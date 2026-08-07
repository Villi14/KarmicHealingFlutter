import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class GradientBackground extends StatelessWidget {
  const GradientBackground({
    super.key,
    required this.child,
    this.tone = AppColors.clam,
  });

  final Widget child;
  final Color tone;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: AppColors.backgroundPrimary,
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
