import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/design_constants.dart';
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
  Widget build(BuildContext context) => ScrollBlur(
    child: Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        flexibleSpace: const ScrollBlurBackdrop(),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text('Settings'),
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
                      title: 'About',
                      onTap: () => showAuraAlert(
                        context,
                        icon: SFSymbols.infoCircle,
                        level: AuraLevel.crown,
                        title: 'Karmic Healing',
                        message: 'Version 1.0',
                      ),
                    ),
                    DisclosureCell(
                      title: 'Theme',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const ThemeSettingsScreen(),
                          fullscreenDialog: true,
                        ),
                      ),
                    ),
                    DisclosureCell(
                      title: 'Session Duration',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const EnergySettingsScreen(),
                          fullscreenDialog: true,
                        ),
                      ),
                    ),
                    DisclosureCell(
                      title: 'Change Language',
                      onTap: () => showAuraAlert(
                        context,
                        level: AuraLevel.brow,
                        title: 'Change Language',
                        message:
                            'The app follows the language of your device. Change it in system settings.',
                      ),
                    ),
                    DisclosureCell(
                      title: 'Privacy Policy',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const PrivacyPolicyScreen(),
                          fullscreenDialog: true,
                        ),
                      ),
                    ),
                    DisclosureCell(
                      title: 'Write to us',
                      onTap: () => showAuraAlert(
                        context,
                        icon: SFSymbols.envelope,
                        level: AuraLevel.brow,
                        title: 'Write to us',
                        message: 'We would love to hear from you.',
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
