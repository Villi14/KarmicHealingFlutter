import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/design_constants.dart';
import 'aura_widgets.dart';
import 'gradient_background.dart';
import 'scroll_blur.dart';
import 'sf_symbols.dart';

/// The five steps of the guide, shared by every help screen that shows it.
const helpSteps = <(String, String, IconData)>[
  (
    'Prepare your space',
    "Find a quiet place where you won't be disturbed. Sit or lie down comfortably, close your eyes, and take several deep breaths to relax.",
    SFSymbols.heart,
  ),
  (
    'Ask for permission',
    'Mentally or aloud, ask the Lords of Karma for permission to speak with them. Wait for their response - you may feel a sense of permission or guidance.',
    SFSymbols.moonStars,
  ),
  (
    'Formulate your request',
    'Clearly and respectfully state your request. Be specific about what you need help with. Speak from your heart with sincerity and humility.',
    SFSymbols.sunMax,
  ),
  (
    'Listen and observe',
    'After making your request, remain quiet and attentive. You may receive guidance through thoughts, feelings, images, or inner knowing. Trust your intuition.',
    SFSymbols.handRaised,
  ),
  (
    'Express gratitude',
    'Thank the Lords of Karma for their time and assistance. Express your gratitude sincerely, regardless of whether you received immediate help or not.',
    SFSymbols.checkmarkCircle,
  ),
];

const importantTips = [
  'Practice regularly - the more you communicate, the stronger your connection becomes',
  'Be patient - answers may not come immediately, but they will come at the right time',
  "Trust the process - even if you don't see immediate results, trust that healing is happening",
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
  Widget build(BuildContext context) => ScrollBlur(
    child: Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        flexibleSpace: const ScrollBlurBackdrop(),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text('Help'),
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
                  DesignConstants.navigationBarInset(context) + 24,
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
                      'How to work with the Lords of Karma',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Source Serif 4',
                        fontSize: 28,
                        color: AppColors.of(context).textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Step-by-step guide to effective communication',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.of(context).textPrimary,
                        fontSize: 17,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 32),
                    for (var index = 0; index < helpSteps.length; index++) ...[
                      HelpStep(
                        number: index + 1,
                        step: helpSteps[index],
                        level: level,
                      ),
                      if (index != helpSteps.length - 1)
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
