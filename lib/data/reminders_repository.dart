import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import 'app_database.dart';
import 'models.dart';
import 'reminder_notifications.dart';

/// The tallies the grid of cells on the reminders screen shows.
@immutable
class ReminderStats {
  const ReminderStats({
    this.allCount = 0,
    this.flaggedCount = 0,
    this.scheduledCount = 0,
    this.todayCount = 0,
  });

  final int allCount;
  final int flaggedCount;
  final int scheduledCount;
  final int todayCount;
}

/// Which reminders a detail screen is looking at.
enum RemindersDetailType { all, completed, flagged, topic, scheduled, today }

/// How a detail screen arranges what it shows.
enum RemindersOrdering { dueDate, priority, title }

/// Topics and the reminders in them, held in memory and written through to
/// SQLite. See [RequestsRepository] for why the read model lives in Dart.
class RemindersRepository extends ChangeNotifier {
  RemindersRepository(
    this._database, {
    ReminderScheduler scheduler = const NoReminderScheduler(),
  }) : _scheduler = scheduler; // ignore: prefer_initializing_formals

  final AppDatabase _database;
  final ReminderScheduler _scheduler;
  static const _uuid = Uuid();

  List<RemindersList> _topics = const [];
  List<Reminder> _reminders = const [];

  /// Topics in the order they were arranged.
  List<RemindersList> get topics => List.unmodifiable(_topics);

  bool get isEmpty => _topics.isEmpty;

  /// Reads the store back into memory, and lets the notifications follow.
  ///
  /// Every write ends here, so scheduling hangs off this one call rather than
  /// off each of them: whatever a reminder has just become — fulfilled, moved,
  /// deleted along with its topic — the tray is told the same way.
  Future<void> load() async {
    final topicRows = await _database.db.query('remindersLists');
    final reminderRows = await _database.db.query('reminders');
    _topics = topicRows.map(RemindersList.fromRow).toList()
      ..sort((a, b) => a.position.compareTo(b.position));
    _reminders = reminderRows.map(Reminder.fromRow).toList()
      ..sort((a, b) => a.position.compareTo(b.position));
    notifyListeners();
    await _scheduler.sync(_reminders);
  }

  RemindersList? topicById(String id) {
    for (final topic in _topics) {
      if (topic.id == id) return topic;
    }
    return null;
  }

  Reminder? reminderById(String id) {
    for (final reminder in _reminders) {
      if (reminder.id == id) return reminder;
    }
    return null;
  }

  /// How many reminders in a topic are still open — the figure its row carries.
  int openCountOf(String topicId) => _reminders
      .where((r) => r.remindersListId == topicId && !r.isCompleted)
      .length;

  /// The tallies of the grid.
  ///
  /// `flagged` counts every flagged reminder, fulfilled or not; the rest count
  /// only what is still open — the same reading the Swift app takes.
  ReminderStats get stats => ReminderStats(
    allCount: _reminders.where((r) => !r.isCompleted).length,
    flaggedCount: _reminders.where((r) => r.isFlagged).length,
    scheduledCount: _reminders.where(_isScheduled).length,
    todayCount: _reminders.where(_isToday).length,
  );

  static bool _isScheduled(Reminder reminder) =>
      !reminder.isCompleted && reminder.dueDate != null;

  /// Whether a reminder falls on today, read in the user's own day rather than
  /// in UTC — a reminder set for tonight belongs to tonight.
  static bool _isToday(Reminder reminder) {
    final dueDate = reminder.dueDate;
    if (reminder.isCompleted || dueDate == null) return false;
    final now = DateTime.now();
    return dueDate.year == now.year &&
        dueDate.month == now.month &&
        dueDate.day == now.day;
  }

  static bool isPastDue(Reminder reminder) {
    final dueDate = reminder.dueDate;
    if (reminder.isCompleted || dueDate == null) return false;
    final now = DateTime.now();
    final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
    return due.isBefore(DateTime(now.year, now.month, now.day));
  }

  /// The reminders a detail screen shows, filtered and arranged.
  List<Reminder> remindersFor(
    RemindersDetailType type, {
    String? topicId,
    bool showCompleted = false,
    RemindersOrdering ordering = RemindersOrdering.dueDate,
  }) {
    bool belongs(Reminder reminder) {
      switch (type) {
        case RemindersDetailType.all:
          return !reminder.isCompleted;
        case RemindersDetailType.completed:
          return reminder.isCompleted;
        case RemindersDetailType.flagged:
          return reminder.isFlagged;
        case RemindersDetailType.topic:
          return reminder.remindersListId == topicId;
        case RemindersDetailType.scheduled:
          return _isScheduled(reminder);
        case RemindersDetailType.today:
          return _isToday(reminder);
      }
    }

    final rows = _reminders
        .where((r) => showCompleted || !r.isCompleted)
        .where(belongs)
        .toList();

    rows.sort((a, b) {
      // Whatever else is asked for, what is done sinks below what is not.
      final byCompletion = (a.isCompleted ? 1 : 0).compareTo(
        b.isCompleted ? 1 : 0,
      );
      if (byCompletion != 0) return byCompletion;

      switch (ordering) {
        case RemindersOrdering.dueDate:
          // A reminder with no date waits at the end rather than at the front.
          if (a.dueDate == null && b.dueDate == null) return 0;
          if (a.dueDate == null) return 1;
          if (b.dueDate == null) return -1;
          return a.dueDate!.compareTo(b.dueDate!);
        case RemindersOrdering.priority:
          final byPriority = (b.priority?.rawValue ?? 0).compareTo(
            a.priority?.rawValue ?? 0,
          );
          if (byPriority != 0) return byPriority;
          return (b.isFlagged ? 1 : 0).compareTo(a.isFlagged ? 1 : 0);
        case RemindersOrdering.title:
          return a.title.compareTo(b.title);
      }
    });

    return rows;
  }

