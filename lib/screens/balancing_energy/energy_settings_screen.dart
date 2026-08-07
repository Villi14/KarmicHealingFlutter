import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../constants/app_colors.dart';
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
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemUiOverlayStyle.dark,
    child: Scaffold(
      body: GradientBackground(
        tone: AppColors.health,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 300),
                child: Column(
                  children: [
                    const Text(
                      'Settings',
                      style: TextStyle(
                        fontFamily: 'Source Serif 4',
                        fontSize: 28,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _MenuRow(
                      icon: const AuraIcon(
                        SFSymbols.clock,
                        level: AuraLevel.heart,
                        size: 20,
                      ),
                      title: 'Session Duration',
                      value: '$_duration minutes',
                      options: const [1, 3, 5, 10, 15],
                      selected: _duration,
                      label: (value) => '$value minutes',
                      onSelected: (value) => setState(() => _duration = value),
                    ),
                    const SizedBox(height: 20),
                    _SwitchRow(
                      icon: const AuraIcon.drawn(
                        SFGlyph.iphoneRadiowaves,
                        level: AuraLevel.heart,
                        size: 20,
                      ),
                      title: 'Vibration',
                      value: _vibration,
                      onChanged: (value) => setState(() => _vibration = value),
                    ),
                    const SizedBox(height: 12),
                    _SwitchRow(
                      icon: const AuraIcon(
                        SFSymbols.speakerWave2,
                        level: AuraLevel.heart,
                        size: 20,
                      ),
                      title: 'Sound',
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
                            'Volume',
                            style: TextStyle(
                              color: _sound
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                              fontSize: 17,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${(_volume * 100).round()}%',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 17,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: AppColors.health,
                        thumbColor: AppColors.health,
                        overlayColor: AppColors.health.withValues(alpha: .12),
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
                      title: 'Rest the screen',
                      value: _screenRest,
                      onChanged: (value) => setState(() => _screenRest = value),
                    ),
                    if (_screenRest) ...[
                      const SizedBox(height: 12),
                      _MenuRow(
                        icon: const AuraIcon(
                          SFSymbols.timer,
                          level: AuraLevel.heart,
                          size: 20,
                        ),
                        title: 'Delay',
                        value: 'After $_delay s',
                        options: const [15, 30, 60, 120],
                        selected: _delay,
                        label: (value) => 'After $value s',
                        onSelected: (value) => setState(() => _delay = value),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'The screen darkens between steps and lights up again on the next one.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 15,
                          height: 1.35,
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: AuraButton(
                        label: 'Done',
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
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 17),
          ),
        ),
        CupertinoSwitch(
          value: value,
          activeTrackColor: AppColors.health,
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
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 17),
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
                style: const TextStyle(
                  color: AppColors.textSecondary,
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
