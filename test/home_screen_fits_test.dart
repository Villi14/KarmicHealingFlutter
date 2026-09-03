import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karmic_healing_flutter/constants/design_constants.dart';
import 'package:karmic_healing_flutter/screens/home/home_screen.dart';
import 'package:karmic_healing_flutter/widgets/aura_widgets.dart';

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
  // and tablet sizes, and the phones. A 1080p phone counts its pixels three,
  // two and three quarters, or two and five eighths to the point, and 360 x 640
  // — the narrowest and shortest of those — is the one the screen has to be
  // laid out to hold.
  for (final size in const [
    Size(1920, 1080),
    Size(1440, 900),
    Size(1280, 720),
    Size(1024, 768),
    Size(834, 1194),
    Size(390, 844),
    Size(360, 640),
    Size(360, 720),
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
      Rect card(String tool) => tester.getRect(
        find.ancestor(of: find.text(tool), matching: find.byType(AuraCard)),
      );

      for (final tool in const ['Requests', 'Reminders', 'Settings']) {
        expect(find.text(tool), findsOneWidget);
        expect(
          card(tool).bottom,
          lessThanOrEqualTo(size.height),
          reason: '$tool should be on screen at $size',
        );
      }
      // The two tools share the row under the heading, the third follows one
      // gap under the first — not driven down to the foot of the window — and
      // all three are one size.
      expect(card('Requests').top, moreOrLessEquals(card('Reminders').top));
      expect(card('Requests').right, lessThan(card('Reminders').left));
      expect(card('Settings').left, moreOrLessEquals(card('Requests').left));
      expect(
        card('Settings').top - card('Requests').bottom,
        moreOrLessEquals(DesignConstants.spacingMedium),
        reason: 'the tools should stay one block at $size',
      );
      for (final tool in const ['Reminders', 'Settings']) {
        expect(
          card(tool).size,
          within(distance: 0.5, from: card('Requests').size),
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
