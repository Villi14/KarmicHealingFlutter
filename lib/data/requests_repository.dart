import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import 'app_database.dart';
import 'models.dart';

/// What a search over requests turned up, split by level.
@immutable
class RequestsSearchResults {
  const RequestsSearchResults({
    required this.requests,
    required this.subrequests,
    required this.completedCount,
  });

  final List<RequestsList> requests;
  final List<Subrequest> subrequests;

  /// Fulfilled matches on both levels together.
  ///
  /// Search hides what is fulfilled on both levels, so the tally that offers to
  /// show it counts both — otherwise a fulfilled request matches, is hidden,
  /// and nothing on screen says so.
  final int completedCount;

  bool get hasResults => requests.isNotEmpty || subrequests.isNotEmpty;
}

/// Requests and the subrequests under them, held in memory and written through
/// to SQLite.
///
/// The store is the truth on disk; this keeps the whole of it in memory because
/// a practice holds tens of rows, not thousands. Reading in Dart also settles
/// what SQLite cannot: `LIKE` folds ASCII only, so a Ukrainian title typed in a
/// different case than it was saved would never match. [String.toLowerCase]
/// knows the whole alphabet.
class RequestsRepository extends ChangeNotifier {
  RequestsRepository(this._database);

  final AppDatabase _database;
  static const _uuid = Uuid();

  List<RequestsList> _requests = const [];
  List<Subrequest> _subrequests = const [];

  /// Requests in the order they were arranged, fulfilled ones sorted after
  /// their peers at the same position.
  List<RequestsList> get requests => List.unmodifiable(_requests);

  bool get isEmpty => _requests.isEmpty;

  Future<void> load() async {
    final requestRows = await _database.db.query('requestsLists');
    final subrequestRows = await _database.db.query('requests');
    _requests = requestRows.map(RequestsList.fromRow).toList()..sort(_byOrder);
    _subrequests = subrequestRows.map(Subrequest.fromRow).toList()
      ..sort((a, b) => a.position.compareTo(b.position));
    notifyListeners();
  }

  static int _byOrder(RequestsList a, RequestsList b) {
    final byPosition = a.position.compareTo(b.position);
    if (byPosition != 0) return byPosition;
    final byCompletion = (a.isCompleted ? 1 : 0).compareTo(
      b.isCompleted ? 1 : 0,
    );
    if (byCompletion != 0) return byCompletion;
    return a.title.compareTo(b.title);
  }

  RequestsList? requestById(String id) {
    for (final request in _requests) {
      if (request.id == id) return request;
    }
    return null;
  }

  /// The subrequests of one request, in the order they were written.
  List<Subrequest> subrequestsOf(String requestId) => _subrequests
      .where((subrequest) => subrequest.requestsListId == requestId)
      .toList();

  SubrequestProgress progressOf(String requestId) {
    final subrequests = subrequestsOf(requestId);
    return SubrequestProgress(
      total: subrequests.length,
      completed: subrequests.where((s) => s.isCompleted).length,
    );
  }

  /// Whether the user may flip this request's radio button right now.
  ///
  /// Fulfilling a request asks for every subrequest to be fulfilled first; a
  /// request that is already fulfilled can always be reopened.
  bool canToggleCompletion(RequestsList request) =>
      request.isCompleted || progressOf(request.id).allCompleted;

  // MARK: - Requests

  /// A blank request, wearing the colour its screen already wears, ready for a
  /// form to fill in.
  RequestsList draftRequest(Color color) =>
      RequestsList(id: _uuid.v4(), color: color);

  /// Writes a request, new or edited, and passes its date down to whatever
  /// hangs beneath it.
  Future<void> saveRequest(RequestsList request) async {
    final isNew = requestById(request.id) == null;
    final row = request.toRow();
    if (isNew) row['position'] = await _database.nextPosition('requestsLists');
    await _database.upsert('requestsLists', row);
    // A brand new request has nothing under it yet; an edited one passes its
    // date on.
    await _inheritDueDate(request.id);
    await load();
  }

