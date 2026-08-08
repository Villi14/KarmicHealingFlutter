import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/design_constants.dart';
import '../../data/energy_settings.dart';
import '../../l10n/app_localizations.dart';
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
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settings = EnergySettingsScope.of(context);

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
          title: Text(l10n.energyBalancing),
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
          tone: AppColors.of(context).health,
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
                        if (!settings.initialProcessCompleted)
                          DisclosureCell(
                            title: SessionKind.initialProcess.title(l10n),
                            onTap: () => _open(SessionKind.initialProcess),
                          ),
                        DisclosureCell(
                          title: SessionKind.essentialSelf.title(l10n),
                          onTap: () => _open(SessionKind.essentialSelf),
                        ),
                        DisclosureCell(
                          title: SessionKind.divineSelf.title(l10n),
                          onTap: () => _open(SessionKind.divineSelf),
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
  }

  void _open(SessionKind kind) {
    final l10n = AppLocalizations.of(context);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BalancingEnergyScreen(
          kind: kind,
          title: kind.title(l10n),
          steps: kind.steps(l10n),
          onCompleted: () {
            if (kind == SessionKind.initialProcess) {
              EnergySettingsScope.of(context).completeInitialProcess();
            }
          },
        ),
      ),
    );
  }

  void _showHelp() => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.of(context).backgroundPrimary,
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

  static List<String> _settingsTips(AppLocalizations l10n) => [
    l10n.meditationAutoScroll,
    l10n.meditationStepTiming,
    l10n.meditationVibrationSetting,
    l10n.meditationSoundSetting,
    l10n.meditationVolumeSetting,
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return HelpScreen(
      level: AuraLevel.heart,
      tone: AppColors.of(context).health,
      extras: [
        TipsCard(
          title: l10n.meditationSettingsTitle,
          tips: _settingsTips(l10n),
          level: AuraLevel.heart,
        ),
        TipsCard(
          title: l10n.helpTipsTitle,
          tips: importantTips(l10n),
          level: AuraLevel.heart,
        ),
      ],
    );
  }
}
