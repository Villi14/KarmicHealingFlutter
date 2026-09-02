import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../locale_controller.dart';
import '../../widgets/aura_widgets.dart';
import '../../widgets/choice_card.dart';
import '../../widgets/gradient_background.dart';

/// Which language the app speaks. Built like the appearance screen it sits
/// beside — options on their own cards, and the one action that closes them —
/// only there are sixteen of them, so the column scrolls rather than centring.
///
/// Each language is named in itself, because somebody who has landed here by
/// accident in a language they cannot read still has to find their way back,
/// and "Українська" is the one word on this screen they will recognise.
class LanguageSettingsScreen extends StatelessWidget {
  const LanguageSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controller = LocaleScope.of(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: statusBarStyle(Theme.of(context).brightness),
      child: Scaffold(
        body: GradientBackground(
          tone: AppColors.of(context).peace,
          child: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 300),
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    Text(
                      l10n.changeLanguage,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Source Serif 4',
                        fontSize: 28,
                        color: AppColors.of(context).textPrimary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Sixteen options are more than a screen holds, so only the
                    // list scrolls: the title stays above it and the way out
                    // stays below, within reach of a thumb that has not yet
                    // found its language.
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        children: [
                          // Following the device comes first, as it does on the
                          // appearance screen, and is what the app did before
                          // anybody chose anything.
                          ChoiceCard(
                            title: l10n.system,
                            isSelected: controller.value == null,
                            onTap: () => controller.setLocale(null),
                          ),
                          const SizedBox(height: 12),
                          for (final locale in LocaleController.choices) ...[
                            ChoiceCard(
                              title: LocaleController.nameOf(locale),
                              isSelected: controller.value == locale,
                              onTap: () => controller.setLocale(locale),
                            ),
                            const SizedBox(height: 12),
                          ],
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 8, 8, 24),
                      child: SizedBox(
                        width: double.infinity,
                        child: AuraButton(
                          label: l10n.done,
                          level: AuraLevel.brow,
                          onPressed: () => Navigator.of(context).maybePop(),
                        ),
                      ),
                    ),
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
