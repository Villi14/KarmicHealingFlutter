import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/aura_widgets.dart';
import '../../widgets/help_screen.dart';

/// How to work with the Lords of Karma: the shared five-step guide, plus the
/// detailed process behind it and what a request is made of.
class RequestsHelpScreen extends StatelessWidget {
  const RequestsHelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return HelpScreen(
      level: AuraLevel.sacral,
      tone: AppColors.of(context).friendly,
      extras: [
        _KarmaProcessCard(),
        TipsCard(
          title: l10n.requestsStructureTitle,
          tips: [l10n.requestsStructureExplanation],
          level: AuraLevel.sacral,
        ),
        TipsCard(
          title: l10n.helpTipsTitle,
          tips: importantTips(l10n),
          level: AuraLevel.sacral,
        ),
      ],
    );
  }
}

class _KarmaProcessCard extends StatelessWidget {
  const _KarmaProcessCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final steps = [
      l10n.karmaStep1,
      l10n.karmaStep2,
      l10n.karmaStep3,
      l10n.karmaStep4,
    ];
    final stepsAfterPrayer = [
      l10n.karmaStep5,
      l10n.karmaStep6,
      l10n.karmaStep7,
      l10n.karmaStep8,
    ];
    final categories = [
      l10n.karmaCategoryA,
      l10n.karmaCategoryB,
      l10n.karmaCategoryC,
      l10n.karmaCategoryD,
    ];

    return AuraCard(
      level: AuraLevel.sacral,
      watermark: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              l10n.karmaHelpTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Source Serif 4',
                fontSize: 20,
                color: AppColors.of(context).textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 20),
          for (var index = 0; index < steps.length; index++) ...[
            _KarmaStep(number: index + 1, text: steps[index]),
            const SizedBox(height: 16),
          ],
          _QuoteCard(text: l10n.karmaLiberationPrayer, italic: true),
          const SizedBox(height: 16),
          for (var index = 0; index < stepsAfterPrayer.length; index++) ...[
            _KarmaStep(number: index + 5, text: stepsAfterPrayer[index]),
            const SizedBox(height: 16),
          ],
          _QuoteCard(lines: categories),
          const SizedBox(height: 16),
          _KarmaStep(number: 9, text: l10n.karmaStep9),
        ],
      ),
    );
  }
}

class _KarmaStep extends StatelessWidget {
  const _KarmaStep({required this.number, required this.text});

  final int number;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 30,
        height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.of(context).friendly, width: 2),
        ),
        child: Text(
          '$number',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.of(context).textPrimary,
          ),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Text(
          text,
          style: TextStyle(
            color: AppColors.of(context).textSecondary,
            fontSize: 17,
            height: 1.35,
          ),
        ),
      ),
    ],
  );
}

class _QuoteCard extends StatelessWidget {
  const _QuoteCard({this.text, this.lines = const [], this.italic = false});

  final String? text;
  final List<String> lines;
  final bool italic;

  @override
  Widget build(BuildContext context) {
    final all = [?text, ...lines];
    return AuraCard(
      level: AuraLevel.sacral,
      watermark: false,
      elevated: false,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var index = 0; index < all.length; index++) ...[
            Text(
              all[index],
              style: TextStyle(
                color: AppColors.of(context).textSecondary,
                fontSize: 17,
                height: 1.35,
                fontStyle: italic ? FontStyle.italic : FontStyle.normal,
              ),
            ),
            if (index != all.length - 1) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}
