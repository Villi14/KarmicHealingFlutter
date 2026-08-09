import 'package:flutter_test/flutter_test.dart';
import 'package:karmic_healing_flutter/data/energy_settings.dart';
import 'package:karmic_healing_flutter/screens/balancing_energy/balancing_energy_list_screen.dart';
import 'package:karmic_healing_flutter/screens/balancing_energy/energy_settings_screen.dart';
import 'package:karmic_healing_flutter/widgets/aura_widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/test_app.dart';

void main() {
  Future<EnergySettings> settingsFrom(Map<String, Object> stored) {
    SharedPreferences.setMockInitialValues(stored);
    return EnergySettings.load();
  }

  test('a store nobody has touched answers with the defaults', () async {
    final settings = await settingsFrom({});

    expect(settings.sessionDuration, 5);
    expect(settings.stepDuration, const Duration(minutes: 5));
    expect(settings.soundEnabled, isFalse);
    expect(settings.vibrationEnabled, isFalse);
    expect(settings.audioVolume, .5);
    expect(settings.screenRestEnabled, isTrue, reason: 'on out of the box');
    expect(settings.screenRestDelay, 30);
    expect(settings.initialProcessCompleted, isFalse);
  });

  test(
    'a duration of zero reads as the default, not as no time at all',
    () async {
      final settings = await settingsFrom({
        EnergySettings.sessionDurationKey: 0,
        EnergySettings.screenRestDelayKey: 0,
      });

      expect(settings.sessionDuration, 5);
      expect(settings.screenRestDelay, 30);
    },
  );

  test('what is stored is what the Swift app stores it under', () async {
    final settings = await settingsFrom({});
    await settings.setSessionDuration(10);
    await settings.setSoundEnabled(true);
    await settings.setAudioVolume(.8);
    await settings.setScreenRestEnabled(false);
    await settings.completeInitialProcess();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('session_duration'), 10);
    expect(prefs.getBool('sound_enabled'), isTrue);
    expect(prefs.getDouble('audio_volume'), .8);
    expect(prefs.getBool('screen_rest_enabled'), isFalse);
    expect(prefs.getBool('initial_process_completed'), isTrue);
  });

  test('a change tells whoever is watching', () async {
    final settings = await settingsFrom({});
    var heard = 0;
    settings.addListener(() => heard++);

    await settings.setSessionDuration(3);
    await settings.setVibrationEnabled(true);

    expect(heard, 2);
  });

  testWidgets(
    'the settings screen shows what was stored, and stores what is picked',
    (tester) async {
      final settings = await settingsFrom({
        EnergySettings.sessionDurationKey: 3,
      });
      await tester.pumpWidget(
        testApp(home: const EnergySettingsScreen(), energySettings: settings),
      );
      await tester.pumpAndSettle();

      expect(find.text('3 minutes'), findsOneWidget);

      await tester.tap(find.text('3 minutes'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('15 minutes').last);
      await tester.pumpAndSettle();

      expect(settings.sessionDuration, 15);
      expect(find.text('15 minutes'), findsOneWidget);
    },
  );

  testWidgets('the volume slider waits for the sound to be turned on', (
    tester,
  ) async {
    final settings = await settingsFrom({});
    await tester.pumpWidget(
      testApp(home: const EnergySettingsScreen(), energySettings: settings),
    );
    await tester.pumpAndSettle();

    expect(
      tester.widget<AuraSlider>(find.byType(AuraSlider)).onChanged,
      isNull,
    );

    await tester.tap(find.byType(AuraSwitch).at(1));
    await tester.pumpAndSettle();

    expect(settings.soundEnabled, isTrue);
    expect(
      tester.widget<AuraSlider>(find.byType(AuraSlider)).onChanged,
      isNotNull,
    );
  });

  testWidgets('the initial process steps aside once it has been walked', (
    tester,
  ) async {
    final settings = await settingsFrom({});
    await tester.pumpWidget(
      testApp(
        home: const BalancingEnergyListScreen(),
        energySettings: settings,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Initial process'), findsOneWidget);

    await settings.completeInitialProcess();
    await tester.pumpAndSettle();

    expect(find.text('Initial process'), findsNothing);
    expect(find.text('Essential Self'), findsOneWidget);
  });
}
