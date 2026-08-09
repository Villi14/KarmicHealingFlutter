import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// The app's store, laid out exactly as the Swift app lays it out.
///
/// Column names, types and the cascade rules come from
/// `Features/Db/Sources/AppDatabase.swift`, so a database written by one app is
/// readable by the other. What Swift does with temporary triggers — handing a
/// new row the next free `position` — is done here in
/// [AppDatabase.nextPosition], because a trigger created per connection is a
/// thing to remember to recreate, and a query is not.
///
/// The one thing not carried over is `STRICT` on the tables. Android hands the
/// app whichever SQLite its system image shipped with, and the keyword only
/// arrived in 3.37 — on anything older `CREATE TABLE` fails outright and the
/// app cannot open its store at all. Nothing about the file changes without it:
/// the columns, their declared types and the values written into them are the
/// same, so the Swift app still reads what this one writes.
class AppDatabase {
  const AppDatabase._(this.db);

  final Database db;

  static const _fileName = 'db.sqlite';

  /// Opens the store on disk, creating it the first time.
  static Future<AppDatabase> open() async {
    final path = p.join(await getDatabasesPath(), _fileName);
    return AppDatabase._(await _openAt(path));
  }

  /// A store that lives only as long as the process — for tests and previews.
  ///
  /// Every call opens its own: sqflite hands out one instance per path by
  /// default, and every in-memory store answers to the same path, so two tests
  /// asking for a fresh one would otherwise be handed the same rows.
  static Future<AppDatabase> openInMemory() async =>
      AppDatabase._(await _openAt(inMemoryDatabasePath, singleInstance: false));

  static Future<Database> _openAt(
    String path, {
    bool singleInstance = true,
  }) => openDatabase(
    path,
    version: 1,
    singleInstance: singleInstance,
    onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
    onCreate: (db, version) async {
      await db.execute('''
        CREATE TABLE "requestsLists" (
          "id" TEXT PRIMARY KEY NOT NULL ON CONFLICT REPLACE,
          "color" INTEGER NOT NULL DEFAULT 1251712256,
          "position" INTEGER NOT NULL DEFAULT 0,
          "title" TEXT NOT NULL,
          "description" TEXT NOT NULL DEFAULT '',
          "isCompleted" INTEGER NOT NULL DEFAULT 0,
          "priority" INTEGER,
          "dueDate" TEXT,
          "notes" TEXT NOT NULL DEFAULT ''
        )
      ''');

      // No `priority` here: a subrequest borrows its request's urgency the same
      // way it borrows its date. The Swift schema dropped the column in its
      // second migration; a store created fresh never grows it.
      await db.execute('''
        CREATE TABLE "requests" (
          "id" TEXT PRIMARY KEY NOT NULL ON CONFLICT REPLACE,
          "dueDate" TEXT,
          "isCompleted" INTEGER NOT NULL DEFAULT 0,
          "notes" TEXT,
          "position" INTEGER NOT NULL DEFAULT 0,
          "requestsListID" TEXT NOT NULL,
          "title" TEXT NOT NULL,

          FOREIGN KEY("requestsListID") REFERENCES "requestsLists"("id") ON DELETE CASCADE
        )
      ''');

      await db.execute('''
        CREATE TABLE "remindersLists" (
          "id" TEXT PRIMARY KEY NOT NULL ON CONFLICT REPLACE,
          "color" INTEGER NOT NULL DEFAULT 1251712256,
          "position" INTEGER NOT NULL DEFAULT 0,
          "title" TEXT NOT NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE "reminders" (
          "id" TEXT PRIMARY KEY NOT NULL ON CONFLICT REPLACE,
          "dueDate" TEXT,
          "isCompleted" INTEGER NOT NULL DEFAULT 0,
          "isFlagged" INTEGER NOT NULL DEFAULT 0,
          "notes" TEXT,
          "position" INTEGER NOT NULL DEFAULT 0,
          "priority" INTEGER,
          "remindersListID" TEXT NOT NULL,
          "title" TEXT NOT NULL,

          FOREIGN KEY("remindersListID") REFERENCES "remindersLists"("id") ON DELETE CASCADE
        )
      ''');
    },
  );

  /// Writes [row] to [table], updating the row that already carries its id or
  /// adding it if none does.
  ///
  /// Never `INSERT OR REPLACE`: replacing deletes the old row first, and a
  /// delete drags everything hanging off it through `ON DELETE CASCADE` — so
  /// editing a request's title would quietly take its subrequests with it.
  Future<void> upsert(String table, Map<String, Object?> row) async {
    final updated = await db.update(
      table,
      row,
      where: '"id" = ?',
      whereArgs: [row['id']],
    );
    if (updated == 0) await db.insert(table, row);
  }

  /// The position a row added to [table] right now should take: after
  /// everything already there.
  Future<int> nextPosition(String table) async {
    final rows = await db.rawQuery(
      'SELECT max("position") AS "max" FROM "$table"',
    );
    final max = rows.first['max'];
    return max is int ? max + 1 : 0;
  }

  Future<void> close() => db.close();
}
