import 'package:flutter_test/flutter_test.dart';
import 'package:karmic_healing_flutter/data/app_database.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// The store's shape — the part the Swift app agrees to as well. A column
/// renamed, dropped or retyped here still opens without error and just as
/// quietly stops being the file the other app can read.
void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late AppDatabase database;

  setUp(() async => database = await AppDatabase.openInMemory());

  tearDown(() => database.close());

  Future<Set<String>> columnsOf(String table) async {
    final rows = await database.db.rawQuery('PRAGMA table_info("$table")');
    return rows.map((row) => row['name'] as String).toSet();
  }

  test('every table the app reads and writes exists', () async {
    final tables = await database.db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table'",
    );
    expect(tables.map((row) => row['name']), {
      'requestsLists',
      'requests',
      'remindersLists',
      'reminders',
    });
  });

  test('requestsLists carries the columns the Swift app writes', () async {
    expect(await columnsOf('requestsLists'), {
      'id',
      'color',
      'position',
      'title',
      'description',
      'isCompleted',
      'priority',
      'dueDate',
      'notes',
    });
  });

  test('requests carries the columns the Swift app writes', () async {
    expect(await columnsOf('requests'), {
      'id',
      'dueDate',
      'isCompleted',
      'notes',
      'position',
      'requestsListID',
      'title',
    });
  });

  test('remindersLists carries the columns the Swift app writes', () async {
    expect(await columnsOf('remindersLists'), {
      'id',
      'color',
      'position',
      'title',
    });
  });

  test('reminders carries the columns the Swift app writes', () async {
    expect(await columnsOf('reminders'), {
      'id',
      'dueDate',
      'isCompleted',
      'isFlagged',
      'notes',
      'position',
      'priority',
      'remindersListID',
      'title',
    });
  });

  test('foreign keys are enforced, so an orphan row cannot be written', () async {
    expect(
      () => database.db.insert('requests', {
        'id': 'r1',
        'requestsListID': 'missing-list',
        'title': 'Orphan',
      }),
      throwsA(isA<DatabaseException>()),
    );
  });

  test('deleting a list cascades to what hangs off it', () async {
    await database.db.insert('requestsLists', {
      'id': 'list-1',
      'title': 'A list',
    });
    await database.db.insert('requests', {
      'id': 'req-1',
      'requestsListID': 'list-1',
      'title': 'A request',
    });

    await database.db.delete(
      'requestsLists',
      where: '"id" = ?',
      whereArgs: ['list-1'],
    );

    final left = await database.db.query('requests');
    expect(left, isEmpty);
  });

  test('upsert updates an existing row instead of replacing it', () async {
    await database.upsert('requestsLists', {'id': 'list-1', 'title': 'One'});
    await database.db.insert('requests', {
      'id': 'req-1',
      'requestsListID': 'list-1',
      'title': 'A request',
    });

    // A REPLACE would delete "list-1" first, cascading "req-1" away with it.
    await database.upsert('requestsLists', {'id': 'list-1', 'title': 'Two'});

    final requests = await database.db.query('requests');
    expect(requests, hasLength(1));
    final lists = await database.db.query('requestsLists');
    expect(lists.single['title'], 'Two');
  });

  test('nextPosition follows on from what is already in the table', () async {
    expect(await database.nextPosition('requestsLists'), 0);

    await database.db.insert('requestsLists', {
      'id': 'list-1',
      'title': 'One',
      'position': 4,
    });

    expect(await database.nextPosition('requestsLists'), 5);
  });

  test(
    'two in-memory stores opened at once never share a row',
    () async {
      final other = await AppDatabase.openInMemory();
      addTearDown(other.close);

      await database.db.insert('requestsLists', {
        'id': 'list-1',
        'title': 'Only in the first',
      });

      final rows = await other.db.query('requestsLists');
      expect(rows, isEmpty);
    },
  );
}
