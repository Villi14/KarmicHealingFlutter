import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karmic_healing_flutter/widgets/aura_widgets.dart';
import 'package:karmic_healing_flutter/widgets/color_picker_row.dart';

import 'support/test_app.dart';

/// The colour row: one swatch, and behind it the whole spectrum.
void main() {
  Future<List<Color>> pumpRow(WidgetTester tester, Color color) async {
    final picked = <Color>[];
    await tester.pumpWidget(
      testApp(
        home: Scaffold(
          body: ColorPickerRow(
            level: AuraLevel.sacral,
            color: color,
            onChanged: picked.add,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return picked;
  }

  /// Drags the wheel's hue ring to the point opposite where the colour sits, so
  /// whatever it lands on is a hue of its own.
  Future<void> turnTheWheel(WidgetTester tester) async {
    final wheel = tester.getRect(find.byType(ColorWheelPicker));
    await tester.dragFrom(wheel.center, Offset(0, wheel.height / 2 - 6));
    await tester.pumpAndSettle();
  }

  testWidgets('the row offers the colour it was given, and no presets', (
    tester,
  ) async {
    await pumpRow(tester, const Color(0xFF4A99EF));
    expect(find.byType(GestureDetector), findsOneWidget);
  });

  testWidgets('the swatch opens the spectrum and reports what it settles on', (
    tester,
  ) async {
    const start = Color(0xFF4A99EF);
    final picked = await pumpRow(tester, start);

    await tester.tap(find.byType(GestureDetector));
    await tester.pumpAndSettle();
    expect(find.text('Done'), findsOneWidget);

    await turnTheWheel(tester);
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    expect(picked, hasLength(1));
    expect(picked.single, isNot(start));
    expect(picked.single.a, 1);
  });

  testWidgets('cancelling the spectrum leaves the colour alone', (
    tester,
  ) async {
    final picked = await pumpRow(tester, const Color(0xFF4A99EF));

    await tester.tap(find.byType(GestureDetector));
    await tester.pumpAndSettle();

    await turnTheWheel(tester);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(picked, isEmpty);
  });
}
