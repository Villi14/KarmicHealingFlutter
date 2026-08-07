import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import 'aura_widgets.dart';

/// What a list says when it has nothing to show: the ring motif around a glyph,
/// a line of voice, a line of explanation, and the one action that ends the emptiness.
class KarmicEmptyState extends StatelessWidget {
  const KarmicEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    required this.level,
    this.tone,
    this.actionTitle,
    this.onAction,
  });

  final Widget icon;
  final String title;
  final String message;
  final AuraLevel level;
  final Color? tone;
  final String? actionTitle;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => AuraCard(
    level: level,
    tone: tone ?? level.color,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
    child: Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            AuraRings(level: level, size: 96, opacity: .35),
            icon,
          ],
        ),
        const SizedBox(height: 20),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Source Serif 4',
            fontSize: 20,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 15,
            height: 1.35,
          ),
        ),
        if (actionTitle != null && onAction != null) ...[
          const SizedBox(height: 20),
          AuraButton(label: actionTitle!, level: level, onPressed: onAction!),
        ],
      ],
    ),
  );
}
