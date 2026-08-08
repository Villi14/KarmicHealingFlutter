import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/design_constants.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/aura_alert.dart';
import '../../widgets/aura_widgets.dart';
import '../../widgets/disclosure_cell.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/scroll_blur.dart';
import '../../widgets/sf_symbols.dart';
import '../balancing_energy/energy_settings_screen.dart';
import 'privacy_policy_screen.dart';
import 'theme_settings_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return ScrollBlur(
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          flexibleSpace: const ScrollBlurBackdrop(),
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          shadowColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          title: Text(l10n.settings),
          leading: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const AuraIcon(SFSymbols.chevronLeft, level: AuraLevel.brow),
          ),
        ),
        body: GradientBackground(
          tone: AppColors.of(context).peace,
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  16,
                  DesignConstants.navigationBarInset(context) + 16,
                  16,
                  24,
                ),
                child: AuraCard(
                  level: AuraLevel.brow,
                  padding: EdgeInsets.zero,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DisclosureCell(
                        title: l10n.about,
                        onTap: () => showAuraAlert(
                          context,
                          icon: SFSymbols.infoCircle,
                          level: AuraLevel.crown,
                          title: l10n.karmicHealing,
                          message: l10n.versionLabel('1.0'),
                        ),
                      ),
                      DisclosureCell(
                        title: l10n.theme,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const ThemeSettingsScreen(),
                            fullscreenDialog: true,
                          ),
                        ),
                      ),
                      DisclosureCell(
                        title: l10n.sessionDuration,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const EnergySettingsScreen(),
                            fullscreenDialog: true,
                          ),
                        ),
                      ),
                      DisclosureCell(
                        title: l10n.changeLanguage,
                        onTap: () => showAuraAlert(
                          context,
                          level: AuraLevel.brow,
                          title: l10n.changeLanguage,
                          message: l10n.changeLanguageMessage,
                        ),
                      ),
                      DisclosureCell(
                        title: l10n.privacyPolicy,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const PrivacyPolicyScreen(),
                            fullscreenDialog: true,
                          ),
                        ),
                      ),
                      DisclosureCell(
                        title: l10n.writeToUs,
                        onTap: () => showAuraAlert(
                          context,
                          icon: SFSymbols.envelope,
                          level: AuraLevel.brow,
                          title: l10n.writeToUs,
                          message: l10n.writeToUsMessage,
                        ),
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
}
