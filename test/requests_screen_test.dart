import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karmic_healing_flutter/data/repository_scope.dart';
import 'package:karmic_healing_flutter/screens/requests/request_detail_screen.dart';
import 'package:karmic_healing_flutter/screens/requests/requests_screen.dart';
import 'package:karmic_healing_flutter/widgets/aura_widgets.dart';
import 'package:karmic_healing_flutter/widgets/karmic_empty_state.dart';
import 'package:karmic_healing_flutter/widgets/karmic_search_bar.dart';
import 'package:karmic_healing_flutter/widgets/list_row.dart';

import 'support/test_app.dart';
import 'support/test_repositories.dart';

/// The requests screen against a real store: what it draws comes from the
/// database, and what it does lands back in it.
void main() {
  setUpAll(useTestDatabaseFactory);

  late TestRepositories repositories;
  setUp(() async => repositories = await emptyRepositories());

  /// Writes to the store from a test body.
  ///
  /// A `testWidgets` body runs in a fake-async zone where real I/O never
  /// completes, so anything touching the database has to step outside it.
  Future<void> write(WidgetTester tester, Future<void> Function() body) async {
    await tester.runAsync(body);
  }

  Future<void> pumpRequests(WidgetTester tester) async {
    await tester.pumpWidget(
      RepositoryScope(
        requests: repositories.requests,
        reminders: repositories.reminders,
        child: testApp(home: const RequestsScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('an empty store shows the empty state, not a list', (
    tester,
  ) async {
    await pumpRequests(tester);

    expect(find.text('Start with a request'), findsOneWidget);
    expect(find.byType(ListRow), findsNothing);
  });

  testWidgets('the empty state stands in the margin the search bar keeps', (
    tester,
  ) async {
    await pumpRequests(tester);

    final search = tester.getRect(
      find.descendant(
        of: find.byType(KarmicSearchBar),
        matching: find.byType(AuraCard),
      ),
    );
    final empty = tester.getRect(find.byType(KarmicEmptyState));
    expect(empty.left, moreOrLessEquals(search.left));
    expect(empty.right, moreOrLessEquals(search.right));
  });

  testWidgets('a request written to the store shows up as a row', (
    tester,
  ) async {
    final repository = repositories.requests;
    await write(tester, () async {
      await repository.saveRequest(
        repository
            .draftRequest(const Color(0xFF4A99EF))
            .copyWith(title: 'Здоровʼя родини'),
      );
    });

    await pumpRequests(tester);

    expect(find.text('Здоровʼя родини'), findsOneWidget);
    expect(find.text('Start with a request'), findsNothing);
  });

  testWidgets('tapping a request opens what hangs under it', (tester) async {
    final repository = repositories.requests;
    final request = repository
        .draftRequest(const Color(0xFF4A99EF))
        .copyWith(title: 'Personal Request');
    await write(tester, () async {
      await repository.saveRequest(request);
      await repository.saveSubrequest(
        repository.draftSubrequest(request.id).copyWith(title: 'Take a walk'),
      );
    });

    await pumpRequests(tester);
    await tester.tap(find.text('Personal Request'));
    await tester.pumpAndSettle();

    expect(find.byType(RequestDetailScreen), findsOneWidget);
    expect(find.text('Take a walk'), findsOneWidget);
    // The request waits for it, and the header says so.
    expect(
      find.textContaining('Fulfil every subrequest first'),
      findsOneWidget,
    );
  });

  testWidgets('the radio button of a waiting request does not move', (
    tester,
  ) async {
    final repository = repositories.requests;
    final request = repository
        .draftRequest(const Color(0xFF4A99EF))
        .copyWith(title: 'Personal Request');
    await write(tester, () async {
      await repository.saveRequest(request);
      await repository.saveSubrequest(
        repository.draftSubrequest(request.id).copyWith(title: 'Take a walk'),
      );
    });

    await pumpRequests(tester);
    await tester.tap(find.byType(ListRow));
    await tester.pumpAndSettle();

    expect(repository.requestById(request.id)!.isCompleted, isFalse);
  });

  testWidgets('searching narrows to what matches, whatever the case', (
    tester,
  ) async {
    final repository = repositories.requests;
    await write(tester, () async {
      for (final title in ['Здоровʼя родини', 'Business Request']) {
        await repository.saveRequest(
          repository
              .draftRequest(const Color(0xFF4A99EF))
              .copyWith(title: title),
        );
      }
    });

    await pumpRequests(tester);
    await tester.enterText(find.byType(TextField).first, 'ЗДОРОВ');
    await tester.pumpAndSettle();

    expect(find.text('Здоровʼя родини'), findsOneWidget);
    expect(find.text('Business Request'), findsNothing);
  });
}
