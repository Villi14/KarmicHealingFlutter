import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../constants/app_colors.dart';
import '../../constants/design_constants.dart';
import '../../widgets/aura_widgets.dart';
import '../../widgets/disclosure_cell.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/help_screen.dart';
import '../../widgets/scroll_blur.dart';
import '../../widgets/sf_symbols.dart';
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
        title: const Text('Energy Balancing'),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const AuraIcon(SFSymbols.chevronLeft, level: AuraLevel.heart),
        ),
        actions: [
          IconButton(
            onPressed: _showHelp,
            icon: const AuraIcon(
              SFSymbols.questionmarkCircle,
              level: AuraLevel.heart,
            ),
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
                  DesignConstants.navigationBarInset(context) + 16,
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
    ),
  );

  void _open(String title, List<EnergyStep> steps) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BalancingEnergyScreen(
          title: title,
          steps: steps,
          onCompleted: () async {
            if (title != 'Initial Process') return;
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool('initial_process_completed', true);
            if (mounted) setState(() => _initialProcessCompleted = true);
          },
        ),
      ),
    );
  }

  void _showHelp() => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.backgroundPrimary,
    builder: (context) => const FractionallySizedBox(
      heightFactor: 1,
      child: BalancingEnergyHelpScreen(),
    ),
  );
}

/// The shared guide, in the balancing-energy tone, with the settings tips that
/// only apply to a meditation session.
class BalancingEnergyHelpScreen extends StatelessWidget {
  const BalancingEnergyHelpScreen({super.key});

  static const _settingsTips = [
    'Meditation steps scroll automatically according to the set time interval.',
    'You can customize the time interval for transitioning to the next step in meditation.',
    'You can enable or disable vibration when transitioning to the next step.',
    'You can enable or disable sound playback when transitioning to the next step.',
    'You can adjust the volume of this sound.',
  ];

  @override
  Widget build(BuildContext context) => const HelpScreen(
    level: AuraLevel.heart,
    tone: AppColors.health,
    extras: [
      TipsCard(
        title: 'Meditation Step Settings',
        tips: _settingsTips,
        level: AuraLevel.heart,
      ),
      TipsCard(
        title: 'Important Tips',
        tips: importantTips,
        level: AuraLevel.heart,
      ),
    ],
  );
}