  Future<void> deleteRequest(String id) async {
    // The subrequests go with it — the schema cascades.
    await _database.db.delete(
      'requestsLists',
      where: '"id" = ?',
      whereArgs: [id],
    );
    await load();
  }

  /// Flips the request's completion when the rules allow it.
  ///
  /// Nothing here happens on its own: a request is only ever fulfilled by this
  /// call, never by its subrequests reaching the finish line.
  Future<void> toggleRequestCompletion(String id) async {
    final request = requestById(id);
    if (request == null || !canToggleCompletion(request)) return;

    await _database.db.update(
      'requestsLists',
      {'isCompleted': request.isCompleted ? 0 : 1},
      where: '"id" = ?',
      whereArgs: [id],
    );
    await load();
  }

  Future<void> moveRequest(int oldIndex, int newIndex) async {
    final ids = _requests.map((request) => request.id).toList();
    if (oldIndex < 0 || oldIndex >= ids.length) return;
    final id = ids.removeAt(oldIndex);
    ids.insert(newIndex.clamp(0, ids.length), id);
    await _writePositions('requestsLists', ids);
    await load();
  }

  // MARK: - Subrequests

  Subrequest draftSubrequest(String requestId) =>
      Subrequest(id: _uuid.v4(), requestsListId: requestId);

  /// Writes a subrequest, then settles what that does to the request above it.
  Future<void> saveSubrequest(Subrequest subrequest) async {
    final isNew = !_subrequests.any((s) => s.id == subrequest.id);
    final row = subrequest.toRow();
    if (isNew) row['position'] = await _database.nextPosition('requests');
    await _database.upsert('requests', row);
    // The subrequest takes its request's date, and a subrequest added to an
    // already fulfilled request reopens it.
    await _inheritDueDate(subrequest.requestsListId);
    await _syncCompletion(subrequest.requestsListId);
    await load();
  }

  /// Flips a subrequest.
  ///
  /// Reopening one reopens the request above it; fulfilling the last one only
  /// unlocks that request's radio button, it never taps it for the user.
  Future<void> toggleSubrequest(String id) async {
    final subrequest = _subrequestById(id);
    if (subrequest == null) return;

    await _database.db.update(
      'requests',
      {'isCompleted': subrequest.isCompleted ? 0 : 1},
      where: '"id" = ?',
      whereArgs: [id],
    );
    await _syncCompletion(subrequest.requestsListId);
    await load();
  }

  Future<void> deleteSubrequest(String id) async {
    final subrequest = _subrequestById(id);
    if (subrequest == null) return;

    await _database.db.delete('requests', where: '"id" = ?', whereArgs: [id]);
    await _syncCompletion(subrequest.requestsListId);
    await load();
  }

  Future<void> moveSubrequest(
    String requestId,
    int oldIndex,
    int newIndex,
  ) async {
    final ids = subrequestsOf(requestId).map((s) => s.id).toList();
    if (oldIndex < 0 || oldIndex >= ids.length) return;
    final id = ids.removeAt(oldIndex);
    ids.insert(newIndex.clamp(0, ids.length), id);
    await _writePositions('requests', ids);
    await load();
  }

  // MARK: - Search

