import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/aura_widgets.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/sf_symbols.dart';

class EnergySettingsScreen extends StatefulWidget {
  const EnergySettingsScreen({super.key});

  @override
  State<EnergySettingsScreen> createState() => _EnergySettingsScreenState();
}

class _EnergySettingsScreenState extends State<EnergySettingsScreen> {
  int _duration = 5;
  bool _vibration = false;
  bool _sound = false;
  double _volume = .5;
  bool _screenRest = true;
  int _delay = 30;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

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
                        value: l10n.minutesCount(_duration),
                        options: const [1, 3, 5, 10, 15],
                        selected: _duration,
                        label: l10n.minutesCount,
                        onSelected: (value) =>
                            setState(() => _duration = value),
                      ),
                      const SizedBox(height: 20),
                      _SwitchRow(
                        icon: const AuraIcon.drawn(
                          SFGlyph.iphoneRadiowaves,
                          level: AuraLevel.heart,
                          size: 20,
                        ),
                        title: l10n.vibration,
                        value: _vibration,
                        onChanged: (value) =>
                            setState(() => _vibration = value),
                      ),
                      const SizedBox(height: 12),
                      _SwitchRow(
                        icon: const AuraIcon(
                          SFSymbols.speakerWave2,
                          level: AuraLevel.heart,
                          size: 20,
                        ),
                        title: l10n.sound,
                        value: _sound,
                        onChanged: (value) => setState(() => _sound = value),
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
                                color: _sound
                                    ? AppColors.of(context).textPrimary
                                    : AppColors.of(context).textSecondary,
                                fontSize: 17,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${(_volume * 100).round()}%',
                              style: TextStyle(
                                color: AppColors.of(context).textSecondary,
                                fontSize: 17,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: AppColors.of(context).health,
                          thumbColor: AppColors.of(context).health,
                          overlayColor: AppColors.of(
                            context,
                          ).health.withValues(alpha: .12),
                        ),
                        child: Slider(
                          value: _volume,
                          divisions: 10,
                          onChanged: _sound
                              ? (value) => setState(() => _volume = value)
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
                        value: _screenRest,
                        onChanged: (value) =>
                            setState(() => _screenRest = value),
                      ),
                      if (_screenRest) ...[
                        const SizedBox(height: 12),
                        _MenuRow(
                          icon: const AuraIcon(
                            SFSymbols.timer,
                            level: AuraLevel.heart,
                            size: 20,
                          ),
                          title: l10n.delay,
                          value: l10n.secondsCount(_delay),
                          options: const [15, 30, 60, 120],
                          selected: _delay,
                          label: l10n.secondsCount,
                          onSelected: (value) => setState(() => _delay = value),
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
        CupertinoSwitch(
          value: value,
          activeTrackColor: AppColors.of(context).health,
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
