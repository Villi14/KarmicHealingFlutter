import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karmic_healing_flutter/screens/home/home_screen.dart';

import 'support/test_app.dart';

void main() {
  Future<void> pumpAt(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(testApp(home: const HomeScreen()));
    await tester.pump();
    // A window too short for the whole screen says so during that first
    // layout, and settles into the scrolling arrangement on the next frame.
    await tester.pump();
  }

  ScrollableState scrollable(WidgetTester tester) =>
      tester.state(find.byType(Scrollable).first);

  // Every window with the height for the screen shows it whole: the desktop
  // and tablet sizes, and the phones — a 1080p phone is about 390 x 840
  // points, whichever way its pixels are counted.
  for (final size in const [
    Size(1920, 1080),
    Size(1440, 900),
    Size(1280, 720),
    Size(1024, 768),
    Size(834, 1194),
    Size(390, 844),
    Size(411, 731),
    Size(393, 698),
    Size(375, 667),
  ]) {
    testWidgets('home shows every tool without scrolling at $size', (
      tester,
    ) async {
      await pumpAt(tester, size);
      expect(
        scrollable(tester).position.maxScrollExtent,
        0,
        reason: 'content should fit at $size',
      );
      for (final tool in const ['Requests', 'Reminders', 'Settings']) {
        expect(find.text(tool), findsOneWidget);
        expect(
          tester.getRect(find.text(tool)).bottom,
          lessThanOrEqualTo(size.height),
          reason: '$tool should be on screen at $size',
        );
      }
      expect(tester.takeException(), isNull);
    });
  }

  // A phone on its side is too short even for a single folded row: it scrolls,
  // as it always has, but it lays out without overflowing.
  for (final size in const [Size(844, 390)]) {
    testWidgets('home scrolls without overflowing at $size', (tester) async {
      await pumpAt(tester, size);
      expect(scrollable(tester).position.maxScrollExtent, greaterThan(0));
      expect(tester.takeException(), isNull);
    });
  }
}
