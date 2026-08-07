import 'dart:math' as math;

import 'package:flutter/cupertino.dart';

/// The SF Symbols the iOS app draws, named as the SwiftUI sources name them.
///
/// Cupertino Icons is a port of the SF Symbols glyphs, so nearly every symbol
/// the iOS app uses has an exact counterpart there — reaching for a Material
/// icon instead is what put the port's glyphs out of step with the original.
/// The five symbols Cupertino Icons has no counterpart for are drawn by hand
/// as [SFIcon] instead.
abstract final class SFSymbols {
  static const chevronLeft = CupertinoIcons.chevron_left;
  static const chevronRight = CupertinoIcons.chevron_right;
  static const chevronUpChevronDown = CupertinoIcons.chevron_up_chevron_down;
  static const arrowUpArrowDown = CupertinoIcons.arrow_up_arrow_down;
  static const arrowRight = CupertinoIcons.arrow_right;

  static const plus = CupertinoIcons.plus;
  static const xmark = CupertinoIcons.xmark;
  static const xmarkCircle = CupertinoIcons.xmark_circle;
  static const checkmark = CupertinoIcons.checkmark;
  static const checkmarkCircle = CupertinoIcons.checkmark_circle;
  static const ellipsis = CupertinoIcons.ellipsis;

  static const infoCircle = CupertinoIcons.info_circle;
  static const questionmarkCircle = CupertinoIcons.question_circle;
  static const exclamationmark = CupertinoIcons.exclamationmark;
  static const exclamationmarkTriangle =
      CupertinoIcons.exclamationmark_triangle;

  static const calendar = CupertinoIcons.calendar;
  static const clock = CupertinoIcons.clock;
  static const timer = CupertinoIcons.timer;
  static const bell = CupertinoIcons.bell;
  static const tray = CupertinoIcons.tray;

  static const magnifyingglass = CupertinoIcons.search;
  static const envelope = CupertinoIcons.envelope;
  static const globe = CupertinoIcons.globe;
  static const eye = CupertinoIcons.eye;
  static const trash = CupertinoIcons.trash;
  static const tag = CupertinoIcons.tag;
  static const flag = CupertinoIcons.flag;
  static const flagFill = CupertinoIcons.flag_fill;
  static const chartBar = CupertinoIcons.chart_bar;
  static const textformatCharacters = CupertinoIcons.textformat_abc;
  static const lightbulb = CupertinoIcons.lightbulb;
  static const staroflife = CupertinoIcons.staroflife;
  static const moonStars = CupertinoIcons.moon_stars;
  static const sunMax = CupertinoIcons.sun_max;
  static const heart = CupertinoIcons.heart;
  static const handRaised = CupertinoIcons.hand_raised;
  static const book = CupertinoIcons.book;
  static const sparkles = CupertinoIcons.sparkles;
  static const speakerWave2 = CupertinoIcons.speaker_2;
  static const speakerWave3 = CupertinoIcons.speaker_3;
  static const play = CupertinoIcons.play;
  static const pause = CupertinoIcons.pause;
  static const circle = CupertinoIcons.circle;
  static const circleFill = CupertinoIcons.largecircle_fill_circle;
}

/// An SF Symbol with no Cupertino Icons counterpart, drawn to match the weight
/// and proportions of the font glyphs it sits beside.
enum SFGlyph {
  meditate,
  leaf,
  gearshape,
  pencilAndListClipboard,
  iphoneRadiowaves,
}

/// Renders an [SFGlyph]. Sizes and tints itself from the ambient [IconTheme]
/// exactly as [Icon] does, so it drops into any slot a font glyph would fill.
class SFIcon extends StatelessWidget {
  const SFIcon(this.glyph, {super.key, this.size, this.color});

  final SFGlyph glyph;
  final double? size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = IconTheme.of(context);
    final dimension = size ?? theme.size ?? 24;
    return SizedBox.square(
      dimension: dimension,
      child: CustomPaint(
        painter: _SFGlyphPainter(
          glyph,
          color ?? theme.color ?? const Color(0xFF000000),
        ),
      ),
    );
  }
}

class _SFGlyphPainter extends CustomPainter {
  const _SFGlyphPainter(this.glyph, this.color);

  final SFGlyph glyph;
  final Color color;

  /// Every glyph below is authored on a 100x100 canvas.
  static const _canvas = 100.0;

