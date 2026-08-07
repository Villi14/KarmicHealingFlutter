import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../constants/app_colors.dart';
import '../../widgets/aura_widgets.dart';
import '../../widgets/gradient_background.dart';
import '../balancing_energy/balancing_energy_list_screen.dart';
import '../reminders/reminders_screen.dart';
import '../requests/requests_screen.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    extendBodyBehindAppBar: true,
    appBar: AppBar(
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
            constraints: const BoxConstraints(maxWidth: 700),
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  16,
                  MediaQuery.paddingOf(context).top + kToolbarHeight + 12,
                  16,
                  28,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HeroCard(
                      onTap: () =>
                          Get.to(() => const BalancingEnergyListScreen()),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Your tools',
                      style: TextStyle(
                        fontFamily: 'Source Serif 4',
                        fontSize: 20,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GridView.count(
                      crossAxisCount: 2,
                      primary: false,
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: constraints.maxHeight <= 600
                          ? 1.45
                          : 1.28,
                      children: [
                        _ToolCard(
                          title: 'Requests',
                          icon: Icons.spa_outlined,
                          level: AuraLevel.sacral,
                          onTap: () => Get.to(() => const RequestsScreen()),
                        ),
                        _ToolCard(
                          title: 'Reminders',
                          icon: Icons.edit_note_rounded,
                          level: AuraLevel.solar,
                          onTap: () => Get.to(() => const RemindersScreen()),
                        ),
                        _ToolCard(
                          title: 'Settings',
                          icon: Icons.settings_outlined,
                          level: AuraLevel.brow,
                          onTap: () => Get.to(() => const SettingsScreen()),
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
    padding: const EdgeInsets.all(24),
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
            child: AuraIcon(
              Icons.eco_outlined,
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
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerLeft,
                child: AuraButton(
                  label: 'Start session',
                  icon: Icons.arrow_forward,
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
  final IconData icon;
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
            AuraIcon(icon, level: level),
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
