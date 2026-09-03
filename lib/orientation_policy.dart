import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Which way round the app is allowed to be held.
///
/// A phone is drawn for one hand holding it upright: the aura is laid out top
/// to bottom, and the session screens read as a column. Turned on its side a
/// phone has barely 400pt of height left, which is less than the shortest of
/// those screens can be laid out in, so the window stays portrait however the
/// device is held.
///
/// A tablet is wide enough on its side to hold every screen — the content is
/// capped at a readable width and centred, and the screens
/// that measure themselves settle into their scrolling arrangement — so there
/// it turns freely, as the SwiftUI app does.
///
/// The rule is applied here rather than in the manifest or the plist because
/// only one of the two platforms can express it natively: `~ipad` says it on
/// iOS, while an Android activity has one orientation whatever the screen it
/// opens on. Reading the window also means a foldable is measured as it is
/// rather than as it was — unfolded into a tablet it is granted the rotation,
/// folded shut it loses it again.
class OrientationPolicy extends StatefulWidget {
  const OrientationPolicy({super.key, required this.child});

  final Widget child;

  /// The shortest side, in logical pixels, of a window wide enough to be worth
  /// turning. The same 600dp everything else on Android calls a tablet.
  static const tabletShortestSide = 600.0;

  @override
  State<OrientationPolicy> createState() => _OrientationPolicyState();
}

class _OrientationPolicyState extends State<OrientationPolicy> {
  /// What was last asked for, so a rebuild that changes nothing does not go
  /// back to the platform to say so.
  bool? _upright;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final size = MediaQuery.sizeOf(context);
    // The shortest side rather than the height: it is the same measure whether
    // the device is being held upright or on its side, so the answer does not
    // flip back and forth with the rotation it is deciding.
    final upright = size.shortestSide < OrientationPolicy.tabletShortestSide;
    if (upright == _upright) return;
    _upright = upright;

    // An empty list is not "no orientations" but "no preference of mine":
    // Android falls back to the sensor, and iOS to what the plist allows the
    // idiom, which on an iPad is portrait and both landscapes.
    SystemChrome.setPreferredOrientations(
      upright ? const [DeviceOrientation.portraitUp] : const [],
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
