import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karmic_healing_flutter/widgets/sf_symbols.dart';

/// Renders the hand-drawn SF glyphs to a PNG so they can be eyeballed against
/// the iOS originals. Not an assertion — a QA aid.
void main() {
  testWidgets('render hand-drawn SF glyphs', (tester) async {
    tester.view.physicalSize = const Size(1200, 300);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: RepaintBoundary(
          key: const Key('sheet'),
          child: ColoredBox(
            color: const Color(0xFFFFFFFF),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (final glyph in SFGlyph.values)
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SFIcon(glyph, size: 120, color: const Color(0xFF111111)),
                        const SizedBox(height: 8),
                        SFIcon(glyph, size: 24, color: const Color(0xFF111111)),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final image = await tester.binding.runAsync(
      () async => (tester.renderObject(find.byKey(const Key('sheet')))
              as RenderRepaintBoundary)
          .toImage(pixelRatio: 2),
    );
    final bytes = await tester.binding.runAsync(
      () async => image!.toByteData(format: ui.ImageByteFormat.png),
    );
    File(
      Platform.environment['SF_PREVIEW_OUT'] ?? 'outputs/sf_glyphs.png',
    ).writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}
