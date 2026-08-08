import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/aura_widgets.dart';
import '../../widgets/gradient_background.dart';
import '../../theme_controller.dart';
import '../../widgets/sf_symbols.dart';

/// Which appearance the app follows. A dialog rather than a page: three options
/// on their own cards, and the one action that closes them.
class ThemeSettingsScreen extends StatelessWidget {
  const ThemeSettingsScreen({super.key});

  static Map<ThemeMode, String> _themes(AppLocalizations l10n) => {
    ThemeMode.system: l10n.system,
    ThemeMode.light: l10n.light,
    ThemeMode.dark: l10n.dark,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: statusBarStyle(Theme.of(context).brightness),
      child: Scaffold(
        body: GradientBackground(
          tone: AppColors.of(context).peace,
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 56,
                  vertical: 24,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 300),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.theme,
                        style: TextStyle(
                          fontFamily: 'Source Serif 4',
                          fontSize: 28,
                          color: AppColors.of(context).textPrimary,
                        ),
                      ),
                      const SizedBox(height: 20),
                      for (final theme in _themes(l10n).entries) ...[
                        _ThemeOption(
                          title: theme.value,
                          isSelected: theme.key == ThemeScope.of(context).value,
                          onTap: () =>
                              ThemeScope.of(context).setMode(theme.key),
                        ),
                        const SizedBox(height: 12),
                      ],
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: AuraButton(
                          label: l10n.done,
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
                  ? AppColors.of(context).textPrimary
                  : AppColors.of(context).textSecondary,
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
