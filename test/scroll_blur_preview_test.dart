import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karmic_healing_flutter/screens/requests/requests_help_screen.dart';

/// Captures a screen at rest and scrolled, so the navigation bar's frosting can
/// be eyeballed. Not an assertion — a QA aid.
void main() {
  testWidgets('navigation bar frosts as content scrolls under it', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(402, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    const boundaryKey = Key('screen');
    await tester.pumpWidget(
      const RepaintBoundary(
        key: boundaryKey,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          home: RequestsHelpScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    Future<void> capture(String name) async {
      final boundary =
          tester.renderObject(find.byKey(boundaryKey)) as RenderRepaintBoundary;
      final bytes = await tester.binding.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 2);
        return image.toByteData(format: ui.ImageByteFormat.png);
      });
      File('outputs/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
    }

    await capture('blur_at_rest');

    await tester.drag(find.byType(Scrollable).first, const Offset(0, -260));
    await tester.pumpAndSettle();
    await capture('blur_scrolled');
  });
}
