import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karmic_healing_flutter/data/app_database.dart';
import 'package:karmic_healing_flutter/data/models.dart';
import 'package:karmic_healing_flutter/data/reminder_notifications.dart';
import 'package:karmic_healing_flutter/data/reminders_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// A scheduler that keeps what it was last told instead of talking to a device.
class RecordingScheduler extends ReminderScheduler {
  final List<List<Reminder>> syncs = [];

  /// What the last sync would actually have put in the tray.
  List<Reminder> get scheduled => LocalReminderScheduler.pending(
    syncs.last,
    now: DateTime.now(),
  ).map((entry) => entry.reminder).toList();

  @override
  Future<void> sync(List<Reminder> reminders) async => syncs.add(reminders);
}

/// Which reminders reach the tray, and how the store keeps it honest.
void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Europe/Kyiv'));
  });

  final now = DateTime(2026, 8, 8, 12);

  Reminder reminderAt(DateTime? dueDate, {bool isCompleted = false}) => Reminder(
    id: 'id-${dueDate?.millisecondsSinceEpoch ?? 0}-$isCompleted',
    remindersListId: 'topic',
    title: 'Morning meditation',
    dueDate: dueDate,
    isCompleted: isCompleted,
  );

  group('what is worth scheduling', () {
    test('a reminder due later today is', () {
      final reminder = reminderAt(DateTime(2026, 8, 8, 18));

      final pending = LocalReminderScheduler.pending([reminder], now: now);

      expect(pending.single.reminder.id, reminder.id);
      expect(pending.single.at.hour, 18);
      expect(pending.single.at.location, tz.local);
    });

    test('one already past, one fulfilled and one undated are not', () {
      final pending = LocalReminderScheduler.pending([
        reminderAt(DateTime(2026, 8, 8, 6)),
        reminderAt(DateTime(2026, 8, 9, 6), isCompleted: true),
        reminderAt(null),
      ], now: now);

      expect(pending, isEmpty);
    });

    test('the soonest comes first', () {
      final pending = LocalReminderScheduler.pending([
        reminderAt(DateTime(2026, 8, 10, 9)),
        reminderAt(DateTime(2026, 8, 8, 20)),
        reminderAt(DateTime(2026, 8, 9, 9)),
      ], now: now);

      expect(
        pending.map((entry) => entry.at.day),
        [8, 9, 10],
      );
    });

    test('only as many as a device will hold are handed over', () {
      final reminders = List.generate(
        80,
        (index) => reminderAt(DateTime(2026, 8, 9).add(Duration(hours: index))),
      );

      final pending = LocalReminderScheduler.pending(reminders, now: now);

      expect(pending, hasLength(60));
      // The earliest are the ones kept, so nothing near at hand is dropped.
      expect(pending.first.at.day, 9);
    });

    test('the same reminder always gets the same notification number', () {
      final id = LocalReminderScheduler.notificationIdOf('a-b-c');

      expect(id, LocalReminderScheduler.notificationIdOf('a-b-c'));
      expect(id, isNot(LocalReminderScheduler.notificationIdOf('a-b-d')));
      expect(id, greaterThanOrEqualTo(0));
    });
  });

  group('the store keeping the tray current', () {
    late AppDatabase database;
    late RecordingScheduler scheduler;
    late RemindersRepository repository;

    setUp(() async {
      database = await AppDatabase.openInMemory();
      scheduler = RecordingScheduler();
      repository = RemindersRepository(database, scheduler: scheduler);
      await repository.load();
    });

    tearDown(() => database.close());

    Future<Reminder> addReminder({DateTime? dueDate}) async {
      final topic = repository
          .draftTopic(const Color(0xFF4A99EF))
          .copyWith(title: 'Personal');
      await repository.saveTopic(topic);

      final reminder = repository
          .draftReminder(topic.id)
          .copyWith(title: 'Morning meditation', dueDate: dueDate);
      await repository.saveReminder(reminder);
      return reminder;
    }

    test('a saved reminder is handed over', () async {
      final reminder = await addReminder(dueDate: DateTime(2027));

      expect(scheduler.scheduled.single.id, reminder.id);
    });

    test('an undated one is not', () async {
      await addReminder();

      expect(scheduler.scheduled, isEmpty);
    });

    test('fulfilling one takes it out of the tray', () async {
      final reminder = await addReminder(dueDate: DateTime(2027));

      await repository.toggleReminderCompletion(reminder.id);

      expect(scheduler.scheduled, isEmpty);
    });

    test('deleting one takes it out of the tray', () async {
      final reminder = await addReminder(dueDate: DateTime(2027));

      await repository.deleteReminder(reminder.id);

      expect(scheduler.scheduled, isEmpty);
    });

    test('deleting a topic takes the reminders in it too', () async {
      final reminder = await addReminder(dueDate: DateTime(2027));
      final topicId = repository.reminderById(reminder.id)!.remindersListId;

      await repository.deleteTopic(topicId);

      expect(scheduler.scheduled, isEmpty);
    });
  });
}
