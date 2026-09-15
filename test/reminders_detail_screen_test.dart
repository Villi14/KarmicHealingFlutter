import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karmic_healing_flutter/data/models.dart';
import 'package:karmic_healing_flutter/data/reminders_repository.dart';
import 'package:karmic_healing_flutter/data/repository_scope.dart';
import 'package:karmic_healing_flutter/screens/reminders/reminders_detail_screen.dart';
import 'package:karmic_healing_flutter/widgets/sf_symbols.dart';

import 'support/test_app.dart';
import 'support/test_repositories.dart';

/// The five cuts across every topic, and the topic-only screen underneath
/// them: what shows, what is named, and the menu that reorders and reveals
/// what is done.
void main() {
  setUpAll(useTestDatabaseFactory);

  late TestRepositories repositories;
  setUp(() async => repositories = await emptyRepositories());

  Future<void> write(WidgetTester tester, Future<void> Function() body) =>
      tester.runAsync(body);

  Future<RemindersList> addTopic(
    WidgetTester tester, {
    String title = 'Home',
  }) {
    late RemindersList topic;
    return write(tester, () async {
      final draft = repositories.reminders
          .draftTopic(const Color(0xFF4A99EF))
          .copyWith(title: title);
      await repositories.reminders.saveTopic(draft);
      topic = repositories.reminders.topicById(draft.id)!;
    }).then((_) => topic);
  }

  Future<void> addReminder(
    WidgetTester tester,
    RemindersList topic, {
    String title = 'Water the plants',
    bool isFlagged = false,
    bool isCompleted = false,
  }) => write(tester, () async {
    final draft = repositories.reminders
        .draftReminder(topic.id)
        .copyWith(
          title: title,
          isFlagged: isFlagged,
          isCompleted: isCompleted,
        );
    await repositories.reminders.saveReminder(draft);
  });

  Future<void> pumpDetail(
    WidgetTester tester, {
    String? topicId,
    RemindersDetailType type = RemindersDetailType.topic,
  }) async {
    await tester.pumpWidget(
      RepositoryScope(
        requests: repositories.requests,
        reminders: repositories.reminders,
        child: testApp(
          home: RemindersDetailScreen(topicId: topicId, type: type),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets("a topic's own screen names itself and hides the topic badge", (
    tester,
  ) async {
    final topic = await addTopic(tester, title: 'Home');
    await addReminder(tester, topic);
    await pumpDetail(tester, topicId: topic.id);

    // The eyebrow is upper-cased by AuraLabel, same as any other tone label.
    expect(find.text('TOPIC'), findsOneWidget);
    // Once for the header, not again as a badge on the row beneath it.
    expect(find.text('Home'), findsOneWidget);
  });

  testWidgets('the All cut mixes topics and names each row\'s own', (
    tester,
  ) async {
    final home = await addTopic(tester, title: 'Home');
    final work = await addTopic(tester, title: 'Work');
    await addReminder(tester, home, title: 'Water the plants');
    await addReminder(tester, work, title: 'Send the invoice');
    await pumpDetail(tester, type: RemindersDetailType.all);

    expect(find.text('Water the plants'), findsOneWidget);
    expect(find.text('Send the invoice'), findsOneWidget);
    // The badge naming each row's topic is upper-cased by AuraLabel.
    expect(find.text('HOME'), findsOneWidget);
    expect(find.text('WORK'), findsOneWidget);
  });

  testWidgets('the Flagged cut shows only what is flagged', (tester) async {
    final topic = await addTopic(tester);
    await addReminder(tester, topic, title: 'Flagged one', isFlagged: true);
    await addReminder(tester, topic, title: 'Plain one');
    await pumpDetail(tester, type: RemindersDetailType.flagged);

    expect(find.text('Flagged one'), findsOneWidget);
    expect(find.text('Plain one'), findsNothing);
  });

  testWidgets(
    "a topic's screen starts hiding what is done, and the menu can reveal it",
    (tester) async {
      final topic = await addTopic(tester);
      await addReminder(tester, topic, title: 'Still open');
      await addReminder(tester, topic, title: 'Already done', isCompleted: true);
      await pumpDetail(tester, topicId: topic.id);

      expect(find.text('Already done'), findsNothing);

      await tester.tap(find.byIcon(SFSymbols.ellipsis));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Show Completed'));
      await tester.pumpAndSettle();

      expect(find.text('Already done'), findsOneWidget);
    },
  );

  testWidgets('the topic screen closes itself once its topic is gone', (
    tester,
  ) async {
    final topic = await addTopic(tester, title: 'Home');
    await pumpDetail(tester, topicId: topic.id);
    expect(find.byType(RemindersDetailScreen), findsOneWidget);

    await write(tester, () => repositories.reminders.deleteTopic(topic.id));
    await tester.pumpAndSettle();

    expect(find.text('TOPIC'), findsNothing);
  });
}
