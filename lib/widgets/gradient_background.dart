import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class GradientBackground extends StatelessWidget {
  const GradientBackground({super.key, required this.child, this.tone});

  final Widget child;

  /// The wash over the page. Defaults to the throat colour of whichever
  /// appearance the screen is painted in.
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final tone = this.tone ?? colors.clam;
    return ColoredBox(
      color: colors.backgroundPrimary,
      child: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(-0.15, -0.2),
            radius: 1.25,
            colors: [
              tone.withValues(alpha: 0.12),
              tone.withValues(alpha: 0.05),
              Colors.transparent,
            ],
            stops: const [0, 0.46, 1],
          ),
        ),
        child: child,
      ),
    );
  }
}
