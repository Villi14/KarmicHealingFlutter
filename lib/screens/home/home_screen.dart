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
          title: Text(
            AppLocalizations.of(context).karmicHealing,
            style: TextStyle(
              fontFamily: 'Source Serif 4',
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
    final padding = EdgeInsets.fromLTRB(
      DesignConstants.paddingLarge,
      widget.navigationBarInset +
          DesignConstants.screenVerticalPadding(context),
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
    final tools = _ToolsGrid(
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

/// The tools, in as many columns as the space asks for.
///
/// Two columns is the phone layout. Given a box too short for its two rows —
/// a landscape phone, a desktop window — the cards first lose height, and then,
/// where the width allows, the grid folds into a single row.
class _ToolsGrid extends StatelessWidget {
  const _ToolsGrid({required this.items, this.onTooShort});

  final List<_Tool> items;

  /// Told, during layout, that the box the grid was given cannot hold its cards
  /// at a readable size.
  final VoidCallback? onTooShort;

  /// Below this a card is too small to hold its icon and its title; the grid
  /// stops shrinking and the layout looks elsewhere for the room.
  static const _minCardHeight = 108.0;

  /// Under this width a card holds its title in the smaller of the two sizes,
  /// so that a folded row on a phone still reads.
  static const _denseCardWidth = 160.0;

  /// A single row needs at least this much width to keep its cards square-ish.
  static const _singleRowMinWidth = 340.0;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      const spacing = DesignConstants.spacingMedium;
      final ratio = DesignConstants.cardAspectRatio(context);

      double naturalHeight(int columns) =>
          (box.maxWidth - spacing * (columns - 1)) / columns / ratio;
      int rowsFor(int columns) => (items.length / columns).ceil();

      double rowsHeight(int columns, double card) =>
          rowsFor(columns) * card + spacing * (rowsFor(columns) - 1);

      var columns = 2;
      var height = naturalHeight(columns);
      // Whether the grid still ends up taller than the box it was given — on a
      // phone the hero card leaves too little for even one row of cards, and
      // the screen goes back to scrolling.
      var overflows = false;

      if (box.hasBoundedHeight) {
        double fit(int columns) =>
            (box.maxHeight - spacing * (rowsFor(columns) - 1)) /
            rowsFor(columns);

        height = math.min(height, fit(columns));
        if (height < _minCardHeight && box.maxWidth >= _singleRowMinWidth) {
          columns = items.length;
          height = math.min(naturalHeight(columns), fit(columns));
        }
        height = math.max(height, _minCardHeight);
        overflows = rowsHeight(columns, height) > box.maxHeight + 0.5;
        if (overflows) onTooShort?.call();
      }

      final cardWidth = (box.maxWidth - spacing * (columns - 1)) / columns;

      return GridView.builder(
        primary: false,
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        physics: overflows
            ? const ClampingScrollPhysics()
            : const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          crossAxisSpacing: spacing,
          mainAxisSpacing: spacing,
          mainAxisExtent: height,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final tool = items[index];
          return _ToolCard(
            title: tool.title,
            icon: tool.icon,
            level: tool.level,
            dense: cardWidth < _denseCardWidth,
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute<void>(builder: (_) => tool.screen())),
          );
        },
      );
    },
  );
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.onTap});
  final VoidCallback onTap;

  /// Under this width the badge moves above the words rather than beside them:
  /// a 28pt serif line in the column that is left over next to the badge wraps
  /// five times on a phone, and the card grows past half the screen.
  static const _stackedBelowWidth = 480.0;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final stacked = box.maxWidth < _stackedBelowWidth;
      final badge = Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [
              AppColors.of(context).health.withValues(alpha: .22),
              AppColors.of(context).clam.withValues(alpha: .16),
            ],
          ),
        ),
        child: const Center(
          child: AuraIcon.drawn(
            SFGlyph.meditate,
            level: AuraLevel.heart,
            size: 36,
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
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context).homeDailyTitle,
            style: TextStyle(
              fontFamily: 'Source Serif 4',
              color: AppColors.of(context).textPrimary,
              fontSize: stacked ? 24 : 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context).homeDailySubtitle,
            style: TextStyle(
              color: AppColors.of(context).textSecondary,
              fontSize: 15,
              height: 1.35,
            ),
          ),
          const SizedBox(
            height: DesignConstants.spacingSmall + DesignConstants.paddingSmall,
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
          DesignConstants.compact(
            context,
            DesignConstants.paddingXLarge,
            DesignConstants.paddingLarge,
          ),
        ),
        onTap: onTap,
        child: stacked
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  badge,
                  SizedBox(height: DesignConstants.spacingMedium),
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
    this.dense = false,
  });

  final String title;
  final Widget icon;
  final AuraLevel level;
  final VoidCallback onTap;

  /// A card narrow enough that its title needs the smaller size and tighter
  /// padding — three cards across a phone.
  final bool dense;

  @override
  Widget build(BuildContext context) => AuraCard(
    level: level,
    onTap: onTap,
    padding: EdgeInsets.all(
      dense ? DesignConstants.paddingMedium : DesignConstants.paddingLarge,
    ),
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
            fontSize: dense ? 14 : 17,
            color: AppColors.of(context).textPrimary,
          ),
        ),
      ],
    ),
  );
}
