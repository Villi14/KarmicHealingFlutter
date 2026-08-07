import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import 'aura_widgets.dart';

/// A tile in the grid of standing filters above a list — Today, Flagged, All.
/// The count sits as a figure on the right, so the tile reads as a measurement.
class GridCell extends StatelessWidget {
  const GridCell({
    super.key,
    required this.title,
    required this.icon,
    required this.level,
    required this.onTap,
    this.count,
  });

  final String title;
  final IconData icon;
  final AuraLevel level;
  final VoidCallback onTap;
  final int? count;

  @override
  Widget build(BuildContext context) => AuraCard(
    level: level,
    onTap: onTap,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 4),
              AuraIcon(icon, level: level, size: 18),
              const SizedBox(height: 12),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Source Serif 4',
                  fontSize: 15,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        if (count != null)
          Text(
            '$count',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 28,
              fontWeight: FontWeight.w300,
            ),
          ),
      ],
    ),
  );
}