  /// Matches the stroke of a regular-weight SF Symbol at the same optical size.
  static const _stroke = 7.0;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.shortestSide / _canvas;
    canvas.save();
    canvas.translate(
      (size.width - _canvas * scale) / 2,
      (size.height - _canvas * scale) / 2,
    );
    canvas.scale(scale);

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    switch (glyph) {
      case SFGlyph.meditate:
        _paintMeditate(canvas, paint);
      case SFGlyph.leaf:
        _paintLeaf(canvas, paint);
      case SFGlyph.gearshape:
        _paintGearshape(canvas, paint);
      case SFGlyph.pencilAndListClipboard:
        _paintClipboard(canvas, paint);
      case SFGlyph.iphoneRadiowaves:
        _paintRadiowaves(canvas, paint);
    }
    canvas.restore();
  }

  /// `apple.meditate` — a figure seated cross-legged, hands resting on the knees.
  void _paintMeditate(Canvas canvas, Paint paint) {
    canvas.drawCircle(const Offset(50, 15), 9.5, paint);
    // Torso and arms as one silhouette, kept narrow so the crossed legs below
    // read as legs rather than as the base of a bell.
    canvas.drawPath(
      Path()
        ..moveTo(29, 79)
        ..cubicTo(28, 52, 37, 33, 50, 33)
        ..cubicTo(63, 33, 72, 52, 71, 79),
      paint,
    );
    // Crossed legs, reaching well past the body on both sides.
    canvas.drawPath(
      Path()
        ..moveTo(8, 80)
        ..quadraticBezierTo(50, 68, 92, 80)
        ..quadraticBezierTo(50, 94, 8, 80)
        ..close(),
      paint,
    );
  }

  /// `leaf` — a pointed tip up to the right over a rounded base, with its midrib.
  void _paintLeaf(Canvas canvas, Paint paint) {
    canvas.drawPath(
      Path()
        ..moveTo(87, 13)
        ..cubicTo(48, 13, 17, 40, 17, 71)
        ..cubicTo(17, 83, 27, 89, 41, 86)
        ..cubicTo(71, 80, 87, 52, 87, 13)
        ..close(),
      paint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(24, 84)
        ..cubicTo(44, 62, 62, 44, 82, 20),
      paint,
    );
  }

  /// `gearshape` — eight tapered teeth around a hub.
  void _paintGearshape(Canvas canvas, Paint paint) {
    const center = Offset(50, 50);
    const teeth = 8;
    const outer = 45.0;
    const root = 33.0;
    const step = 2 * math.pi / teeth;
    // Half-widths: the teeth are wider where they meet the hub than at the tip.
    const tipHalf = 0.20;
    const rootHalf = 0.36;

    Offset at(double radius, double angle) =>
        center + Offset(math.cos(angle) * radius, math.sin(angle) * radius);

    final path = Path()..moveTo(at(outer, -tipHalf).dx, at(outer, -tipHalf).dy);
    for (var i = 0; i < teeth; i++) {
      final a = i * step;
      path
        ..arcTo(
          Rect.fromCircle(center: center, radius: outer),
          a - tipHalf,
          tipHalf * 2,
          false,
        )
        ..lineTo(at(root, a + rootHalf).dx, at(root, a + rootHalf).dy)
        ..arcTo(
          Rect.fromCircle(center: center, radius: root),
          a + rootHalf,
          step - rootHalf * 2,
          false,
        )
        ..lineTo(
          at(outer, a + step - tipHalf).dx,
          at(outer, a + step - tipHalf).dy,
        );
    }
    path.close();
    canvas.drawPath(path, paint);
    canvas.drawCircle(center, 14, paint);
  }

  /// `pencil.and.list.clipboard` — a ruled clipboard with a pencil across it.
  void _paintClipboard(Canvas canvas, Paint paint) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTRB(9, 21, 63, 92),
        const Radius.circular(9),
      ),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTRB(26, 11, 46, 27),
        const Radius.circular(5),
      ),
      paint,
    );
    for (final line in const [
      (Offset(21, 48), Offset(51, 48)),
      (Offset(21, 63), Offset(51, 63)),
      (Offset(21, 78), Offset(40, 78)),
    ]) {
      canvas.drawLine(line.$1, line.$2, paint);
    }
    // Pencil: a tip, a shaft, and the ferrule line across it.
    canvas.drawPath(
      Path()
        ..moveTo(58, 82)
        ..lineTo(71.4, 68.5)
        ..lineTo(94.1, 46.0)
        ..lineTo(84.2, 55.9)
        ..lineTo(61.5, 78.4)
        ..close(),
      paint,
    );
    canvas.drawLine(const Offset(71.4, 68.5), const Offset(61.5, 78.4), paint);
  }

  /// `iphone.radiowaves.left.and.right` — a handset broadcasting to both sides.
  void _paintRadiowaves(Canvas canvas, Paint paint) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTRB(37, 19, 63, 81),
        const Radius.circular(7),
      ),
      paint,
    );
    canvas.drawLine(const Offset(45, 27), const Offset(55, 27), paint);
    const center = Offset(50, 50);
    for (final radius in const [22.0, 34.0]) {
      for (final start in const [math.pi * 3 / 4, -math.pi / 4]) {
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          start,
          math.pi / 2,
          false,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SFGlyphPainter old) =>
      old.glyph != glyph || old.color != color;
}
