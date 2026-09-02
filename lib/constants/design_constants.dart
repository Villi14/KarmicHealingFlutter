import 'package:flutter/material.dart';

/// The measurements of the iOS app's design system, mirrored from
/// `KarmicHealing/Features/Common/Sources/Design/DesignConstants.swift`.
///
/// Values the SwiftUI original derives from the device — the compact-height
/// rules and the iPad content scale — need a [BuildContext] here, so they are
/// methods rather than constants.
abstract final class DesignConstants {
  // Padding
  static const paddingTiny = 2.0;
  static const paddingSmall = 4.0;
  static const padding = 8.0;
  static const paddingMedium = 12.0;
  static const paddingLarge = 16.0;
  static const paddingXLarge = 24.0;
  static const paddingXXLarge = 32.0;
  static const bottomPaddingLarge = 50.0;

  // Spacing
  static const spacingSmall = 8.0;
  static const spacingMedium = 12.0;
  static const spacing = 16.0;
  static const spacingLarge = 20.0;
  static const spacingXLarge = 32.0;

  /// Cards and buttons in the "Aura" direction — the larger radius reads calmer.
  static const cornerRadiusLarge = 20.0;

  /// A single column of content never runs wider than this, so a card or a line
  /// of text on a tablet stays as readable as it is on a phone.
  static const maxContentWidth = 700.0;

  /// An alert is a dialog, not a page: it keeps a phone-like width everywhere.
  static const maxAlertWidth = 480.0;

  // Help view
  static const helpIconSize = 60.0;
  static const helpStepCircleSize = 40.0;
  static const helpStepCircleSizeSmall = 30.0;
  static const helpStepSpacing = 12.0;
  static const helpTipSpacing = 8.0;

  // Onboarding
  static const onboardingIconContainerHeight = helpIconSize + paddingLarge * 2;
  static const onboardingSkipButtonHeight = 60.0;

  // Frame sizes
  static const frameHeightSmall = 18.0;
  static const frameHeightMedium = 36.0;
  static const frameHeightXLarge = 48.0;
  static const frameHeightXXLarge = 56.0;
  static const frameWidthSmall = 8.0;
  static const frameWidthMedium = 12.0;
  static const frameWidthXLarge = 80.0;

  // Max frame sizes
  static const maxWidthSmall = 24.0;
  static const maxWidthMedium = 300.0;
  static const maxHeightLarge = 500.0;

  /// Lines a notes field shows before it starts growing with the text.
  static const notesLineLimit = 4;

  // Opacity
  static const opacityLow = 0.1;
  static const opacityMedium = 0.5;

  /// The ring watermark under a card's corner.
  static const opacityWatermark = 0.3;

  /// The half-pixel light edge along the top of a card.
  static const opacityEdgeLight = 0.25;
  static const opacityCardShadow = 0.18;

  // Aura
  static const watermarkSize = 96.0;
  static const watermarkOffset = 34.0;
  static const ringCoreSize = 12.0;

  /// Rest size of the breathing ring, relative to its expanded size.
  static const breathScale = 0.9;

  /// Scale a button settles at while held.
  static const pressedScale = 0.97;
  static const breathingRingSize = 78.0;

  /// One rung of the session ladder.
  static const rungSize = 9.0;
  static const rungHaloWidth = 4.0;

  // Line width
  static const lineWidthThin = 0.5;
  static const lineWidth = 2.0;

  // Shadow
  static const shadowRadiusCard = 16.0;
  static const shadowOffsetCard = 8.0;

  // Threshold
  static const thresholdMedium = 50.0;

  /// Room the transparent navigation bar takes at the top of a screen, for
  /// content that draws behind it.
  ///
  /// Call this from the screen's own build context, above its [Scaffold]. Below
  /// the Scaffold, `extendBodyBehindAppBar` has already folded the app bar into
  /// `MediaQuery.padding.top`, and adding [kToolbarHeight] there counts the bar
  /// a second time.
  static double navigationBarInset(BuildContext context) =>
      MediaQuery.paddingOf(context).top + kToolbarHeight;

  /// Air between the navigation bar and the first line of content under it.
  static const navigationBarGap = 8.0;

  /// Where a screen's content starts: below the bar, with [navigationBarGap]
  /// of air. Every screen that draws behind the bar begins here, so that the
  /// shoulder above the content is the same one on all of them.
  static double contentTopInset(BuildContext context) =>
      navigationBarInset(context) + navigationBarGap;

  /// The toolbar of actions along the bottom of a list screen, above the home
  /// indicator.
  static const bottomBarHeight = 48.0;

  /// Room that bar takes at the foot of a screen, for content that scrolls
  /// behind it.
  ///
  /// Measured rather than read off the `MediaQuery` the Scaffold hands its
  /// body, because the screens that need it build their lists from a method on
  /// the State, whose context sits above the Scaffold.
  static double bottomBarInset(BuildContext context) =>
      MediaQuery.paddingOf(context).bottom + bottomBarHeight;

  /// The 4.7" phones — an iPhone SE is 667pt tall, some 150pt short of the phone
  /// the fixed screens are laid out for. Everything still fits there, but only
  /// once the vertical air between blocks comes down.
  static bool isCompactHeight(BuildContext context) =>
      MediaQuery.sizeOf(context).height <= 700;

  /// A vertical measure that comes down on a short phone.
  static double compact(BuildContext context, double value, double compact) =>
      isCompactHeight(context) ? compact : value;

  /// Air between the blocks of a screen laid out to fit without scrolling.
  static double sectionSpacing(BuildContext context) =>
      compact(context, spacingLarge, spacingMedium);

  /// Top and bottom margin of such a screen.
  static double screenVerticalPadding(BuildContext context) =>
      compact(context, paddingXLarge, padding);

  /// Width/height of a home card. Two rows of these are the tallest block on
  /// Home, so on a short phone the card gives up some of its height rather than
  /// the grid a whole row.
  static double cardAspectRatio(BuildContext context) =>
      1 / compact(context, 0.78, 0.68);
}
