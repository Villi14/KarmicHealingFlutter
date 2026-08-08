import 'package:karmic_healing_flutter/data/app_database.dart';
import 'package:karmic_healing_flutter/data/reminders_repository.dart';
import 'package:karmic_healing_flutter/data/requests_repository.dart';
import 'package:karmic_healing_flutter/data/repository_scope.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Repositories over a store that lives only as long as the test.
///
/// Call [useTestDatabaseFactory] once in `setUpAll` — the sqflite plugin has no
/// platform side under `flutter test`, so the FFI one stands in for it.
void useTestDatabaseFactory() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
}

/// The pair a test hands to `KarmicHealingApp`.
typedef TestRepositories = ({
  RequestsRepository requests,
  RemindersRepository reminders,
});

/// Opens a store and loads both repositories over it.
///
/// Call it from `setUp`, never from inside a `testWidgets` body: that body runs
/// in a fake-async zone, and real database I/O started there never completes.
Future<TestRepositories> emptyRepositories() async =>
    loadRepositories(database: await AppDatabase.openInMemory());