  /// Whether a detail screen of this kind starts out showing what is fulfilled.
  static bool showsCompletedByDefault(RemindersDetailType type) =>
      type == RemindersDetailType.completed;

  // MARK: - Topics

  RemindersList draftTopic(Color color) =>
      RemindersList(id: _uuid.v4(), color: color);

  Future<void> saveTopic(RemindersList topic) async {
    final isNew = topicById(topic.id) == null;
    final row = topic.toRow();
    if (isNew) row['position'] = await _database.nextPosition('remindersLists');
    await _database.upsert('remindersLists', row);
    await load();
  }

  Future<void> deleteTopic(String id) async {
    // The reminders in it go with it — the schema cascades.
    await _database.db.delete(
      'remindersLists',
      where: '"id" = ?',
      whereArgs: [id],
    );
    await load();
  }

  Future<void> moveTopic(int oldIndex, int newIndex) async {
    final ids = _topics.map((topic) => topic.id).toList();
    if (oldIndex < 0 || oldIndex >= ids.length) return;
    final id = ids.removeAt(oldIndex);
    ids.insert(newIndex.clamp(0, ids.length), id);
    await _writePositions('remindersLists', ids);
    await load();
  }

  // MARK: - Reminders

  Reminder draftReminder(String topicId) =>
      Reminder(id: _uuid.v4(), remindersListId: topicId);

  Future<void> saveReminder(Reminder reminder) async {
    final isNew = reminderById(reminder.id) == null;
    final row = reminder.toRow();
    if (isNew) row['position'] = await _database.nextPosition('reminders');
    await _database.upsert('reminders', row);
    await load();
  }

  Future<void> deleteReminder(String id) async {
    await _database.db.delete('reminders', where: '"id" = ?', whereArgs: [id]);
    await load();
  }

  Future<void> toggleReminderCompletion(String id) async {
    final reminder = reminderById(id);
    if (reminder == null) return;

    await _database.db.update(
      'reminders',
      {'isCompleted': reminder.isCompleted ? 0 : 1},
      where: '"id" = ?',
      whereArgs: [id],
    );
    await load();
  }

  Future<void> toggleFlag(String id) async {
    final reminder = reminderById(id);
    if (reminder == null) return;

    await _database.db.update(
      'reminders',
      {'isFlagged': reminder.isFlagged ? 0 : 1},
      where: '"id" = ?',
      whereArgs: [id],
    );
    await load();
  }

  Future<void> moveReminder(String topicId, int oldIndex, int newIndex) async {
    final ids = _reminders
        .where((r) => r.remindersListId == topicId)
        .map((r) => r.id)
        .toList();
    if (oldIndex < 0 || oldIndex >= ids.length) return;
    final id = ids.removeAt(oldIndex);
    ids.insert(newIndex.clamp(0, ids.length), id);
    await _writePositions('reminders', ids);
    await load();
  }

  // MARK: - Search

  /// Matches a reminder's words in any case they were typed.
  ///
  /// Fulfilled matches are counted whether or not they are shown, so the tally
  /// beside the results can offer to bring them back.
  ({List<Reminder> reminders, int completedCount}) search(
    String text, {
    bool showCompleted = false,
  }) {
    final query = text.trim().toLowerCase();
    if (query.isEmpty) return (reminders: const [], completedCount: 0);

    final matches =
        _reminders
            .where(
              (r) =>
                  r.title.toLowerCase().contains(query) ||
                  r.notes.toLowerCase().contains(query),
            )
            .toList()
          ..sort((a, b) {
            final byCompletion = (a.isCompleted ? 1 : 0).compareTo(
              b.isCompleted ? 1 : 0,
            );
            if (byCompletion != 0) return byCompletion;
            if (a.dueDate == null && b.dueDate == null) return 0;
            if (a.dueDate == null) return 1;
            if (b.dueDate == null) return -1;
            return a.dueDate!.compareTo(b.dueDate!);
          });

    return (
      reminders: showCompleted
          ? matches
          : matches.where((r) => !r.isCompleted).toList(),
      completedCount: matches.where((r) => r.isCompleted).length,
    );
  }

  /// Clears fulfilled matches, optionally only those older than [monthsAgo]
  /// months. A reminder with no date is only ever cleared by the unqualified
  /// call, the way an undated thing cannot be old.
  Future<void> deleteCompletedMatching(String text, {int? monthsAgo}) async {
    final matches = search(text, showCompleted: true).reminders
        .where((r) => r.isCompleted)
        .where((r) {
          if (monthsAgo == null) return true;
          final dueDate = r.dueDate;
          if (dueDate == null) return false;
          final now = DateTime.now();
          return dueDate.isBefore(
            DateTime(now.year, now.month - monthsAgo, now.day),
          );
        });

    final batch = _database.db.batch();
    for (final reminder in matches) {
      batch.delete('reminders', where: '"id" = ?', whereArgs: [reminder.id]);
    }
    await batch.commit(noResult: true);
    await load();
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
