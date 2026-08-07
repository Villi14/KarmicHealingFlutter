import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import 'sf_symbols.dart';

enum AuraLevel { root, sacral, solar, heart, throat, brow, crown }

/// The spectrum shifts with the appearance — every level is a touch brighter on
/// a dark page — so a level only becomes a colour once it knows where it is
/// being painted.
extension AuraLevelStyle on AuraLevel {
  Color color(BuildContext context) {
    final colors = AppColors.of(context);
    return switch (this) {
      AuraLevel.root => colors.energy,
      AuraLevel.sacral => colors.friendly,
      AuraLevel.solar => colors.clarity,
      AuraLevel.heart => colors.health,
      AuraLevel.throat => colors.clam,
      AuraLevel.brow => colors.peace,
      AuraLevel.crown => colors.wisdom,
    };
  }

  Color nextColor(BuildContext context) {
    final levels = AuraLevel.values;
    return levels[index == levels.length - 1 ? index - 1 : index + 1].color(
      context,
    );
  }

  LinearGradient gradient(BuildContext context) => LinearGradient(
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
    colors: [color(context), nextColor(context)],
  );
}

class AuraRings extends StatelessWidget {
  const AuraRings({
    super.key,
    required this.level,
    this.tone,
    this.size = 78,
    this.count = 3,
    this.opacity = .5,
    this.core = false,
  });

  final AuraLevel level;
  final Color? tone;
  final double size;
  final int count;
  final double opacity;
  final bool core;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(
      painter: _RingsPainter(
        colors: tone == null
            ? [level.color(context), level.nextColor(context)]
            : [tone!, Color.lerp(tone!, Colors.white, .3)!],
        count: count,
        opacity: opacity,
        core: core,
      ),
    ),
  );
}

class _RingsPainter extends CustomPainter {
  const _RingsPainter({
    required this.colors,
    required this.count,
    required this.opacity,
    required this.core,
  });

  final List<Color> colors;
  final int count;
  final double opacity;
  final bool core;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final shader = LinearGradient(colors: colors).createShader(rect);
    final paint = Paint()
      ..shader = shader
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.white.withValues(alpha: opacity);
    for (var i = 0; i < count; i++) {
      final radius = size.shortestSide / 2 * (i + 1) / count;
      canvas.drawCircle(rect.center, radius - .5, paint);
    }
    if (core) {
      canvas.drawCircle(
        rect.center,
        6,
        Paint()
          ..shader = shader
          ..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RingsPainter oldDelegate) => false;
}

/// The two-tone sheen built from a colour the row or card carries itself:
/// that colour, and the same colour lightened.
LinearGradient toneGradient(Color tone) => LinearGradient(
  begin: Alignment.bottomLeft,
  end: Alignment.topRight,
  colors: [tone, Color.lerp(tone, Colors.white, .3)!],
);

class AuraCard extends StatelessWidget {
  const AuraCard({
    super.key,
    required this.level,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.watermark = true,
    this.onTap,
    this.tone,
    this.elevated = true,
  });

  final AuraLevel level;
  final Widget child;
  final EdgeInsets padding;
  final bool watermark;
  final VoidCallback? onTap;
  final Color? tone;
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.of(context).backgroundSecondary,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color:
              (tone == null
                      ? level.nextColor(context)
                      : Color.lerp(tone!, Colors.white, .3)!)
                  .withValues(alpha: .45),
          width: .5,
        ),
        boxShadow: elevated
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .18),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: Stack(
        children: [
          if (watermark)
            Positioned(
              right: -34,
              bottom: -34,
              child: AuraRings(level: level, tone: tone, size: 96, opacity: .3),
            ),
          Padding(padding: padding, child: child),
        ],
      ),
    );
    return onTap == null
        ? card
        : InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onTap,
            child: card,
          );
  }
}

class AuraIcon extends StatelessWidget {
  const AuraIcon(
    IconData icon, {
    super.key,
    required this.level,
    this.size = 24,
  }) : _symbol = icon,
       _glyph = null;

  /// For the SF Symbols that Cupertino Icons has no glyph for, so they take the
  /// same gradient as the ones that do.
  const AuraIcon.drawn(
    SFGlyph glyph, {
    super.key,
    required this.level,
    this.size = 24,
  }) : _glyph = glyph,
       _symbol = null;

  final IconData? _symbol;
  final SFGlyph? _glyph;
  final AuraLevel level;
  final double size;

  @override
  Widget build(BuildContext context) => ShaderMask(
    shaderCallback: level.gradient(context).createShader,
    child: _symbol != null
        ? Icon(_symbol, size: size, color: Colors.white)
        : SFIcon(_glyph!, size: size, color: Colors.white),
  );
}

/// The same glyph treatment as [AuraIcon], tinted by a colour a topic or a
/// request carries rather than by a spectrum level.
class ToneIcon extends StatelessWidget {
  const ToneIcon(this.icon, {super.key, required this.tone, this.size = 18});

  final IconData icon;
  final Color tone;
  final double size;

  @override
  Widget build(BuildContext context) => ShaderMask(
    shaderCallback: toneGradient(tone).createShader,
    child: Icon(icon, size: size, color: Colors.white),
  );
}

/// The uppercase eyebrow above a step or a section: "STEP 4 OF 14".
///
/// The spectrum sits in the middle of the range, so as tiny uppercase text it
/// washes out against the page unless the tone moves away from it — down on a
/// light page, up on a dark one.
class AuraLabel extends StatelessWidget {
  const AuraLabel(this.text, {super.key, this.tone});

  final String text;
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        color: tone == null ? colors.textSecondary : colors.contrasting(tone!),
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
      ),
    );
  }
}

/// How loudly a button asks to be pressed: filled with the tone for the one
/// action that moves the screen forward, the tone on a wash of itself otherwise.
enum AuraProminence { filled, quiet }

class AuraButton extends StatelessWidget {
  const AuraButton({
    super.key,
    required this.label,
    required this.level,
    required this.onPressed,
    this.icon,
    this.prominence = AuraProminence.filled,
  });

  final String label;
  final AuraLevel level;
  final VoidCallback onPressed;
  final IconData? icon;
  final AuraProminence prominence;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      gradient: prominence == AuraProminence.filled
          ? level.gradient(context)
          : LinearGradient(
              begin: Alignment.bottomLeft,
              end: Alignment.topRight,
              colors: [
                level.color(context).withValues(alpha: .22),
                level.nextColor(context).withValues(alpha: .16),
              ],
            ),
      borderRadius: BorderRadius.circular(20),
    ),
    child: TextButton.icon(
      onPressed: onPressed,
      icon: icon == null ? const SizedBox.shrink() : Icon(icon, size: 18),
      label: Text(label),
      style: TextButton.styleFrom(
        foregroundColor: prominence == AuraProminence.filled
            ? AppColors.onAccent
            : level.color(context),
        minimumSize: const Size(80, 48),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    ),
  );
}
