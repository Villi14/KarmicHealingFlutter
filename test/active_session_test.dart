import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karmic_healing_flutter/data/energy_settings.dart';
import 'package:karmic_healing_flutter/data/session_effects.dart';
import 'package:karmic_healing_flutter/screens/balancing_energy/balancing_energy_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/test_app.dart';

void main() {
  Future<EnergySettings> settingsFrom(Map<String, Object> stored) {
    SharedPreferences.setMockInitialValues(stored);
    return EnergySettings.load();
  }

  Future<void> openSession(
    WidgetTester tester, {
    required EnergySettings settings,
    SessionKind kind = SessionKind.divineSelf,
  }) async {
    await tester.pumpWidget(
      testApp(
        energySettings: settings,
        home: BalancingEnergyScreen(
          kind: kind,
          title: 'Session',
          steps: const [
            EnergyStep('One'),
            EnergyStep('Two'),
            EnergyStep('Three'),
          ],
          effects: const NoSessionEffects(),
        ),
      ),
    );
    await tester.pump();
  }

  test('a store nobody has meditated with has no session in it', () async {
    final settings = await settingsFrom({});

    expect(settings.activeSessionKind, isNull);
    expect(settings.activeSessionStep, 0);
  });

  test('what is stored is what the Swift app stores it under', () async {
    final settings = await settingsFrom({});
    await settings.setActiveSession('essentialSelf', 4);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('active_session_kind'), 'essentialSelf');
    expect(prefs.getInt('active_session_step'), 4);

    await settings.clearActiveSession();

    expect(prefs.getString('active_session_kind'), isNull);
    expect(prefs.getInt('active_session_step'), isNull);
  });

  testWidgets('a session records the step it has reached', (tester) async {
    final settings = await settingsFrom({});
    await openSession(tester, settings: settings);

    // Nothing is written for the step a session opens on — there is no session
    // to speak of until it has moved.
    expect(settings.activeSessionKind, isNull);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    expect(settings.activeSessionKind, 'divineSelf');
    expect(settings.activeSessionStep, 1);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    expect(settings.activeSessionStep, 2);
  });

  testWidgets('a step taken back is recorded too', (tester) async {
    final settings = await settingsFrom({});
    await openSession(tester, settings: settings);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Back'));
    await tester.pumpAndSettle();

    expect(settings.activeSessionStep, 0);
  });

  testWidgets('a session leaves nothing of itself behind when it ends', (
    tester,
  ) async {
    final settings = await settingsFrom({});
    await openSession(tester, settings: settings);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(settings.activeSessionKind, isNotNull);

    // Walked to the end: the last step's button finishes rather than advances.
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    expect(settings.activeSessionKind, isNull);
    expect(settings.activeSessionStep, 0);
  });

  testWidgets('a session walked away from halfway leaves nothing either', (
    tester,
  ) async {
    final settings = await settingsFrom({});
    await openSession(tester, settings: settings);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(settings.activeSessionKind, isNotNull);

    await tester.pumpWidget(testApp(home: const SizedBox()));
    await tester.pumpAndSettle();

    expect(settings.activeSessionKind, isNull);
  });
}
