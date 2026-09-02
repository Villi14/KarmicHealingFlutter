import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import 'aura_widgets.dart';
import 'sf_symbols.dart';

/// One option in a list where exactly one is chosen: the appearance the app
/// wears, the language it speaks. The chosen one is the one in full colour,
/// with a checkmark; the rest wait in the secondary tone.
class ChoiceCard extends StatelessWidget {
  const ChoiceCard({
    super.key,
    required this.title,
    required this.isSelected,
    required this.onTap,
    this.level = AuraLevel.brow,
  });

  final String title;
  final bool isSelected;
  final VoidCallback onTap;
  final AuraLevel level;

  @override
  Widget build(BuildContext context) => AuraCard(
    level: level,
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
        if (isSelected) AuraIcon(SFSymbols.checkmark, level: level, size: 18),
      ],
    ),
  );
}
