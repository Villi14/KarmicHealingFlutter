import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../constants/app_colors.dart';
import 'aura_widgets.dart';
import 'sf_symbols.dart';

/// One row of a list of things the user made: a topic, a request, a reminder.
///
/// The leading glyph turns into a radio button when the row can be completed;
/// rows that cannot show a plain glyph instead. The info button sits in plain
/// sight rather than behind a swipe.
class ListRow extends StatelessWidget {
  const ListRow({
    super.key,
    required this.title,
    required this.tone,
    this.icon = SFSymbols.tag,
    this.count,
    this.isCompleted = false,
    this.showsCompletion = false,
    this.onTap,
    this.onInfo,
    this.watermark = true,
  });

  final String title;
  final Color tone;
  final IconData icon;
  final int? count;
  final bool isCompleted;
  final bool showsCompletion;
  final VoidCallback? onTap;
  final VoidCallback? onInfo;
  final bool watermark;

  @override
  Widget build(BuildContext context) => AuraCard(
    level: AuraLevel.solar,
    tone: tone,
    watermark: watermark,
    elevated: false,
    onTap: onTap,
    padding: EdgeInsets.zero,
    child: SizedBox(
      height: 56,
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: ToneIcon(
              showsCompletion
                  ? (isCompleted ? SFSymbols.checkmarkCircle : SFSymbols.circle)
                  : icon,
              tone: tone,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: isCompleted
                    ? AppColors.textSecondary
                    : AppColors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w500,
                decoration: isCompleted ? TextDecoration.lineThrough : null,
                decorationColor: AppColors.textSecondary,
              ),
            ),
          ),
          if (onInfo != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GestureDetector(
                onTap: onInfo,
                child: ToneIcon(SFSymbols.infoCircle, tone: tone),
              ),
            ),
          if (count != null && count! > 0) ...[
            Text(
              '$count',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 28,
                fontWeight: FontWeight.w300,
              ),
            ),
            const SizedBox(width: 16),
          ],
        ],
      ),
    ),
  );
}

/// The thing a row hangs from — the topic of a reminder, the request of a
/// subrequest — wearing that thing's own colour. Shown on the screens where
/// rows from several parents stand side by side.
class RowBadge extends StatelessWidget {
  const RowBadge({
    super.key,
    required this.title,
    required this.tone,
    this.icon = SFSymbols.tag,
  });

  final String title;
  final Color tone;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 11, color: Color.lerp(tone, Colors.black, .3)),
      const SizedBox(width: 4),
      Flexible(child: AuraLabel(title, tone: tone)),
    ],
  );
}

/// When a reminder is due, and whether that moment has already passed.
class DueDateBadge extends StatelessWidget {
  const DueDateBadge({
    super.key,
    required this.date,
    required this.isPastDue,
    this.level = AuraLevel.solar,
  });

  final DateTime date;
  final bool isPastDue;
  final AuraLevel level;

  @override
  Widget build(BuildContext context) {
    final color = isPastDue ? level.color : AppColors.textSecondary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isPastDue ? SFSymbols.exclamationmarkTriangle : SFSymbols.calendar,
          size: 12,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(
          DateFormat.yMMMd().format(date),
          style: TextStyle(color: color, fontSize: 12),
        ),
        if (isPastDue)
          Text('  Overdue', style: TextStyle(color: color, fontSize: 12)),
      ],
    );
  }
}
