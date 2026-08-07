import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../constants/app_colors.dart';
import '../../widgets/aura_widgets.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/sf_symbols.dart';

/// Which appearance the app follows. A dialog rather than a page: three options
/// on their own cards, and the one action that closes them.
class ThemeSettingsScreen extends StatefulWidget {
  const ThemeSettingsScreen({super.key});

  @override
  State<ThemeSettingsScreen> createState() => _ThemeSettingsScreenState();
}

class _ThemeSettingsScreenState extends State<ThemeSettingsScreen> {
  static const _themes = ['System', 'Light', 'Dark'];

  String _theme = 'System';

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemUiOverlayStyle.dark,
    child: Scaffold(
      body: GradientBackground(
        tone: AppColors.peace,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 56, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 300),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Theme',
                      style: TextStyle(
                        fontFamily: 'Source Serif 4',
                        fontSize: 28,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    for (final theme in _themes) ...[
                      _ThemeOption(
                        title: theme,
                        isSelected: theme == _theme,
                        onTap: () => setState(() => _theme = theme),
                      ),
                      const SizedBox(height: 12),
                    ],
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: AuraButton(
                        label: 'Done',
                        level: AuraLevel.brow,
                        onPressed: () => Navigator.of(context).maybePop(),
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

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => AuraCard(
    level: AuraLevel.brow,
    watermark: false,
    onTap: onTap,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: isSelected
                  ? AppColors.textPrimary
                  : AppColors.textSecondary,
              fontSize: 17,
            ),
          ),
        ),
        if (isSelected)
          const AuraIcon(SFSymbols.checkmark, level: AuraLevel.brow, size: 18),
      ],
    ),
  );
}
