import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/design_constants.dart';
import '../l10n/app_localizations.dart';
import 'aura_widgets.dart';
import 'gradient_background.dart';
import 'scroll_blur.dart';
import 'sf_symbols.dart';

/// The five steps of the guide, shared by every help screen that shows it.
List<(String, String, IconData)> helpSteps(AppLocalizations l10n) => [
  (l10n.helpStep1Title, l10n.helpStep1Description, SFSymbols.heart),
  (l10n.helpStep2Title, l10n.helpStep2Description, SFSymbols.moonStars),
  (l10n.helpStep3Title, l10n.helpStep3Description, SFSymbols.sunMax),
  (l10n.helpStep4Title, l10n.helpStep4Description, SFSymbols.handRaised),
  (l10n.helpStep5Title, l10n.helpStep5Description, SFSymbols.checkmarkCircle),
];

/// The energy balancing help opens with the one rule that is specific to it —
/// the Initial Process is walked once, the rest as often as they are needed.
List<String> importantTips(
  AppLocalizations l10n, {
  bool initialProcess = false,
}) => [
  if (initialProcess) l10n.helpTipInitialProcess,
  l10n.helpTip1,
  l10n.helpTip2,
  l10n.helpTip3,
];

/// "How to work with the Lords of Karma" — the same guide wherever it appears,
/// in the tone of the screen that opened it, with that screen's own cards
/// appended below the steps.
class HelpScreen extends StatelessWidget {
  const HelpScreen({
    super.key,
    required this.level,
    required this.tone,
    this.extras = const [],
  });

  final AuraLevel level;
  final Color tone;

  /// Cards shown after the steps, separated by the same 32pt rhythm.
  final List<Widget> extras;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final steps = helpSteps(l10n);

    return ScrollBlur(
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          flexibleSpace: const ScrollBlurBackdrop(),
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          title: Text(l10n.help),
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: AuraIcon(SFSymbols.xmark, level: level),
            ),
          ],
        ),
        body: GradientBackground(
          tone: tone,
          child: SafeArea(
            top: false,
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 700),
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    DesignConstants.contentTopInset(context),
                    16,
                    32,
                  ),
                  child: Column(
                    children: [
                      AuraIcon(
                        SFSymbols.questionmarkCircle,
                        level: level,
                        size: 60,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        l10n.helpTitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Source Serif 4',
                          fontSize: 28,
                          color: AppColors.of(context).textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        l10n.helpSubtitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.of(context).textPrimary,
                          fontSize: 17,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 32),
                      for (var index = 0; index < steps.length; index++) ...[
                        HelpStep(
                          number: index + 1,
                          step: steps[index],
                          level: level,
                        ),
                        if (index != steps.length - 1)
                          const SizedBox(height: 20),
                      ],
                      for (final extra in extras) ...[
                        const SizedBox(height: 32),
                        extra,
                      ],
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

class HelpStep extends StatelessWidget {
  const HelpStep({
    super.key,
    required this.number,
    required this.step,
    required this.level,
  });

  final int number;
  final (String, String, IconData) step;
  final AuraLevel level;

  @override
  Widget build(BuildContext context) => AuraCard(
    level: level,
    watermark: false,
    padding: const EdgeInsets.all(12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: level.color(context), width: 2),
          ),
          child: Text(
            '$number',
            style: TextStyle(
              fontFamily: 'Source Serif 4',
              fontSize: 20,
              color: AppColors.of(context).textPrimary,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AuraIcon(step.$3, level: level, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      step.$1,
                      style: TextStyle(
                        fontFamily: 'Source Serif 4',
                        fontSize: 20,
                        color: AppColors.of(context).textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                step.$2,
                style: TextStyle(
                  color: AppColors.of(context).textSecondary,
                  fontSize: 17,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class TipsCard extends StatelessWidget {
  const TipsCard({
    super.key,
    required this.title,
    required this.tips,
    required this.level,
  });

  final String title;
  final List<String> tips;
  final AuraLevel level;

  @override
  Widget build(BuildContext context) => AuraCard(
    level: level,
    watermark: false,
    child: Column(
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Source Serif 4',
            fontSize: 20,
            color: AppColors.of(context).textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        for (var index = 0; index < tips.length; index++) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AuraIcon(SFSymbols.lightbulb, level: level, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  tips[index],
                  style: TextStyle(
                    color: AppColors.of(context).textSecondary,
                    fontSize: 17,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
          if (index != tips.length - 1) const SizedBox(height: 8),
        ],
      ],
    ),
  );
}
