import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../widgets/aura_widgets.dart';
import '../../widgets/help_screen.dart';

/// How to work with the Lords of Karma: the shared five-step guide, plus the
/// detailed process behind it and what a request is made of.
class RequestsHelpScreen extends StatelessWidget {
  const RequestsHelpScreen({super.key});

  static const _structureTip =
      'A request can be broken into subrequests. While any subrequest is unfulfilled, the request itself stays locked \u2014 mark it yourself once they are all done.';

  @override
  Widget build(BuildContext context) => HelpScreen(
    level: AuraLevel.sacral,
    tone: AppColors.of(context).friendly,
    extras: [
      _KarmaProcessCard(),
      TipsCard(
        title: 'Request Structure',
        tips: [_structureTip],
        level: AuraLevel.sacral,
      ),
      TipsCard(
        title: 'Important Tips',
        tips: importantTips,
        level: AuraLevel.sacral,
      ),
    ],
  );
}

class _KarmaProcessCard extends StatelessWidget {
  const _KarmaProcessCard();

  static const _karmaSteps = [
    'Ask permission to speak with the Lords of Karma - you will feel their presence.',
    'Ask for the karmic liberation you wish to receive.',
    'You will receive an answer "yes" or "no".',
    'If the answer is "yes", ask for liberation:',
  ];

  static const _prayer =
      'Let this healing pass through all levels and all bodies, through all my lives, including this present life, let all harm (caused by connections or situations) be removed, and let healing come to today - to NOW!';

  static const _karmaStepsAfterPrayer = [
    'If the answer is "no", ask what you should do to achieve liberation. Wait for the answer. If you receive information about a past life that you don\'t fully understand, ask for clarification.',
    'If you receive "no" in step 4, repeat questions requiring yes-no answers at each stage. Each time you receive a negative answer, do what is written in step 5.',
    'You can ask as many times as you want and about anything. But your requests should be simple and stated separately.',
    'Use this process for four categories of karmic healing:',
  ];

  static const _categories = [
    'a) for healing from diseases or correcting physical condition;',
    'b) for healing conflict relationships;',
    'c) for getting rid of negative character traits and bad habits;',
    'd) for correcting negative life situations.',
  ];

  static const _lastKarmaStep =
      "Treat these Beings with great respect. Never argue with them and don't forget to thank them.";

  @override
  Widget build(BuildContext context) => AuraCard(
    level: AuraLevel.sacral,
    watermark: false,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Text(
            'Detailed Process of Working with the Lords of Karma',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Source Serif 4',
              fontSize: 20,
              color: AppColors.of(context).textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 20),
        for (var index = 0; index < _karmaSteps.length; index++) ...[
          _KarmaStep(number: index + 1, text: _karmaSteps[index]),
          const SizedBox(height: 16),
        ],
        const _QuoteCard(text: _prayer, italic: true),
        const SizedBox(height: 16),
        for (var index = 0; index < _karmaStepsAfterPrayer.length; index++) ...[
          _KarmaStep(number: index + 5, text: _karmaStepsAfterPrayer[index]),
          const SizedBox(height: 16),
        ],
        const _QuoteCard(lines: _categories),
        const SizedBox(height: 16),
        const _KarmaStep(number: 9, text: _lastKarmaStep),
      ],
    ),
  );
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
