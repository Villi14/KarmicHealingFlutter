import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karmic_healing_flutter/data/repository_scope.dart';
import 'package:karmic_healing_flutter/l10n/app_locales.dart';
import 'package:karmic_healing_flutter/l10n/app_localizations.dart';
import 'package:karmic_healing_flutter/l10n/translation.dart';
import 'package:karmic_healing_flutter/screens/home/home_screen.dart';
import 'package:karmic_healing_flutter/screens/requests/requests_screen.dart';

import 'support/test_app.dart';
import 'support/test_repositories.dart';

/// The fifteen languages the Swift app ships, ported along with the strings
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
      containsAll(<String>[
        'en', 'uk', 'ru', 'de', 'es', 'fr', 'it', 'ja', //
        'ko', 'pl', 'pt', 'tr', 'zh', 'bn', 'hi',
      ]),
    );
  });

  test('every language carries every string, and no stray ones', () {
    Set<String> keysOf(String locale) =>
        (jsonDecode(File('lib/l10n/app_$locale.arb').readAsStringSync())
                as Map<String, dynamic>)
            .keys
            .where((key) => !key.startsWith('@'))
            .toSet();

    final template = keysOf('en');
    expect(template, isNotEmpty);

    for (final locale in AppLocalizations.supportedLocales) {
      expect(
        keysOf(locale.languageCode),
        template,
        reason: '\${locale.languageCode} is out of step with the template',
      );
    }
  });

  test('a device speaking none of the fifteen is answered in English', () {
    expect(AppLocales.resolve(const [Locale('sv')]), AppLocales.fallback);
    expect(AppLocales.resolve(null), AppLocales.fallback);
    // A regional variant stands or falls with its language.
    expect(AppLocales.resolve(const [Locale('pt', 'PT')]), const Locale('pt'));
    expect(AppLocales.resolve(const [Locale('de', 'AT')]), const Locale('de'));
    // The first the device asks for that the app can answer in, not the first
    // it supports.
    expect(
      AppLocales.resolve(const [Locale('sv'), Locale('ja'), Locale('uk')]),
      const Locale('ja'),
    );
  });

  test('only the three languages somebody read are vouched for', () {
    for (final locale in const [Locale('en'), Locale('uk'), Locale('ru')]) {
      expect(
        Translation.isMachineTranslated(locale),
        isFalse,
        reason: '\${locale.languageCode} was apologised for',
      );
    }
    for (final locale in const [Locale('de'), Locale('ja'), Locale('pt')]) {
      expect(
        Translation.isMachineTranslated(locale),
        isTrue,
        reason: '\${locale.languageCode} passed itself off as read',
      );
    }
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

  testWidgets('a French device gets a French home screen', (tester) async {
    await pump(tester, const HomeScreen(), const Locale('fr'));

    expect(find.text('Vos outils'), findsOneWidget);
  });

  testWidgets('an unsupported language falls back to English', (tester) async {
    // Not merely the first of `supportedLocales`, which is alphabetical by ARB
    // file and so would hand a Swedish device Bengali.
    await pump(tester, const HomeScreen(), const Locale('sv'));

    expect(find.text('Your tools'), findsOneWidget);
  });
}
