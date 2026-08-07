import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../constants/app_colors.dart';
import '../../constants/design_constants.dart';
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
  Widget build(BuildContext context) => ScrollBlur(
    child: Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        flexibleSpace: const ScrollBlurBackdrop(),
        backgroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        title: const Text(
          'Karmic Healing',
          style: TextStyle(
            fontFamily: 'Source Serif 4',
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: GradientBackground(
        tone: AppColors.health,
        child: SafeArea(
          top: false,
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: DesignConstants.maxContentWidth,
              ),
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  DesignConstants.paddingLarge,
                  DesignConstants.navigationBarInset(context) +
                      DesignConstants.screenVerticalPadding(context),
                  DesignConstants.paddingLarge,
                  DesignConstants.screenVerticalPadding(context),
                ),
                child: Column(
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
                          DesignConstants.compact(
                            context,
                            DesignConstants.paddingSmall,
                            0,
                          ),
                    ),
                    const Text(
                      'Your tools',
                      style: TextStyle(
                        fontFamily: 'Source Serif 4',
                        fontSize: 20,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: DesignConstants.sectionSpacing(context)),
                    GridView.count(
                      crossAxisCount: 2,
                      primary: false,
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: DesignConstants.spacingMedium,
                      mainAxisSpacing: DesignConstants.spacingMedium,
                      childAspectRatio: DesignConstants.cardAspectRatio(
                        context,
                      ),
                      children: [
                        _ToolCard(
                          title: 'Requests',
                          icon: const AuraIcon(
                            SFSymbols.staroflife,
                            level: AuraLevel.sacral,
                          ),
                          level: AuraLevel.sacral,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const RequestsScreen(),
                            ),
                          ),
                        ),
                        _ToolCard(
                          title: 'Reminders',
                          icon: const AuraIcon.drawn(
                            SFGlyph.pencilAndListClipboard,
                            level: AuraLevel.solar,
                          ),
                          level: AuraLevel.solar,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const RemindersScreen(),
                            ),
                          ),
                        ),
                        _ToolCard(
                          title: 'Settings',
                          icon: const AuraIcon.drawn(
                            SFGlyph.gearshape,
                            level: AuraLevel.brow,
                          ),
                          level: AuraLevel.brow,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const SettingsScreen(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => AuraCard(
    level: AuraLevel.heart,
    padding: EdgeInsets.all(
      DesignConstants.compact(
        context,
        DesignConstants.paddingXLarge,
        DesignConstants.paddingLarge,
      ),
    ),
    onTap: onTap,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                AppColors.health.withValues(alpha: .22),
                AppColors.clam.withValues(alpha: .16),
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
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'TODAY',
                style: TextStyle(
                  color: AppColors.health,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'A moment to return to yourself',
                style: TextStyle(
                  fontFamily: 'Source Serif 4',
                  color: AppColors.textPrimary,
                  fontSize: 28,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Take a few quiet minutes to balance your energy and continue your practice.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                  height: 1.35,
                ),
              ),
              const SizedBox(
                height:
                    DesignConstants.spacingSmall + DesignConstants.paddingSmall,
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: AuraButton(
                  label: 'Start session',
                  icon: SFSymbols.arrowRight,
                  level: AuraLevel.heart,
                  onPressed: onTap,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
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
                gradient: level.gradient,
              ),
            ),
          ],
        ),
        const Spacer(),
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Source Serif 4',
            fontSize: 17,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    ),
  );
}
