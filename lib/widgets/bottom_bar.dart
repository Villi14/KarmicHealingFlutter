import 'package:flutter/material.dart';

import '../constants/design_constants.dart';
import 'scroll_blur.dart';

/// The row of actions along the bottom of a list screen — "+ Request",
/// "+ Topic".
///
/// It sits over the content rather than on a plate of its own: an opaque strip
/// reads as a white panel stuck to the bottom of a tinted page, which is not
/// what the iOS bar does. The list scrolls underneath and the glass thickens
/// towards the very edge, so the buttons stay legible without the page ending
/// early.
///
/// The screen's [Scaffold] needs `extendBody: true` for the content to reach
/// under it, and its list needs [DesignConstants.bottomBarInset] at the foot of
/// its padding so the last row can still be scrolled clear of the glass.
class KarmicBottomBar extends StatelessWidget {
  const KarmicBottomBar({
    super.key,
    required this.child,
    this.height = DesignConstants.bottomBarHeight,
  });

  final Widget child;
  final double height;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      const Positioned.fill(child: EdgeBlur(edge: VerticalEdge.bottom)),
      SafeArea(
        top: false,
        child: SizedBox(height: height, child: child),
      ),
    ],
  );
}
