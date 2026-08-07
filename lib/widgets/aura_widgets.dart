import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

enum AuraLevel { root, sacral, solar, heart, throat, brow, crown }

extension AuraLevelStyle on AuraLevel {
  Color get color => switch (this) {
    AuraLevel.root => AppColors.energy,
    AuraLevel.sacral => AppColors.friendly,
    AuraLevel.solar => AppColors.clarity,
    AuraLevel.heart => AppColors.health,
    AuraLevel.throat => AppColors.clam,
    AuraLevel.brow => AppColors.peace,
    AuraLevel.crown => AppColors.wisdom,
  };

  Color get nextColor {
    final levels = AuraLevel.values;
    return levels[index == levels.length - 1 ? index - 1 : index + 1].color;
  }

  LinearGradient get gradient => LinearGradient(
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
    colors: [color, nextColor],
  );
}

class AuraRings extends StatelessWidget {
  const AuraRings({
    super.key,
    required this.level,
    this.size = 78,
    this.count = 3,
    this.opacity = .5,
    this.core = false,
  });

  final AuraLevel level;
  final double size;
  final int count;
  final double opacity;
  final bool core;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(
      painter: _RingsPainter(
        colors: [level.color, level.nextColor],
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

class AuraCard extends StatelessWidget {
  const AuraCard({
    super.key,
    required this.level,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.watermark = true,
    this.onTap,
  });

  final AuraLevel level;
  final Widget child;
  final EdgeInsets padding;
  final bool watermark;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: level.nextColor.withValues(alpha: .45),
          width: .5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .18),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          if (watermark)
            Positioned(
              right: -34,
              bottom: -34,
              child: AuraRings(level: level, size: 96, opacity: .3),
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
  const AuraIcon(this.icon, {super.key, required this.level, this.size = 24});

  final IconData icon;
  final AuraLevel level;
  final double size;

  @override
  Widget build(BuildContext context) => ShaderMask(
    shaderCallback: level.gradient.createShader,
    child: Icon(icon, size: size, color: Colors.white),
  );
}

class AuraButton extends StatelessWidget {
  const AuraButton({
    super.key,
    required this.label,
    required this.level,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final AuraLevel level;
  final VoidCallback onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      gradient: level.gradient,
      borderRadius: BorderRadius.circular(20),
    ),
    child: TextButton.icon(
      onPressed: onPressed,
      icon: icon == null ? const SizedBox.shrink() : Icon(icon, size: 18),
      label: Text(label),
      style: TextButton.styleFrom(
        foregroundColor: AppColors.onAccent,
        minimumSize: const Size(80, 48),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    ),
  );
}
