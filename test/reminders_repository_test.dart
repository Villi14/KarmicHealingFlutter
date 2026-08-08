import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karmic_healing_flutter/data/app_database.dart';
import 'package:karmic_healing_flutter/data/models.dart';
import 'package:karmic_healing_flutter/data/reminders_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// What the grid counts, how a detail screen arranges what it shows, and what
/// clearing takes away.
void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late AppDatabase database;
  late RemindersRepository repository;

  setUp(() async {
    database = await AppDatabase.openInMemory();
    repository = RemindersRepository(database);
    await repository.load();
  });

  tearDown(() => database.close());

  Future<RemindersList> addTopic({String title = 'Personal'}) async {
    final topic = repository
        .draftTopic(const Color(0xFF4A99EF))
        .copyWith(title: title);
    await repository.saveTopic(topic);
    return repository.topicById(topic.id)!;
  }

  Future<Reminder> addReminder(
    RemindersList topic, {
    String title = 'Morning meditation',
    String notes = '',
    DateTime? dueDate,
    bool isCompleted = false,
    bool isFlagged = false,
    Priority? priority,
  }) async {
    final reminder = repository
        .draftReminder(topic.id)
        .copyWith(
          title: title,
          notes: notes,
          dueDate: dueDate,
          isCompleted: isCompleted,
          isFlagged: isFlagged,
          priority: priority,
        );
    await repository.saveReminder(reminder);
    return repository.reminderById(reminder.id)!;
  }

  test('a topic carries the number of reminders still open', () async {
    final topic = await addTopic();
    await addReminder(topic, title: 'One');
    final done = await addReminder(topic, title: 'Two');
    await repository.toggleReminderCompletion(done.id);

    expect(repository.openCountOf(topic.id), 1);
  });

  test('the grid counts today, scheduled, all and flagged', () async {
    final topic = await addTopic();
    final now = DateTime.now();
    await addReminder(topic, title: 'Today', dueDate: now);
    await addReminder(
      topic,
      title: 'Later',
      dueDate: now.add(const Duration(days: 3)),
    );
    await addReminder(topic, title: 'Undated');
    await addReminder(topic, title: 'Marked', isFlagged: true);
    final done = await addReminder(
      topic,
      title: 'Done',
      dueDate: now,
      isFlagged: true,
    );
    await repository.toggleReminderCompletion(done.id);

    final stats = repository.stats;
    expect(stats.todayCount, 1, reason: 'the fulfilled one no longer counts');
    expect(stats.scheduledCount, 2);
    expect(stats.allCount, 4);
    expect(stats.flaggedCount, 2, reason: 'flagged counts fulfilled ones too');
  });

  test(
    'an undated reminder waits at the end rather than at the front',
    () async {
      final topic = await addTopic();
      await addReminder(topic, title: 'Undated');
      await addReminder(
        topic,
        title: 'Soon',
        dueDate: DateTime.now().add(const Duration(days: 1)),
      );

      final rows = repository.remindersFor(
        RemindersDetailType.topic,
        topicId: topic.id,
      );

      expect(rows.map((r) => r.title), ['Soon', 'Undated']);
    },
  );

  test(
    'ordering by priority puts the loudest first, flags breaking ties',
    () async {
      final topic = await addTopic();
      await addReminder(topic, title: 'Quiet');
      await addReminder(topic, title: 'Flagged', isFlagged: true);
      await addReminder(topic, title: 'Loud', priority: Priority.high);
      await addReminder(topic, title: 'Middling', priority: Priority.medium);

      final rows = repository.remindersFor(
        RemindersDetailType.topic,
        topicId: topic.id,
        ordering: RemindersOrdering.priority,
      );

      expect(rows.map((r) => r.title), [
        'Loud',
        'Middling',
        'Flagged',
        'Quiet',
      ]);
    },
  );

  test(
    'what is fulfilled sinks below what is not, and hides unless asked',
    () async {
      final topic = await addTopic();
      final done = await addReminder(topic, title: 'Done');
      await addReminder(topic, title: 'Open');
      await repository.toggleReminderCompletion(done.id);

      final hidden = repository.remindersFor(
        RemindersDetailType.topic,
        topicId: topic.id,
      );
      expect(hidden.map((r) => r.title), ['Open']);

      final shown = repository.remindersFor(
        RemindersDetailType.topic,
        topicId: topic.id,
        showCompleted: true,
        ordering: RemindersOrdering.title,
      );
      expect(shown.map((r) => r.title), ['Open', 'Done']);
    },
  );

  test('the fulfilled screen starts out showing what it is named after', () {
    expect(
      RemindersRepository.showsCompletedByDefault(
        RemindersDetailType.completed,
      ),
      isTrue,
    );
    expect(
      RemindersRepository.showsCompletedByDefault(RemindersDetailType.today),
      isFalse,
    );
  });

  test('a reminder can be flagged and unflagged', () async {
    final topic = await addTopic();
    final reminder = await addReminder(topic);

    await repository.toggleFlag(reminder.id);
    expect(repository.reminderById(reminder.id)!.isFlagged, isTrue);

    await repository.toggleFlag(reminder.id);
    expect(repository.reminderById(reminder.id)!.isFlagged, isFalse);
  });

  test('deleting a topic takes its reminders with it', () async {
    final topic = await addTopic();
    await addReminder(topic);

    await repository.deleteTopic(topic.id);

    expect(repository.topics, isEmpty);
    expect(repository.stats.allCount, 0);
  });

  test('editing a topic keeps the reminders in it', () async {
    final topic = await addTopic();
    await addReminder(topic);

    await repository.saveTopic(topic.copyWith(title: 'Renamed'));

    expect(repository.topics.single.title, 'Renamed');
    expect(repository.openCountOf(topic.id), 1);
  });

  test(
    'search matches in any case, across alphabets, counting the fulfilled',
    () async {
      final topic = await addTopic();
      await addReminder(topic, title: 'Ранкова практика');
      final done = await addReminder(topic, title: 'Ранкова прогулянка');
      await repository.toggleReminderCompletion(done.id);

      final hidden = repository.search('РАНКОВА');
      expect(hidden.reminders, hasLength(1));
      expect(hidden.completedCount, 1);
      expect(
        repository.search('ранкова', showCompleted: true).reminders,
        hasLength(2),
      );
    },
  );

  test('clearing by age spares the recent and the undated', () async {
    final topic = await addTopic();
    final old = await addReminder(
      topic,
      title: 'Walk long ago',
      dueDate: DateTime.now().subtract(const Duration(days: 200)),
    );
    final recent = await addReminder(
      topic,
      title: 'Walk yesterday',
      dueDate: DateTime.now().subtract(const Duration(days: 1)),
    );
    final undated = await addReminder(topic, title: 'Walk someday');
    for (final reminder in [old, recent, undated]) {
      await repository.toggleReminderCompletion(reminder.id);
    }

    await repository.deleteCompletedMatching('walk', monthsAgo: 6);

    expect(repository.reminderById(old.id), isNull);
    expect(repository.reminderById(recent.id), isNotNull);
    expect(repository.reminderById(undated.id), isNotNull);

    await repository.deleteCompletedMatching('walk');

    expect(repository.stats.allCount, 0);
    expect(repository.search('walk', showCompleted: true).reminders, isEmpty);
  });

  test('what was written survives reopening the store', () async {
    final topic = await addTopic(title: 'Persisted');
    await addReminder(
      topic,
      title: 'Beneath',
      dueDate: DateTime(2026, 8, 20, 9, 30),
    );

    final reopened = RemindersRepository(database);
    await reopened.load();

    expect(reopened.topics.single.title, 'Persisted');
    final reminder = reopened
        .remindersFor(RemindersDetailType.topic, topicId: topic.id)
        .single;
    expect(reminder.title, 'Beneath');
    expect(reminder.dueDate, DateTime(2026, 8, 20, 9, 30));
  });
}
