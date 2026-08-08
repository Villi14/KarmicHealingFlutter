import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../data/models.dart';
import '../../data/reminders_repository.dart';
import '../../data/repository_scope.dart';
import '../../widgets/aura_widgets.dart';
import '../../widgets/list_row.dart';
import '../../widgets/sf_symbols.dart';
import 'reminder_forms.dart';

/// One reminder, wherever it stands: in its own topic, or beside rows from
/// other topics on Today, All, Flagged and in search.
class ReminderRow extends StatelessWidget {
  const ReminderRow({
    super.key,
    required this.reminder,
    required this.topic,
    this.tone,
    this.showsTopic = false,
  });

  final Reminder reminder;
  final RemindersList topic;

  /// The colour of the screen it stands on. A topic's own screen paints its
  /// rows in the topic's colour; the mixed screens paint theirs in their own.
  final Color? tone;

  /// Screens that mix topics name the topic each reminder came from. A topic's
  /// own screen already says it in the title, so it stays quiet there.
  final bool showsTopic;

  @override
  Widget build(BuildContext context) {
    final repository = RepositoryScope.remindersOf(context);
    final colors = AppColors.of(context);
    final color = tone ?? topic.color;
    final isPastDue = RemindersRepository.isPastDue(reminder);

    return SwipeToDelete(
      id: reminder.id,
      onDelete: () => repository.deleteReminder(reminder.id),
      child: AuraCard(
        level: AuraLevel.solar,
        tone: color,
        watermark: false,
        elevated: false,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () => repository.toggleReminderCompletion(reminder.id),
              child: ToneIcon(
                reminder.isCompleted
                    ? SFSymbols.checkmarkCircle
                    : SFSymbols.circle,
                tone: color,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _openForm(context),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showsTopic) ...[
                      RowBadge(title: topic.title, tone: topic.color),
                      const SizedBox(height: 4),
                    ],
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        if (reminder.priority != null) ...[
                          Text(
                            '!' * reminder.priority!.rawValue,
                            style: TextStyle(
                              color: reminder.isCompleted
                                  ? colors.textSecondary
                                  : topic.color,
                              fontSize: 17,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Flexible(
                          child: Text(
                            reminder.title,
                            style: TextStyle(
                              color: reminder.isCompleted
                                  ? colors.textSecondary
                                  : colors.textPrimary,
                              fontSize: 17,
                              fontWeight: FontWeight.w500,
                              decoration: reminder.isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                              decorationColor: colors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (reminder.notes.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        // Notes read as one line in a row; the whole of them
                        // waits in the form.
                        reminder.notes.replaceAll('\n', ' '),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 15,
                          height: 1.25,
                        ),
                      ),
                    ],
                    if (reminder.dueDate != null) ...[
                      const SizedBox(height: 6),
                      DueDateBadge(
                        date: reminder.dueDate!,
                        isPastDue: isPastDue,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            GestureDetector(
              onTap: () => repository.toggleFlag(reminder.id),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Opacity(
                  opacity: reminder.isFlagged ? 1 : .35,
                  child: ToneIcon(
                    reminder.isFlagged ? SFSymbols.flagFill : SFSymbols.flag,
                    tone: color,
                  ),
                ),
              ),
            ),
            GestureDetector(
              onTap: () => _openForm(context),
              child: ToneIcon(SFSymbols.infoCircle, tone: color),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openForm(BuildContext context) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => ReminderFormScreen(
        topicId: reminder.remindersListId,
        reminder: reminder,
        screenTitle: 'Details',
      ),
    ),
  );
}
