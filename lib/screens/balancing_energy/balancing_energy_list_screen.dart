import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../constants/app_colors.dart';
import '../../widgets/aura_widgets.dart';
import '../../widgets/disclosure_cell.dart';
import '../../widgets/gradient_background.dart';
import 'balancing_energy_screen.dart';

class BalancingEnergyListScreen extends StatefulWidget {
  const BalancingEnergyListScreen({super.key});

  @override
  State<BalancingEnergyListScreen> createState() => _State();
}

class _State extends State<BalancingEnergyListScreen> {
  bool _initialProcessCompleted = false;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((prefs) {
      if (mounted) {
        setState(
          () => _initialProcessCompleted =
              prefs.getBool('initial_process_completed') ?? false,
        );
      }
    });
  }

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
      title: const Text('Energy Balancing'),
      leading: IconButton(
        onPressed: Get.back,
        icon: const AuraIcon(Icons.chevron_left, level: AuraLevel.heart),
      ),
      actions: [
        IconButton(
          onPressed: _showHelp,
          icon: const AuraIcon(Icons.help_outline, level: AuraLevel.heart),
        ),
      ],
    ),
    body: GradientBackground(
      tone: AppColors.health,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                MediaQuery.paddingOf(context).top + kToolbarHeight + 16,
                16,
                16,
              ),
              child: AuraCard(
                level: AuraLevel.heart,
                padding: EdgeInsets.zero,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!_initialProcessCompleted)
                      DisclosureCell(
                        title: 'Initial Process',
                        onTap: () =>
                            _open('Initial Process', EnergySteps.part1),
                      ),
                    DisclosureCell(
                      title: 'Essential Self',
                      onTap: () => _open('Essential Self', EnergySteps.part2),
                    ),
                    DisclosureCell(
                      title: 'Divine Self',
                      onTap: () => _open('Divine Self', EnergySteps.part3),
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

  void _open(String title, List<EnergyStep> steps) {
    Get.to(
      () => BalancingEnergyScreen(
        title: title,
        steps: steps,
        onCompleted: () async {
          if (title != 'Initial Process') return;
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('initial_process_completed', true);
          if (mounted) setState(() => _initialProcessCompleted = true);
        },
      ),
    );
  }

  void _showHelp() => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.backgroundPrimary,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) => const _HelpSheet(),
  );
}

class _HelpSheet extends StatelessWidget {
  const _HelpSheet();

  @override
  Widget build(BuildContext context) => SafeArea(
    child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
      child: Column(
        children: [
          const AuraIcon(Icons.help_outline, level: AuraLevel.heart, size: 60),
          const SizedBox(height: 12),
          const Text(
            'Energy Balancing',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 28,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Move through each practice slowly. Every step is a quiet invitation to notice and rebalance your energy.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, height: 1.45),
          ),
          const SizedBox(height: 28),
          for (final item in const [
            ('1', 'Choose a practice', Icons.favorite_outline),
            ('2', 'Find a quiet place', Icons.nightlight_outlined),
            ('3', 'Follow each step', Icons.wb_sunny_outlined),
            ('4', 'Pause whenever needed', Icons.pan_tool_outlined),
            ('5', 'Complete the session', Icons.check_circle_outline),
          ]) ...[
            AuraCard(
              level: AuraLevel.heart,
              watermark: false,
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.health, width: 2),
                    ),
                    child: Text(item.$1),
                  ),
                  const SizedBox(width: 12),
                  AuraIcon(item.$3, level: AuraLevel.heart),
                  const SizedBox(width: 10),
                  Expanded(child: Text(item.$2)),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    ),
  );
}
