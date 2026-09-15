import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karmic_healing_flutter/data/repository_scope.dart';
import 'package:karmic_healing_flutter/screens/requests/request_detail_screen.dart';
import 'package:karmic_healing_flutter/screens/requests/subrequest_row.dart';

import 'support/test_app.dart';
import 'support/test_repositories.dart';

/// A request's own screen: what it says about being ready to fulfil, and what
/// tapping the radio button does about it.
void main() {
  setUpAll(useTestDatabaseFactory);

  late TestRepositories repositories;
  setUp(() async => repositories = await emptyRepositories());

  Future<void> write(WidgetTester tester, Future<void> Function() body) =>
      tester.runAsync(body);

  Future<String> addRequest(WidgetTester tester, {String title = 'Health'}) {
    late String id;
    return write(tester, () async {
      final request = repositories.requests
          .draftRequest(const Color(0xFF4A99EF))
          .copyWith(title: title);
      await repositories.requests.saveRequest(request);
      id = request.id;
    }).then((_) => id);
  }

  Future<void> pumpDetail(WidgetTester tester, String requestId) async {
    await tester.pumpWidget(
      RepositoryScope(
        requests: repositories.requests,
        reminders: repositories.reminders,
        child: testApp(home: RequestDetailScreen(requestId: requestId)),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('a request with nothing under it says it is ready', (
    tester,
  ) async {
    final id = await addRequest(tester);
    await pumpDetail(tester, id);

    expect(find.text('Ready to be fulfilled'), findsOneWidget);
  });

  testWidgets(
    'a request with an open subrequest says how much is left',
    (tester) async {
      final id = await addRequest(tester);
      await write(tester, () async {
        final subrequest = repositories.requests
            .draftSubrequest(id)
            .copyWith(title: 'Book a check-up');
        await repositories.requests.saveSubrequest(subrequest);
      });
      await pumpDetail(tester, id);

      expect(find.byType(SubrequestRow), findsOneWidget);
      expect(find.text('Book a check-up'), findsOneWidget);
      expect(find.text('Fulfil every subrequest first (0 of 1)'), findsOneWidget);
    },
  );

  testWidgets('fulfilling the last subrequest unlocks the request', (
    tester,
  ) async {
    final id = await addRequest(tester);
    late String subrequestId;
    await write(tester, () async {
      final subrequest = repositories.requests
          .draftSubrequest(id)
          .copyWith(title: 'Book a check-up');
      await repositories.requests.saveSubrequest(subrequest);
      subrequestId = subrequest.id;
    });
    await pumpDetail(tester, id);

    await write(
      tester,
      () => repositories.requests.toggleSubrequest(subrequestId),
    );
    await tester.pumpAndSettle();

    expect(find.text('Every subrequest is fulfilled'), findsOneWidget);
  });

  testWidgets('the screen closes itself once its request is gone', (
    tester,
  ) async {
    final id = await addRequest(tester);
    await pumpDetail(tester, id);
    expect(find.byType(RequestDetailScreen), findsOneWidget);

    await write(tester, () => repositories.requests.deleteRequest(id));
    await tester.pumpAndSettle();

    expect(find.text('Health'), findsNothing);
  });
}
