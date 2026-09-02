import 'dart:async';

import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/design_constants.dart';
import '../../data/app_lock.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/translation.dart';
import '../../widgets/aura_alert.dart';
import '../../widgets/aura_widgets.dart';
import '../../widgets/disclosure_cell.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/scroll_blur.dart';
import '../../widgets/sf_symbols.dart';
import '../balancing_energy/energy_settings_screen.dart';
import 'language_settings_screen.dart';
import 'passcode_setup_screen.dart';
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

  /// Whether a code has been chosen, which decides whether turning the lock on
  /// goes through choosing one first.
  bool _hasPasscode = false;

  @override
  void initState() {
    super.initState();
    widget.actions.appVersion().then((version) {
      if (mounted) setState(() => _version = version);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    AppLockScope.of(context).passcode.isSet().then((isSet) {
      if (mounted) setState(() => _hasPasscode = isSet);
    });
  }

  /// Turning the lock on needs a code to fall back on when a face or a finger
  /// cannot answer, so the first switch of it goes through choosing one — and
  /// leaves the switch off if that is abandoned.
  Future<void> _setLockEnabled(bool isOn) async {
    final lock = AppLockScope.of(context);
    if (!isOn || _hasPasscode) {
      await lock.setEnabled(isOn);
      return;
    }
    await _chooseCode(thenEnable: true);
  }

  Future<void> _chooseCode({bool thenEnable = false}) async {
    final lock = AppLockScope.of(context);
    final navigator = Navigator.of(context);
    await navigator.push(
      MaterialPageRoute<void>(
        builder: (_) => PasscodeSetupScreen(
          passcode: lock.passcode,
          onFinished: () {
            if (mounted) setState(() => _hasPasscode = true);
            if (thenEnable) unawaited(lock.setEnabled(true));
            navigator.pop();
          },
          onCancelled: navigator.pop,
        ),
        fullscreenDialog: true,
      ),
    );
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

  /// Shown only where the words on screen came from a machine. It sits under
  /// the language row because that is where somebody who has just noticed a
  /// strange one will look, and it opens the same letter the "write to us" row
  /// does — the shortest path from noticing to telling.
  Widget _machineTranslationRow(AppLocalizations l10n) {
    final colors = AppColors.of(context);

    return InkWell(
      onTap: () => unawaited(_writeToUs()),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const AuraRings(
                level: AuraLevel.throat,
                size: 18,
                count: 2,
                opacity: 1,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.machineTranslationTitle,
                      style: const TextStyle(
                        fontFamily: 'Source Serif 4',
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: DesignConstants.paddingTiny),
                    Text(
                      l10n.machineTranslationNote,
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const AuraIcon(
                SFSymbols.envelope,
                level: AuraLevel.throat,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// The lock is a switch rather than a page of its own, so it sits in a row
  /// shaped like the disclosure cells around it rather than beside them.
  Widget _appLockRow(AppLocalizations l10n) {
    final colors = AppColors.of(context);
    final isEnabled = AppLockScope.of(context).isEnabled;

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 56),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            const AuraRings(
              level: AuraLevel.brow,
              size: 18,
              count: 2,
              opacity: 1,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.appLock,
                    style: const TextStyle(
                      fontFamily: 'Source Serif 4',
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: DesignConstants.paddingTiny),
                  Text(
                    l10n.appLockDescription,
                    style: TextStyle(color: colors.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            AuraSwitch(
              value: isEnabled,
              level: AuraLevel.brow,
              label: l10n.appLock,
              onChanged: (isOn) => unawaited(_setLockEnabled(isOn)),
            ),
          ],
        ),
      ),
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
                  DesignConstants.contentTopInset(context),
                  16,
                  24,
                ),
                child: DisclosureGroup(
                  level: AuraLevel.brow,
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
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const LanguageSettingsScreen(),
                          fullscreenDialog: true,
                        ),
                      ),
                    ),
                    if (Translation.isMachineTranslated(
                      Localizations.localeOf(context),
                    ))
                      _machineTranslationRow(l10n),
                    _appLockRow(l10n),
                    if (AppLockScope.of(context).isEnabled)
                      DisclosureCell(
                        title: l10n.passcodeChange,
                        level: AuraLevel.brow,
                        onTap: _chooseCode,
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
    );
  }
}
