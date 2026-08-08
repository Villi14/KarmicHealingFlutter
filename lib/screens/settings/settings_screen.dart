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
import 'settings_actions.dart';
import 'theme_settings_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    this.actions = const PlatformSettingsActions(),
  });

  /// What the rows that leave the app go through.
  final SettingsActions actions;

  /// Where "Write to us" writes to — the same address the Swift app shows.
  static const contactEmail = 'karmic.healing14@gmail.com';

  /// The site of the author whose book the app follows; About names her, so
  /// that is where a reader looks for the source.
  static final authorSite = Uri.parse('https://www.dianestein.net');

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  /// Read from the bundle rather than written down here, so About cannot go on
  /// claiming a version that shipped two releases ago.
  String? _version;

  @override
  void initState() {
    super.initState();
    widget.actions.appVersion().then((version) {
      if (mounted) setState(() => _version = version);
    });
  }

  /// About tells the reader what the app is and offers them the book behind it.
  Future<void> _showAbout() {
    final l10n = AppLocalizations.of(context);
    return showAuraAlert(
      context,
      icon: SFSymbols.infoCircle,
      level: AuraLevel.crown,
      title: l10n.karmicHealing,
      message: _version == null
          ? l10n.thanksForUsingKarmicHealing
          : '${l10n.thanksForUsingKarmicHealing}\n\n${l10n.versionLabel(_version!)}',
      buttons: [
        AuraAlertButton(
          l10n.authorSite,
          onPressed: () => widget.actions.openUrl(SettingsScreen.authorSite),
        ),
        AuraAlertButton(l10n.done, prominence: AuraProminence.quiet),
      ],
    );
  }

  /// The app speaks whatever language the device does, so changing it means
  /// leaving for the system settings.
  Future<void> _showChangeLanguage() {
    final l10n = AppLocalizations.of(context);
    return showAuraAlert(
      context,
      level: AuraLevel.brow,
      title: l10n.changeLanguage,
      message: l10n.changeLanguageMessage,
      buttons: [
        AuraAlertButton(
          l10n.openSystemSettings,
          onPressed: widget.actions.openSystemSettings,
        ),
        AuraAlertButton(l10n.done, prominence: AuraProminence.quiet),
      ],
    );
  }

  /// Hands the address to the mail app; a device that has none is shown the
  /// address itself, with a way to carry it out of the app by hand.
  Future<void> _writeToUs() async {
    final l10n = AppLocalizations.of(context);
    final opened = await widget.actions.openUrl(
      Uri(
        scheme: 'mailto',
        path: SettingsScreen.contactEmail,
        queryParameters: {'subject': l10n.karmicHealing},
      ),
    );
    if (opened || !mounted) return;

    await showAuraAlert(
      context,
      icon: SFSymbols.envelope,
      level: AuraLevel.brow,
      title: l10n.writeToUs,
      message: '${l10n.writeToUsMessage}\n\n${SettingsScreen.contactEmail}',
      buttons: [
        AuraAlertButton(
          l10n.copyToClipboard,
          onPressed: () =>
              widget.actions.copyToClipboard(SettingsScreen.contactEmail),
        ),
        AuraAlertButton(l10n.done, prominence: AuraProminence.quiet),
      ],
    );
  }

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
                      DisclosureCell(title: l10n.about, onTap: _showAbout),
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
                        onTap: _showChangeLanguage,
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
                      DisclosureCell(title: l10n.writeToUs, onTap: _writeToUs),
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