  /// Matches a request's own words, and the words of every subrequest, in any
  /// case they were typed.
  RequestsSearchResults search(String text, {bool showCompleted = false}) {
    final query = text.trim().toLowerCase();
    if (query.isEmpty) {
      return const RequestsSearchResults(
        requests: [],
        subrequests: [],
        completedCount: 0,
      );
    }

    bool matchesRequest(RequestsList request) =>
        request.title.toLowerCase().contains(query) ||
        request.description.toLowerCase().contains(query) ||
        request.notes.toLowerCase().contains(query);

    bool matchesSubrequest(Subrequest subrequest) =>
        subrequest.title.toLowerCase().contains(query) ||
        subrequest.notes.toLowerCase().contains(query);

    final requests = _requests.where(matchesRequest).toList()
      ..sort(_bySearchOrder);
    final subrequests = _subrequests.where(matchesSubrequest).toList()
      ..sort(
        (a, b) => (a.isCompleted ? 1 : 0).compareTo(b.isCompleted ? 1 : 0) != 0
            ? (a.isCompleted ? 1 : 0).compareTo(b.isCompleted ? 1 : 0)
            : a.position.compareTo(b.position),
      );

    final completedCount =
        requests.where((r) => r.isCompleted).length +
        subrequests.where((s) => s.isCompleted).length;

    return RequestsSearchResults(
      requests: showCompleted
          ? requests
          : requests.where((r) => !r.isCompleted).toList(),
      subrequests: showCompleted
          ? subrequests
          : subrequests.where((s) => !s.isCompleted).toList(),
      completedCount: completedCount,
    );
  }

  static int _bySearchOrder(RequestsList a, RequestsList b) {
    final byCompletion = (a.isCompleted ? 1 : 0).compareTo(
      b.isCompleted ? 1 : 0,
    );
    if (byCompletion != 0) return byCompletion;
    return a.position.compareTo(b.position);
  }

  /// Clears every fulfilled match on both levels.
  ///
  /// Nothing here carries a date of its own to sift by, so it is all or
  /// nothing. A fulfilled request takes its subrequests with it — the schema
  /// cascades.
  Future<void> deleteCompletedMatching(String text) async {
    final matches = search(text, showCompleted: true);
    final batch = _database.db.batch();
    for (final request in matches.requests.where((r) => r.isCompleted)) {
      batch.delete('requestsLists', where: '"id" = ?', whereArgs: [request.id]);
    }
    for (final subrequest in matches.subrequests.where((s) => s.isCompleted)) {
      batch.delete('requests', where: '"id" = ?', whereArgs: [subrequest.id]);
    }
    await batch.commit(noResult: true);
    await load();
  }

  // MARK: - Rules

  Subrequest? _subrequestById(String id) {
    for (final subrequest in _subrequests) {
      if (subrequest.id == id) return subrequest;
    }
    return null;
  }

  /// Copies a request's date onto every one of its subrequests.
  ///
  /// A subrequest is a step towards its request, so it is due when the request
  /// is. The date is stored rather than derived — search and ordering read it
  /// straight off the row — but it is never shown on a subrequest, and never
  /// edited there.
  Future<void> _inheritDueDate(String requestId) async {
    final rows = await _database.db.query(
      'requestsLists',
      columns: ['dueDate'],
      where: '"id" = ?',
      whereArgs: [requestId],
    );
    if (rows.isEmpty) return;

    await _database.db.update(
      'requests',
      {'dueDate': rows.first['dueDate']},
      where: '"requestsListID" = ?',
      whereArgs: [requestId],
    );
  }

  /// Reopens a fulfilled request as soon as one of its subrequests is
  /// unfinished.
  ///
  /// Called after any change beneath a request — a subrequest toggled, added or
  /// deleted — so a request never stays fulfilled while something under it is
  /// still open.
  Future<void> _syncCompletion(String requestId) async {
    final rows = await _database.db.rawQuery(
      '''
      SELECT count(*) AS "total",
             sum("isCompleted") AS "completed"
      FROM "requests" WHERE "requestsListID" = ?
      ''',
      [requestId],
    );
    final total = rows.first['total']! as int;
    final completed = (rows.first['completed'] as int?) ?? 0;
    if (total == completed) return;

    await _database.db.update(
      'requestsLists',
      {'isCompleted': 0},
      where: '"id" = ? AND "isCompleted" = 1',
      whereArgs: [requestId],
    );
  }

  Future<void> _writePositions(String table, List<String> ids) async {
    final batch = _database.db.batch();
    for (var index = 0; index < ids.length; index++) {
      batch.update(
        table,
        {'position': index},
        where: '"id" = ?',
        whereArgs: [ids[index]],
      );
    }
    await batch.commit(noResult: true);
  }
}
