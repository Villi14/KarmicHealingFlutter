import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/design_constants.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/aura_widgets.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/scroll_blur.dart';
import '../../widgets/sf_symbols.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static List<(String, String)> _sections(AppLocalizations l10n) => [
    (l10n.privacyPolicyIntroTitle, l10n.privacyPolicyIntroContent),
    (l10n.privacyPolicyDataTitle, l10n.privacyPolicyDataContent),
    (l10n.privacyPolicyStorageTitle, l10n.privacyPolicyStorageContent),
    (
      l10n.privacyPolicyNotificationsTitle,
      l10n.privacyPolicyNotificationsContent,
    ),
    (l10n.privacyPolicyThirdPartyTitle, l10n.privacyPolicyThirdPartyContent),
    (l10n.privacyPolicyContactTitle, l10n.privacyPolicyContactContent),
  ];

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
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const AuraIcon(SFSymbols.xmark, level: AuraLevel.crown),
            ),
          ],
        ),
        body: GradientBackground(
          tone: AppColors.of(context).wisdom,
          child: SafeArea(
            top: false,
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 700),
                child: ListView(
                  padding: EdgeInsets.fromLTRB(
                    12,
                    DesignConstants.navigationBarInset(context) + 8,
                    12,
                    32,
                  ),
                  children: [
                    Text(
                      l10n.privacyPolicy,
                      style: TextStyle(
                        fontFamily: 'Source Serif 4',
                        fontSize: 28,
                        color: AppColors.of(context).textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    AuraLabel(l10n.privacyPolicyLastUpdated),
                    const SizedBox(height: 32),
                    for (final section in _sections(l10n)) ...[
                      Text(
                        section.$1,
                        style: TextStyle(
                          fontFamily: 'Source Serif 4',
                          fontSize: 20,
                          color: AppColors.of(context).textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        section.$2,
                        style: TextStyle(
                          color: AppColors.of(context).textSecondary,
                          fontSize: 17,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
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
