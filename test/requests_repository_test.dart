import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karmic_healing_flutter/data/app_database.dart';
import 'package:karmic_healing_flutter/data/models.dart';
import 'package:karmic_healing_flutter/data/requests_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// The rules a request lives by: it waits for its subrequests, it lends them its
/// date, and it reopens the moment one of them does.
void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late AppDatabase database;
  late RequestsRepository repository;

  setUp(() async {
    database = await AppDatabase.openInMemory();
    repository = RequestsRepository(database);
    await repository.load();
  });

  tearDown(() => database.close());

  Future<RequestsList> addRequest({
    String title = 'Personal Request',
    DateTime? dueDate,
  }) async {
    final request = repository
        .draftRequest(const Color(0xFF4A99EF))
        .copyWith(title: title, dueDate: dueDate);
    await repository.saveRequest(request);
    return repository.requestById(request.id)!;
  }

  Future<Subrequest> addSubrequest(
    RequestsList request, {
    String title = 'Groceries',
  }) async {
    final subrequest = repository
        .draftSubrequest(request.id)
        .copyWith(title: title);
    await repository.saveSubrequest(subrequest);
    return repository.subrequestsOf(request.id).last;
  }

  test('a request with nothing under it can be fulfilled at once', () async {
    final request = await addRequest();

    expect(repository.canToggleCompletion(request), isTrue);

    await repository.toggleRequestCompletion(request.id);

    expect(repository.requestById(request.id)!.isCompleted, isTrue);
  });

  test(
    'a request waits for every subrequest before it can be fulfilled',
    () async {
      final request = await addRequest();
      final subrequest = await addSubrequest(request);

      expect(
        repository.canToggleCompletion(repository.requestById(request.id)!),
        isFalse,
      );

      await repository.toggleRequestCompletion(request.id);
      expect(repository.requestById(request.id)!.isCompleted, isFalse);

      await repository.toggleSubrequest(subrequest.id);

      expect(
        repository.canToggleCompletion(repository.requestById(request.id)!),
        isTrue,
      );
      await repository.toggleRequestCompletion(request.id);
      expect(repository.requestById(request.id)!.isCompleted, isTrue);
    },
  );

  test(
    'fulfilling the last subrequest never taps the request itself',
    () async {
      final request = await addRequest();
      final subrequest = await addSubrequest(request);

      await repository.toggleSubrequest(subrequest.id);

      expect(repository.requestById(request.id)!.isCompleted, isFalse);
    },
  );

  test('a subrequest added to a fulfilled request reopens it', () async {
    final request = await addRequest();
    await repository.toggleRequestCompletion(request.id);
    expect(repository.requestById(request.id)!.isCompleted, isTrue);

    await addSubrequest(request);

    expect(repository.requestById(request.id)!.isCompleted, isFalse);
    // And it is locked again until the new subrequest is seen to.
    expect(
      repository.canToggleCompletion(repository.requestById(request.id)!),
      isFalse,
    );
  });

  test('reopening a subrequest reopens the request above it', () async {
    final request = await addRequest();
    final subrequest = await addSubrequest(request);
    await repository.toggleSubrequest(subrequest.id);
    await repository.toggleRequestCompletion(request.id);
    expect(repository.requestById(request.id)!.isCompleted, isTrue);

    await repository.toggleSubrequest(subrequest.id);

    expect(repository.requestById(request.id)!.isCompleted, isFalse);
  });

  test(
    'deleting the last open subrequest leaves the request fulfillable',
    () async {
      final request = await addRequest();
      final open = await addSubrequest(request, title: 'Haircut');

      await repository.deleteSubrequest(open.id);

      expect(
        repository.canToggleCompletion(repository.requestById(request.id)!),
        isTrue,
      );
    },
  );

  test(
    'subrequests take their request\'s date, whenever either is written',
    () async {
      final dueDate = DateTime(2026, 8, 20, 9);
      final request = await addRequest(dueDate: dueDate);
      final subrequest = await addSubrequest(request);

      expect(repository.subrequestsOf(request.id).single.dueDate, dueDate);

      final moved = DateTime(2026, 9, 1, 18);
      await repository.saveRequest(
        repository.requestById(request.id)!.copyWith(dueDate: moved),
      );

      expect(repository.subrequestsOf(request.id).single.dueDate, moved);
      expect(subrequest.id, repository.subrequestsOf(request.id).single.id);
    },
  );

  test('clearing a request\'s date clears it beneath too', () async {
    final request = await addRequest(dueDate: DateTime(2026, 8, 20, 9));
    await addSubrequest(request);

    await repository.saveRequest(
      repository.requestById(request.id)!.copyWith(clearDueDate: true),
    );

    expect(repository.subrequestsOf(request.id).single.dueDate, isNull);
  });

  test('deleting a request takes its subrequests with it', () async {
    final request = await addRequest();
    await addSubrequest(request);

    await repository.deleteRequest(request.id);

    expect(repository.requests, isEmpty);
    expect(repository.subrequestsOf(request.id), isEmpty);
  });

  test('search matches either level, in any case, across alphabets', () async {
    final request = await addRequest(title: 'Здоровʼя родини');
    await repository.saveSubrequest(
      repository.draftSubrequest(request.id).copyWith(title: 'Прогулянка'),
    );

    expect(repository.search('ЗДОРОВ').requests, hasLength(1));
    expect(repository.search('прогулянка').subrequests, hasLength(1));
    expect(repository.search('nothing').hasResults, isFalse);
  });

  test('search hides what is fulfilled but still counts it', () async {
    final request = await addRequest(title: 'Walk');
    final subrequest = await addSubrequest(request, title: 'Walk further');
    await repository.toggleSubrequest(subrequest.id);

    final hidden = repository.search('walk');
    expect(hidden.subrequests, isEmpty);
    expect(hidden.completedCount, 1);

    expect(
      repository.search('walk', showCompleted: true).subrequests,
      hasLength(1),
    );
  });

  test('clearing fulfilled matches leaves the open ones standing', () async {
    final request = await addRequest(title: 'Walk');
    final done = await addSubrequest(request, title: 'Walk further');
    await addSubrequest(request, title: 'Walk daily');
    await repository.toggleSubrequest(done.id);

    await repository.deleteCompletedMatching('walk');

    expect(repository.subrequestsOf(request.id), hasLength(1));
    expect(repository.subrequestsOf(request.id).single.title, 'Walk daily');
  });

  test(
    'a new request lands after the ones already there, and reorders',
    () async {
      final first = await addRequest(title: 'First');
      final second = await addRequest(title: 'Second');
      final third = await addRequest(title: 'Third');

      expect(repository.requests.map((r) => r.id), [
        first.id,
        second.id,
        third.id,
      ]);

      await repository.moveRequest(2, 0);

      expect(repository.requests.map((r) => r.id), [
        third.id,
        first.id,
        second.id,
      ]);
    },
  );

  test('what was written survives reopening the store', () async {
    final request = await addRequest(title: 'Persisted');
    await addSubrequest(request, title: 'Beneath');

    final reopened = RequestsRepository(database);
    await reopened.load();

    expect(reopened.requests.single.title, 'Persisted');
    expect(reopened.subrequestsOf(request.id).single.title, 'Beneath');
  });
}
