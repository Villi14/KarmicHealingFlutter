import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/design_constants.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/aura_widgets.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/scroll_blur.dart';
import '../../widgets/sf_symbols.dart';
import '../balancing_energy/balancing_energy_list_screen.dart';
import '../reminders/reminders_screen.dart';
import '../requests/requests_screen.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Read above the [Scaffold], where the app bar has not yet been folded into
    // the padding — see [DesignConstants.navigationBarInset].
    final navigationBarInset = DesignConstants.navigationBarInset(context);

    return ScrollBlur(
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          flexibleSpace: const ScrollBlurBackdrop(),
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          // Larger than the 17 the bar hands every other title, because Source
          // Serif 4 draws smaller inside its em than Inter does — a cap of
          // .670em against .728, an x-height of .475 against .546, measured off
          // the two files. At a matched 17 this title read a size down from the
          // rest; 19 puts its lowercase and its capitals back alongside theirs.
          title: Text(
            AppLocalizations.of(context).karmicHealing,
            style: TextStyle(
              fontFamily: 'Source Serif 4',
              fontSize: 19,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        body: GradientBackground(
          tone: AppColors.of(context).health,
          child: SafeArea(
            top: false,
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: DesignConstants.maxContentWidth,
                ),
                child: LayoutBuilder(
                  builder: (context, viewport) => _HomeBody(
                    viewport: viewport,
                    navigationBarInset: navigationBarInset,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The body of the screen, in whichever of its two shapes the window allows.
///
/// The screen is laid out to be taken in at a glance, so where the window has
/// the height for it the content fills the window rather than scrolling: the
/// grid of tools takes what the hero card leaves and sizes its cards to it,
/// folding two rows into one where the width allows. A window that cannot hold
/// the whole screen even at the smallest readable card — a phone in portrait,
/// where the hero card alone takes half the height — says so during layout,
/// and the body settles back into the scrolling arrangement.
class _HomeBody extends StatefulWidget {
  const _HomeBody({required this.viewport, required this.navigationBarInset});

  /// The box the body is laid out in, from the [LayoutBuilder] above it.
  final BoxConstraints viewport;

  /// Room the transparent navigation bar takes above the content.
  final double navigationBarInset;

  /// Under this much room, fitting the screen into the window is hopeless
  /// enough not to be worth the measuring frame.
  static const _minFittedHeight = 520.0;

  @override
  State<_HomeBody> createState() => _HomeBodyState();
}

class _HomeBodyState extends State<_HomeBody> {
  /// The window the tools reported they could not fit in. Held as the
  /// constraints rather than a flag so that a resize is measured afresh.
  BoxConstraints? _tooShort;

  @override
  Widget build(BuildContext context) {
    // The same shoulder under the bar every other screen has — see
    // [DesignConstants.contentTopInset], spelled out here because the inset
    // above the Scaffold is the one to add the gap to.
    final padding = EdgeInsets.fromLTRB(
      DesignConstants.paddingLarge,
      widget.navigationBarInset + DesignConstants.navigationBarGap,
      DesignConstants.paddingLarge,
      DesignConstants.screenVerticalPadding(context),
    );
    final room = widget.viewport.hasBoundedHeight
        ? widget.viewport.maxHeight - padding.vertical
        : 0.0;
    final fits =
        room >= _HomeBody._minFittedHeight && _tooShort != widget.viewport;

    return SingleChildScrollView(
      physics: fits ? const NeverScrollableScrollPhysics() : null,
      padding: padding,
      child: SizedBox(
        height: fits ? room : null,
        child: _HomeContent(
          fitted: fits,
          onTooShort: fits ? _reportTooShort : null,
        ),
      ),
    );
  }

  /// Called from the grid's layout, so the rebuild waits for the frame it is
  /// part of to finish.
  void _reportTooShort() {
    final viewport = widget.viewport;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _tooShort != viewport) {
        setState(() => _tooShort = viewport);
      }
    });
  }
}

/// The hero card, the heading and the grid of tools.
///
/// When [fitted], the grid takes what the first two leave and sizes its cards
/// to it, calling [onTooShort] if what is left is too little; otherwise the
/// cards keep their natural height and the page scrolls.
class _HomeContent extends StatelessWidget {
  const _HomeContent({required this.fitted, this.onTooShort});

  final bool fitted;
  final VoidCallback? onTooShort;

  @override
  Widget build(BuildContext context) {
    final tools = _ToolsLayout(
      onTooShort: onTooShort,
      items: [
        _Tool(
          title: AppLocalizations.of(context).requests,
          icon: const AuraIcon(SFSymbols.staroflife, level: AuraLevel.sacral),
          level: AuraLevel.sacral,
          screen: () => const RequestsScreen(),
        ),
        _Tool(
          title: AppLocalizations.of(context).reminders,
          icon: const AuraIcon.drawn(
            SFGlyph.pencilAndListClipboard,
            level: AuraLevel.solar,
          ),
          level: AuraLevel.solar,
          screen: () => const RemindersScreen(),
        ),
        _Tool(
          title: AppLocalizations.of(context).settings,
          icon: const AuraIcon.drawn(SFGlyph.gearshape, level: AuraLevel.brow),
          level: AuraLevel.brow,
          screen: () => const SettingsScreen(),
        ),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _HeroCard(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const BalancingEnergyListScreen(),
            ),
          ),
        ),
        SizedBox(
          height:
              DesignConstants.sectionSpacing(context) +
              // The heading carries a little extra air above it,
              // which a short phone gives back.
              DesignConstants.compact(context, DesignConstants.paddingSmall, 0),
        ),
        Text(
          AppLocalizations.of(context).homeTools,
          style: TextStyle(
            fontFamily: 'Source Serif 4',
            fontSize: 20,
            color: AppColors.of(context).textPrimary,
          ),
        ),
        SizedBox(height: DesignConstants.sectionSpacing(context)),
        if (fitted) Expanded(child: tools) else tools,
      ],
    );
  }
}

class _Tool {
  const _Tool({
    required this.title,
    required this.icon,
    required this.level,
    required this.screen,
  });

  final String title;
  final Widget icon;
  final AuraLevel level;
  final Widget Function() screen;
}

/// The pair of tools, and under them the one that closes the screen.
///
/// All three cards are cut to one size — half the width, and a height short
/// enough to leave the window some air. The two keep the top of the box,
/// straight under the heading, and the third follows straight under the first,
/// one gap below: the three read as one block of tools rather than as two
/// rows with the window's slack driven between them. What the window has to
/// spare is left under the block. A box too short even for that says so, and
/// the screen goes back to scrolling.
class _ToolsLayout extends StatelessWidget {
  const _ToolsLayout({required this.items, this.onTooShort});

  final List<_Tool> items;

  /// Told, during layout, that the box the tools were given cannot hold them
  /// at a readable size.
  final VoidCallback? onTooShort;

  /// Below this a card is too small to hold its icon and its title over two
  /// lines; the cards stop shrinking and the layout looks elsewhere for the
  /// room.
  static const _minCardHeight = 96.0;

  /// A card is a tile, not a panel: given a wide window it stops growing here
  /// rather than following its width up.
  static const _maxCardHeight = 124.0;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      const spacing = DesignConstants.spacingMedium;
      final ratio = DesignConstants.cardAspectRatio(context);
      final pair = items.take(2).toList();
      final foot = items.length > 2 ? items[2] : null;
      final rows = foot == null ? 1 : 2;

      var height = math.min(
        (box.maxWidth - spacing) / 2 / ratio,
        _maxCardHeight,
      );
      // Whether the tools still end up taller than the box they were given, in
      // which case the screen goes back to scrolling.
      var overflows = false;

      if (box.hasBoundedHeight) {
        height = math.max(
          math.min(height, (box.maxHeight - spacing * (rows - 1)) / rows),
          _minCardHeight,
        );
        overflows = height * rows + spacing * (rows - 1) > box.maxHeight + 0.5;
        if (overflows) onTooShort?.call();
      }

      Widget row(List<_Tool?> tools) => SizedBox(
        height: height,
        child: Row(
          children: [
            for (final (index, tool) in tools.indexed) ...[
              if (index > 0) const SizedBox(width: spacing),
              // An empty half keeps the card beside it to the width of the
              // ones above.
              Expanded(
                child: tool == null
                    ? const SizedBox.shrink()
                    : _card(context, tool),
              ),
            ],
          ],
        ),
      );

      final column = Column(
        // The block keeps the top of the box however much of it is spare, so
        // the tools stay together under the heading rather than the last one
        // being carried off to the foot of the window.
        mainAxisSize: MainAxisSize.min,
        children: [
          row(pair),
          if (foot != null) ...[
            const SizedBox(height: spacing),
            row([foot, null]),
          ],
        ],
      );

      // A box this content has outgrown scrolls for the one frame before the
      // screen settles into its scrolling arrangement, rather than overflowing.
      return overflows
          ? SingleChildScrollView(
              primary: false,
              physics: const ClampingScrollPhysics(),
              child: column,
            )
          : column;
    },
  );

  Widget _card(BuildContext context, _Tool tool) => _ToolCard(
    title: tool.title,
    icon: tool.icon,
    level: tool.level,
    onTap: () => Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => tool.screen())),
  );
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.onTap});
  final VoidCallback onTap;

  /// Under this much window the card comes down a size. The tools below it
  /// need some 350 points between the heading and the foot of the screen, and
  /// on a phone — 1080 pixels over three, or two and five eighths, to the
  /// point — that is all the card can be allowed to leave them.
  static const _tightBelowHeight = 800.0;

  /// Under this width the badge moves above the words rather than beside them:
  /// a 28pt serif line in the column that is left over next to the badge wraps
  /// five times on a phone, and the card grows past half the screen.
  static const _stackedBelowWidth = 480.0;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final stacked = box.maxWidth < _stackedBelowWidth;
      // On a short window the card gives up a size and some of its air: it is
      // the tallest block on the screen, and the room the tools need at the
      // foot has to come from somewhere.
      final tight = MediaQuery.sizeOf(context).height < _tightBelowHeight;
      final badgeSize = tight ? 44.0 : 56.0;
      final badge = Container(
        width: badgeSize,
        height: badgeSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [
              AppColors.of(context).health.withValues(alpha: .22),
              AppColors.of(context).clam.withValues(alpha: .16),
            ],
          ),
        ),
        child: Center(
          child: AuraIcon.drawn(
            SFGlyph.meditate,
            level: AuraLevel.heart,
            size: tight ? 28 : 36,
          ),
        ),
      );
      final words = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context).homeDailyEyebrow.toUpperCase(),
            style: TextStyle(
              color: AppColors.of(context).health,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          SizedBox(height: tight ? 4 : 8),
          Text(
            AppLocalizations.of(context).homeDailyTitle,
            style: TextStyle(
              fontFamily: 'Source Serif 4',
              color: AppColors.of(context).textPrimary,
              fontSize: tight ? 21 : (stacked ? 24 : 28),
              height: 1.2,
            ),
          ),
          SizedBox(height: tight ? 4 : 8),
          Text(
            AppLocalizations.of(context).homeDailySubtitle,
            style: TextStyle(
              color: AppColors.of(context).textSecondary,
              fontSize: tight ? 13 : 15,
              height: 1.3,
            ),
            maxLines: tight ? 2 : null,
            overflow: tight ? TextOverflow.ellipsis : null,
          ),
          SizedBox(
            height: tight
                ? DesignConstants.spacingSmall
                : DesignConstants.spacingSmall + DesignConstants.paddingSmall,
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: AuraButton(
              label: AppLocalizations.of(context).startSession,
              icon: SFSymbols.arrowRight,
              level: AuraLevel.heart,
              onPressed: onTap,
            ),
          ),
        ],
      );

      return AuraCard(
        level: AuraLevel.heart,
        padding: EdgeInsets.all(
          tight ? DesignConstants.paddingLarge : DesignConstants.paddingXLarge,
        ),
        onTap: onTap,
        child: stacked
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  badge,
                  SizedBox(
                    height: tight
                        ? DesignConstants.spacingSmall
                        : DesignConstants.spacingMedium,
                  ),
                  words,
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  badge,
                  const SizedBox(width: 20),
                  Expanded(child: words),
                ],
              ),
      );
    },
  );
}

class _ToolCard extends StatelessWidget {
  const _ToolCard({
    required this.title,
    required this.icon,
    required this.level,
    required this.onTap,
  });

  final String title;
  final Widget icon;
  final AuraLevel level;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => AuraCard(
    level: level,
    onTap: onTap,
    padding: const EdgeInsets.all(DesignConstants.paddingMedium),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            icon,
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: level.gradient(context),
              ),
            ),
          ],
        ),
        const Spacer(),
        Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: 'Source Serif 4',
            fontSize: 16,
            color: AppColors.of(context).textPrimary,
          ),
        ),
      ],
    ),
  );
}
