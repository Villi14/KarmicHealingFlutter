import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karmic_healing_flutter/data/energy_settings.dart';
import 'package:karmic_healing_flutter/data/session_effects.dart';
import 'package:karmic_healing_flutter/screens/balancing_energy/balancing_energy_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/test_app.dart';

/// The effects a test gets: nothing reaches the device, and everything the
/// session asked for is kept in the order it was asked.
class _RecordedEffects extends SessionEffects {
  final List<String> calls = [];
  final List<double> volumes = [];

  @override
  Future<void> begin() async => calls.add('begin');

  @override
  Future<void> end() async => calls.add('end');

  @override
  Future<void> setDimmed(bool dimmed) async =>
      calls.add(dimmed ? 'dim' : 'undim');

  @override
  Future<void> chime(double volume) async {
    calls.add('chime');
    volumes.add(volume);
  }

  @override
  Future<void> vibrate() async => calls.add('vibrate');
}

void main() {
  Future<EnergySettings> settingsFrom(Map<String, Object> stored) {
    SharedPreferences.setMockInitialValues(stored);
    return EnergySettings.load();
  }

  /// A session on a clock the test winds by hand, so a step that takes minutes
  /// need not take minutes to test.
  Future<_RecordedEffects> openSession(
    WidgetTester tester, {
    required EnergySettings settings,
    required DateTime Function() now,
  }) async {
    final effects = _RecordedEffects();
    await tester.pumpWidget(
      testApp(
        energySettings: settings,
        home: BalancingEnergyScreen(
          kind: SessionKind.essentialSelf,
          title: 'Session',
          steps: const [
            EnergyStep('One'),
            EnergyStep('Two'),
            EnergyStep('Three'),
          ],
          effects: effects,
          now: now,
        ),
      ),
    );
    await tester.pump();
    return effects;
  }

  testWidgets('a session holds the device awake, and lets go on the way out', (
    tester,
  ) async {
    final settings = await settingsFrom({});
    final effects = await openSession(
      tester,
      settings: settings,
      now: DateTime.now,
    );

    expect(effects.calls, contains('begin'));

    await tester.pumpWidget(testApp(home: const SizedBox()));
    await tester.pump();

    expect(effects.calls, contains('end'));
  });

  testWidgets('a step change chimes and taps at the volume that was stored', (
    tester,
  ) async {
    final settings = await settingsFrom({
      EnergySettings.soundEnabledKey: true,
      EnergySettings.vibrationEnabledKey: true,
      EnergySettings.audioVolumeKey: .8,
    });
    final effects = await openSession(
      tester,
      settings: settings,
      now: DateTime.now,
    );

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    expect(effects.calls, containsAllInOrder(['chime', 'vibrate']));
    expect(effects.volumes, [.8]);
  });

  testWidgets('a step change is silent when neither was asked for', (
    tester,
  ) async {
    final settings = await settingsFrom({});
    final effects = await openSession(
      tester,
      settings: settings,
      now: DateTime.now,
    );

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    expect(effects.calls, isNot(contains('chime')));
    expect(effects.calls, isNot(contains('vibrate')));
  });

  testWidgets('the sound can be had without the vibration', (tester) async {
    final settings = await settingsFrom({EnergySettings.soundEnabledKey: true});
    final effects = await openSession(
      tester,
      settings: settings,
      now: DateTime.now,
    );

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    expect(effects.calls, contains('chime'));
    expect(effects.calls, isNot(contains('vibrate')));
  });

  testWidgets('a volume never chosen still rings at half, not in silence', (
    tester,
  ) async {
    final settings = await settingsFrom({EnergySettings.soundEnabledKey: true});
    final effects = await openSession(
      tester,
      settings: settings,
      now: DateTime.now,
    );

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    expect(effects.volumes, [.5]);
  });

  testWidgets('the screen rests once it has been left alone, and a touch '
      'brings it back', (tester) async {
    var now = DateTime(2026);
    final settings = await settingsFrom({
      EnergySettings.screenRestDelayKey: 15,
    });
    final effects = await openSession(
      tester,
      settings: settings,
      now: () => now,
    );

    // A moment short of the delay is still a session the user is looking at.
    now = now.add(const Duration(seconds: 14));
    await tester.pump(const Duration(seconds: 1));
    expect(effects.calls, isNot(contains('dim')));

    now = now.add(const Duration(seconds: 2));
    await tester.pump(const Duration(seconds: 1));
    expect(effects.calls, contains('dim'));
    expect(find.bySemanticsLabel('Rest the screen'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Rest the screen'));
    await tester.pump();

    expect(effects.calls, contains('undim'));
    expect(find.bySemanticsLabel('Rest the screen'), findsNothing);
  });

  testWidgets('a screen told not to rest stays lit however long it is left', (
    tester,
  ) async {
    var now = DateTime(2026);
    final settings = await settingsFrom({
      EnergySettings.screenRestEnabledKey: false,
    });
    final effects = await openSession(
      tester,
      settings: settings,
      now: () => now,
    );

    now = now.add(const Duration(minutes: 5));
    await tester.pump(const Duration(seconds: 1));

    expect(effects.calls, isNot(contains('dim')));
    expect(find.bySemanticsLabel('Rest the screen'), findsNothing);
  });

  testWidgets('a rest switched off mid-session lifts at once', (tester) async {
    var now = DateTime(2026);
    final settings = await settingsFrom({
      EnergySettings.screenRestDelayKey: 15,
    });
    final effects = await openSession(
      tester,
      settings: settings,
      now: () => now,
    );

    now = now.add(const Duration(seconds: 16));
    await tester.pump(const Duration(seconds: 1));
    expect(effects.calls, contains('dim'));

    await settings.setScreenRestEnabled(false);
    await tester.pump();

    expect(effects.calls, contains('undim'));
    expect(find.bySemanticsLabel('Rest the screen'), findsNothing);
  });

  testWidgets('a paused session is one the user is looking at, so it never '
      'rests', (tester) async {
    var now = DateTime(2026);
    final settings = await settingsFrom({
      EnergySettings.screenRestDelayKey: 15,
    });
    final effects = await openSession(
      tester,
      settings: settings,
      now: () => now,
    );

    await tester.tap(find.byTooltip('Pause'));
    await tester.pump();

    now = now.add(const Duration(minutes: 2));
    await tester.pump(const Duration(seconds: 1));

    expect(effects.calls, isNot(contains('dim')));
  });

  testWidgets('a session left behind holds its place rather than racing '
      'through the steps it was not watched for', (tester) async {
    var now = DateTime(2026);
    final settings = await settingsFrom({
      EnergySettings.sessionDurationKey: 1,
      EnergySettings.soundEnabledKey: true,
    });
    final effects = await openSession(
      tester,
      settings: settings,
      now: () => now,
    );

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();

    now = now.add(const Duration(minutes: 30));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('STEP 1 OF 3'), findsOneWidget);
    expect(effects.calls, isNot(contains('chime')));
  });
}
