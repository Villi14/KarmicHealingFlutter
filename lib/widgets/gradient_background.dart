import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// The aura the page sits on.
///
/// The Swift app paints this as a 3x3 mesh gradient, which carries the tone
/// right across the page: a tenth of it in the top-left corner, an eighth at
/// the middle, and a trace still left along the bottom. A single radial cannot
/// do that — its outskirts run to nothing, and on a screen whose cards cover
/// the middle that leaves only the dead margin showing, which is what made the
/// wash look absent on the lists. So the field is laid down in two passes with
/// the mesh's own weights: a diagonal that reaches everywhere, and the bloom
/// the mesh carries around its middle node.
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
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              tone.withValues(alpha: .10),
              tone.withValues(alpha: .045),
              tone.withValues(alpha: .02),
            ],
            stops: const [0, .5, 1],
          ),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(-0.15, -0.2),
              radius: 1,
              colors: [tone.withValues(alpha: .06), Colors.transparent],
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
