import 'package:flutter_test/flutter_test.dart';
import 'package:karmic_healing_flutter/data/energy_settings.dart';
import 'package:karmic_healing_flutter/data/session_effects.dart';
import 'package:karmic_healing_flutter/screens/balancing_energy/balancing_energy_screen.dart';
import 'package:karmic_healing_flutter/widgets/aura_widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/test_app.dart';

/// A step with more to say than the card is tall.
const _long =
    'Sit with the breath and let it settle, and when it has settled, '
    'let it settle further. ';

void main() {
  Future<void> openSession(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final settings = await EnergySettings.load();

    await tester.pumpWidget(
      testApp(
        energySettings: settings,
        home: BalancingEnergyScreen(
          kind: SessionKind.divineSelf,
          title: 'Session',
          steps: [
            EnergyStep('The long one', _long * 12),
            const EnergyStep('Two'),
          ],
          effects: const NoSessionEffects(),
        ),
      ),
    );
    await tester.pump();
  }

  /// Drags the card's words up. The handle is the title rather than the
  /// passage: the passage is taller than the screen, so its middle — where a
  /// drag would take hold — is nowhere on it.
  Future<void> scrollTheWords(WidgetTester tester) async {
    await tester.drag(find.text('The long one'), const Offset(0, -120));
    await tester.pump();
  }

  testWidgets('a step with more words than fit scrolls inside its card', (
    tester,
  ) async {
    await openSession(tester);

    final description = find.textContaining('let it settle');
    final before = tester.getRect(description);

    await scrollTheWords(tester);

    expect(
      tester.getRect(description).top,
      lessThan(before.top),
      reason: 'the words should have moved up under the ring',
    );
  });

  testWidgets('the counter and the ring stay put while the words move', (
    tester,
  ) async {
    await openSession(tester);

    final ring = find.byType(BreathingRings);
    final before = tester.getRect(ring);

    await scrollTheWords(tester);

    expect(tester.getRect(ring), before);
    expect(find.text('STEP 1 OF 2'), findsOneWidget);
  });

  testWidgets('scrolling the words does not turn the page', (tester) async {
    await openSession(tester);

    await scrollTheWords(tester);

    expect(find.text('The long one'), findsOneWidget);
    expect(find.text('Two'), findsNothing);
  });
}
