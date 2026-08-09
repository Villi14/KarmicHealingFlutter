import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_theme.dart';
import '../../data/energy_settings.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/aura_widgets.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/sf_symbols.dart';

/// Every row here writes straight through to [EnergySettings]: there is no
/// local copy of a setting to get out of step with what was stored, and no
/// "save" for the user to forget.
class EnergySettingsScreen extends StatelessWidget {
  const EnergySettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settings = EnergySettingsScope.of(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: statusBarStyle(Theme.of(context).brightness),
      child: Scaffold(
        body: GradientBackground(
          tone: AppColors.of(context).health,
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 300),
                  child: Column(
                    children: [
                      Text(
                        l10n.settings,
                        style: TextStyle(
                          fontFamily: 'Source Serif 4',
                          fontSize: 28,
                          color: AppColors.of(context).textPrimary,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _MenuRow(
                        icon: const AuraIcon(
                          SFSymbols.clock,
                          level: AuraLevel.heart,
                          size: 20,
                        ),
                        title: l10n.sessionDuration,
                        value: l10n.minutesCount(settings.sessionDuration),
                        options: EnergySettings.durationOptions,
                        selected: settings.sessionDuration,
                        label: l10n.minutesCount,
                        onSelected: settings.setSessionDuration,
                      ),
                      const SizedBox(height: 20),
                      _SwitchRow(
                        icon: const AuraIcon.drawn(
                          SFGlyph.iphoneRadiowaves,
                          level: AuraLevel.heart,
                          size: 20,
                        ),
                        title: l10n.vibration,
                        value: settings.vibrationEnabled,
                        onChanged: settings.setVibrationEnabled,
                      ),
                      const SizedBox(height: 12),
                      _SwitchRow(
                        icon: const AuraIcon(
                          SFSymbols.speakerWave2,
                          level: AuraLevel.heart,
                          size: 20,
                        ),
                        title: l10n.sound,
                        value: settings.soundEnabled,
                        onChanged: settings.setSoundEnabled,
                      ),
                      const SizedBox(height: 20),
                      _SettingsCard(
                        child: Row(
                          children: [
                            const AuraIcon(
                              SFSymbols.speakerWave3,
                              level: AuraLevel.heart,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              l10n.volume,
                              style: TextStyle(
                                color: settings.soundEnabled
                                    ? AppColors.of(context).textPrimary
                                    : AppColors.of(context).textSecondary,
                                fontSize: 17,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${(settings.audioVolume * 100).round()}%',
                              style: TextStyle(
                                color: AppColors.of(context).textSecondary,
                                fontSize: 17,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: AuraSlider(
                          value: settings.audioVolume,
                          level: AuraLevel.heart,
                          divisions: 10,
                          label: l10n.volume,
                          onChanged: settings.soundEnabled
                              ? settings.setAudioVolume
                              : null,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _SwitchRow(
                        icon: const AuraIcon(
                          SFSymbols.moonStars,
                          level: AuraLevel.heart,
                          size: 20,
                        ),
                        title: l10n.screenRest,
                        value: settings.screenRestEnabled,
                        onChanged: settings.setScreenRestEnabled,
                      ),
                      if (settings.screenRestEnabled) ...[
                        const SizedBox(height: 12),
                        _MenuRow(
                          icon: const AuraIcon(
                            SFSymbols.timer,
                            level: AuraLevel.heart,
                            size: 20,
                          ),
                          title: l10n.delay,
                          value: l10n.secondsCount(settings.screenRestDelay),
                          options: EnergySettings.restDelayOptions,
                          selected: settings.screenRestDelay,
                          label: l10n.secondsCount,
                          onSelected: settings.setScreenRestDelay,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          l10n.screenRestHint,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.of(context).textSecondary,
                            fontSize: 15,
                            height: 1.35,
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: AuraButton(
                          label: l10n.done,
                          level: AuraLevel.heart,
                          onPressed: () => Navigator.of(context).pop(),
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

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => AuraCard(
    level: AuraLevel.heart,
    watermark: false,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: child,
  );
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final Widget icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => _SettingsCard(
    child: Row(
      children: [
        icon,
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: AppColors.of(context).textPrimary,
              fontSize: 17,
            ),
          ),
        ),
        AuraSwitch(
          value: value,
          level: AuraLevel.heart,
          label: title,
          onChanged: onChanged,
        ),
      ],
    ),
  );
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.options,
    required this.selected,
    required this.label,
    required this.onSelected,
  });

  final Widget icon;
  final String title;
  final String value;
  final List<int> options;
  final int selected;
  final String Function(int) label;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) => _SettingsCard(
    child: Row(
      children: [
        icon,
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: AppColors.of(context).textPrimary,
              fontSize: 17,
            ),
          ),
        ),
        PopupMenuButton<int>(
          initialValue: selected,
          onSelected: onSelected,
          itemBuilder: (context) => [
            for (final option in options)
              PopupMenuItem(
                value: option,
                child: Row(
                  children: [
                    SizedBox(
                      width: 24,
                      child: option == selected
                          ? const Icon(SFSymbols.checkmark, size: 18)
                          : null,
                    ),
                    Text(label(option)),
                  ],
                ),
              ),
          ],
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: AppColors.of(context).textSecondary,
                  fontSize: 17,
                ),
              ),
              const SizedBox(width: 8),
              const AuraIcon(
                SFSymbols.chevronUpChevronDown,
                level: AuraLevel.heart,
                size: 18,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
