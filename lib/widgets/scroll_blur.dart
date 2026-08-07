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
  const ScrollBlurBackdrop({
    super.key,
    this.sigma = 18,
    this.distance = 28,
    this.tint = AppColors.backgroundPrimary,
  });

  /// Blur at full strength.
  final double sigma;

  /// How far the content travels before the bar reaches full strength.
  final double distance;

  final Color tint;

  @override
  Widget build(BuildContext context) {
    final t = (_ScrollBlurScope.of(context) / distance).clamp(0.0, 1.0);
    // A zero-sigma BackdropFilter still forces a saveLayer, so at rest draw nothing.
    if (t == 0) return const SizedBox.expand();
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: sigma * t, sigmaY: sigma * t),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: tint.withValues(alpha: .55 * t),
            border: Border(
              bottom: BorderSide(
                color: AppColors.textSecondary.withValues(alpha: .16 * t),
                width: .5,
              ),
            ),
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}
