import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karmic_healing_flutter/data/repository_scope.dart';
import 'package:karmic_healing_flutter/l10n/app_localizations.dart';
import 'package:karmic_healing_flutter/screens/home/home_screen.dart';
import 'package:karmic_healing_flutter/screens/requests/requests_screen.dart';

import 'support/test_app.dart';
import 'support/test_repositories.dart';

/// The three languages the Swift app ships, ported along with the strings
/// themselves: what the screens show follows the device, and nothing is left
/// hardcoded in English behind it.
void main() {
  setUpAll(useTestDatabaseFactory);

  late TestRepositories repositories;
  setUp(() async => repositories = await emptyRepositories());

  Future<void> pump(WidgetTester tester, Widget home, Locale locale) async {
    await tester.pumpWidget(
      RepositoryScope(
        requests: repositories.requests,
        reminders: repositories.reminders,
        child: testApp(home: home, locale: locale),
      ),
    );
    await tester.pumpAndSettle();
  }

  test('every supported language carries the whole catalogue', () {
    expect(
      AppLocalizations.supportedLocales.map((locale) => locale.languageCode),
      containsAll(<String>['en', 'uk', 'ru']),
    );
  });

  testWidgets('a Ukrainian device gets a Ukrainian home screen', (
    tester,
  ) async {
    await pump(tester, const HomeScreen(), const Locale('uk'));

    expect(find.text('Ваші інструменти'), findsOneWidget);
    expect(find.text('Прохання'), findsOneWidget);
    expect(find.text('Мить, щоб повернутися до себе'), findsOneWidget);
    expect(find.text('Your tools'), findsNothing);
  });

  testWidgets('a Russian device gets a Russian home screen', (tester) async {
    await pump(tester, const HomeScreen(), const Locale('ru'));

    expect(find.text('Ваши инструменты'), findsOneWidget);
    expect(find.text('Настройки'), findsOneWidget);
  });

  testWidgets('the empty state speaks the language too', (tester) async {
    await pump(tester, const RequestsScreen(), const Locale('uk'));

    expect(find.text('Почніть із прохання'), findsOneWidget);
    expect(find.text('Додати прохання'), findsOneWidget);
  });

  testWidgets('an unsupported language falls back to English', (tester) async {
    await pump(tester, const HomeScreen(), const Locale('fr'));

    expect(find.text('Your tools'), findsOneWidget);
  });
}
