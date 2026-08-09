import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karmic_healing_flutter/widgets/aura_widgets.dart';
import 'package:karmic_healing_flutter/widgets/color_picker_row.dart';

import 'support/test_app.dart';

/// The colour row: the swatches answer at once, and the last one opens the
/// whole spectrum.
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

  testWidgets('tapping a swatch reports that colour', (tester) async {
    const start = Color(0xFF4A99EF);
    final picked = await pumpRow(tester, start);

    final swatches = find.byType(GestureDetector);
    await tester.tap(swatches.at(3));
    await tester.pumpAndSettle();

    expect(picked, hasLength(1));
    expect(picked.single, isNot(start));
  });

  testWidgets('the last swatch opens the spectrum and reports what it settles '
      'on', (tester) async {
    final picked = await pumpRow(tester, const Color(0xFF4A99EF));

    await tester.tap(find.byType(GestureDetector).last);
    await tester.pumpAndSettle();
    expect(find.text('Done'), findsOneWidget);

    // A tap at the far end of the hue bar is a hue of its own.
    final hue = find.byKey(const Key('hue'));
    final bar = tester.getRect(hue);
    await tester.tapAt(Offset(bar.right - 1, bar.center.dy));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    expect(picked, hasLength(1));
    expect(HSVColor.fromColor(picked.single).hue, greaterThan(300));
    expect(picked.single.a, 1);
  });

  testWidgets('cancelling the spectrum leaves the colour alone', (
    tester,
  ) async {
    final picked = await pumpRow(tester, const Color(0xFF4A99EF));

    await tester.tap(find.byType(GestureDetector).last);
    await tester.pumpAndSettle();

    final hue = find.byKey(const Key('hue'));
    await tester.tapAt(tester.getRect(hue).centerLeft + const Offset(1, 0));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(picked, isEmpty);
  });
}
