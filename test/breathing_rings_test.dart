import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karmic_healing_flutter/widgets/aura_widgets.dart';

/// The ambient breath the session ring runs on.
void main() {
  test('the breath fills and empties over its period, and no further', () {
    final start = DateTime.fromMillisecondsSinceEpoch(0);

    expect(breathPhaseAt(start), closeTo(0, 1e-9));
    expect(breathPhaseAt(start.add(breathPeriod ~/ 2)), closeTo(1, 1e-9));
    expect(breathPhaseAt(start.add(breathPeriod)), closeTo(0, 1e-9));

    for (var step = 0; step <= 32; step++) {
      final phase = breathPhaseAt(start.add(breathPeriod * (step / 32)));
      expect(phase, inInclusiveRange(0, 1));
    }
  });

  test('every ring reads the same breath at the same moment', () {
    final moment = DateTime.now();
    expect(breathPhaseAt(moment), breathPhaseAt(moment));
    // A ring built a moment later is on the same inhale, not its own.
    expect(
      breathPhaseAt(moment.add(breathPeriod)),
      closeTo(breathPhaseAt(moment), 1e-9),
    );
  });

  testWidgets('the ring holds still where motion is asked to stop', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        ),
        home: const Scaffold(body: BreathingRings(level: AuraLevel.heart)),
      ),
    );

    // Nothing left animating is what lets this return at all.
    await tester.pumpAndSettle();
  });
}
