import 'dart:ui';

import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// Publishes how far the screen's scroll view has travelled, so a navigation
/// bar painted over the content can react to content passing beneath it.
///
/// Wraps the [Scaffold] rather than the scroll view because scroll
/// notifications travel up the tree, and the app bar is the scroll view's
/// sibling — the nearest place both can see is above the two of them.
class ScrollBlur extends StatefulWidget {
  const ScrollBlur({super.key, required this.child});

  final Widget child;

  @override
  State<ScrollBlur> createState() => _ScrollBlurState();
}

class _ScrollBlurState extends State<ScrollBlur> {
  final _offset = ValueNotifier<double>(0);

  @override
  void dispose() {
    _offset.dispose();
    super.dispose();
  }

  @override
  Widget build(
    BuildContext context,
  ) => NotificationListener<ScrollNotification>(
    onNotification: (notification) {
      // depth 0 keeps a nested horizontal or inner list from driving the bar.
      if (notification.depth == 0 &&
          notification.metrics.axis == Axis.vertical) {
        _offset.value = notification.metrics.pixels;
      }
      return false;
    },
    child: _ScrollBlurScope(offset: _offset, child: widget.child),
  );
}

class _ScrollBlurScope extends InheritedNotifier<ValueNotifier<double>> {
  const _ScrollBlurScope({
    required ValueNotifier<double> offset,
    required super.child,
  }) : super(notifier: offset);

  static double of(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<_ScrollBlurScope>()
          ?.notifier
          ?.value ??
      0;
}

/// The frosted material behind a navigation bar: clear while the content sits
/// at the top, blurring in as the content scrolls up under it.
///
/// Goes in [AppBar.flexibleSpace], under a [ScrollBlur]. The screen's
/// [Scaffold] needs `extendBodyBehindAppBar: true` for there to be anything
/// behind the bar to blur.
class ScrollBlurBackdrop extends StatelessWidget {
  const ScrollBlurBackdrop({super.key, this.sigma = 12, this.distance = 28});

  /// Blur of one layer at full strength; the layers stack, so the band right
  /// under the status bar ends up several times this.
  final double sigma;

  /// How far the content travels before the bar reaches full strength.
  final double distance;

  @override
  Widget build(BuildContext context) {
    final t = (_ScrollBlurScope.of(context) / distance).clamp(0.0, 1.0);
    // A zero-sigma BackdropFilter still forces a saveLayer, so at rest draw nothing.
    if (t == 0) return const SizedBox.expand();
    return EdgeBlur(edge: VerticalEdge.top, sigma: sigma * t, opacity: t);
  }
}

/// Which end of a strip the frosting gathers at.
enum VerticalEdge { top, bottom }

/// A strip of glass that thickens towards one edge: clear where it meets the
/// content, fully frosted where it meets the screen's edge.
///
/// A single blur across the whole strip draws a visible seam where it stops —
/// the iOS bars this mirrors ramp the blur instead, so the material has no edge
/// of its own. The ramp here is a stack of blurs, each clipped to a shorter
/// band than the one beneath it: a backdrop filter takes in everything already
/// painted behind it, so the layers compound, and the strength climbs a step at
/// every band boundary until the screen's edge.
///
/// The obvious way to write that — one blur behind a gradient [ShaderMask] —
/// renders nothing on Impeller, where a backdrop filter inside a save layer has
/// no backdrop to read. Hence the clipped bands, whose steps the tint gradient
/// over them softens.
class EdgeBlur extends StatelessWidget {
  const EdgeBlur({
    super.key,
    required this.edge,
    this.sigma = 12,
    this.layers = 4,
    this.opacity = 1,
  });

  final VerticalEdge edge;

  /// Blur applied by one layer.
  final double sigma;

  /// How many times the ramp is stepped. More is smoother and costs a pass each.
  final int layers;

  /// Scales the whole effect, for a bar that fades in as content reaches it.
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    // Every gradient here runs from the screen's edge inwards, so a stop of 0
    // is the frosted end and a stop of 1 the clear one.
    final atEdge = edge == VerticalEdge.top
        ? Alignment.topCenter
        : Alignment.bottomCenter;
    final inwards = edge == VerticalEdge.top
        ? Alignment.bottomCenter
        : Alignment.topCenter;

    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Layer 0 covers the whole strip, each one after it stops a step
          // shorter of the content. The shorter the band the stronger its
          // blur, so the step down at the strip's inner edge — the one that
          // would read as a seam across the content — is the faintest of them.
          for (var i = 0; i < layers; i++)
            Align(
              alignment: atEdge,
              child: FractionallySizedBox(
                heightFactor: (layers - i) / layers,
                child: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(
                      sigmaX: sigma * (i + 1) / layers,
                      sigmaY: sigma * (i + 1) / layers,
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
            ),
          // The wash that keeps a title legible over whatever passes beneath,
          // laid on the same ramp so it too has no edge.
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: atEdge,
                end: inwards,
                colors: [
                  colors.backgroundPrimary.withValues(alpha: .55 * opacity),
                  colors.backgroundPrimary.withValues(alpha: 0),
                ],
              ),
            ),
            child: const SizedBox.expand(),
          ),
        ],
      ),
    );
  }
}
