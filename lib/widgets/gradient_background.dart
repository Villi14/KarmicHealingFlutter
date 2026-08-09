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
///
/// The bloom belongs at the middle, not up beside the corner. Stacked on the
/// diagonal's own strongest end it only deepened a corner that was already the
/// darkest thing on the page and was spent by half way down, so on a tall
/// phone the lower half read as bare white — the mesh instead keeps its
/// heaviest node dead centre and still has a trace to lay along the bottom
/// edge.
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
              tone.withValues(alpha: .04),
              tone.withValues(alpha: .025),
            ],
            stops: const [0, .5, 1],
          ),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            // The mesh's middle node, at .12 where it meets the diagonal, and
            // wide enough that what is left of it still reaches the foot of
            // the page rather than stopping at the fold.
            gradient: RadialGradient(
              center: const Alignment(-0.1, 0),
              radius: 1.1,
              colors: [tone.withValues(alpha: .08), Colors.transparent],
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
