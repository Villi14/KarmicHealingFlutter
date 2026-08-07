import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../constants/app_colors.dart';
import '../../constants/design_constants.dart';
import '../../widgets/aura_widgets.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/list_row.dart';
import '../../widgets/scroll_blur.dart';
import '../../widgets/sf_symbols.dart';
import 'reminder_forms.dart';

/// A single reminder as it stands in a topic's list.
class Reminder {
  const Reminder(
    this.title, {
    this.notes = '',
    this.priority = 0,
    this.dueDate,
    this.isCompleted = false,
    this.isFlagged = false,
  });

  final String title;
  final String notes;
  final int priority;
  final DateTime? dueDate;
  final bool isCompleted;
  final bool isFlagged;
}

class RemindersDetailScreen extends StatelessWidget {
  const RemindersDetailScreen({
    super.key,
    this.title = 'Personal',
    this.color = const Color(0xFF4A99EF),
  });

  final String title;
  final Color color;

  static final _items = [
    Reminder(
      'Morning meditation',
      notes: 'Ten quiet minutes before anything else',
      priority: 2,
      dueDate: DateTime(2026, 8, 7, 8),
      isFlagged: true,
    ),
    Reminder(
      'Energy check-in',
      notes: 'Notice how the day sits in the body',
      priority: 1,
      dueDate: DateTime(2026, 8, 6),
    ),
    const Reminder('Gratitude practice', notes: 'Three things, written down'),
    const Reminder('Evening breathing'),
    const Reminder('Read a chapter', isCompleted: true),
  ];

  @override
  Widget build(BuildContext context) => ScrollBlur(
    child: Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        flexibleSpace: const ScrollBlurBackdrop(),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const AuraIcon(SFSymbols.chevronLeft, level: AuraLevel.solar),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const AuraIcon(SFSymbols.ellipsis, level: AuraLevel.solar),
          ),
        ],
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.backgroundPrimary.withValues(alpha: .92),
          border: Border(
            top: BorderSide(
              color: AppColors.textSecondary.withValues(alpha: .12),
              width: .5,
            ),
          ),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 48,
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ReminderFormScreen(topicColor: color),
                  ),
                ),
                icon: ToneIcon(SFSymbols.plus, tone: color),
                label: Text(
                  'Reminder',
                  style: TextStyle(color: color, fontSize: 17),
                ),
              ),
            ),
          ),
        ),
      ),
      body: GradientBackground(
        tone: AppColors.clarity,
        child: SafeArea(
          top: false,
          bottom: false,
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  20,
                  DesignConstants.navigationBarInset(context) + 8,
                  20,
                  24,
                ),
                children: [
                  _TopicHeader(title: title, color: color),
                  const SizedBox(height: 20),
                  for (final item in _items) ...[
                    _ReminderRow(reminder: item, color: color),
                    const SizedBox(height: 8),
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

class _TopicHeader extends StatelessWidget {
  const _TopicHeader({required this.title, required this.color});

  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      AuraLabel('Topic', tone: color),
      const SizedBox(height: 8),
      Text(
        title,
        style: TextStyle(
          fontFamily: 'Source Serif 4',
          fontSize: 20,
          color: color,
        ),
      ),
    ],
  );
}

class _ReminderRow extends StatelessWidget {
  const _ReminderRow({required this.reminder, required this.color});

  final Reminder reminder;
  final Color color;

  @override
  Widget build(BuildContext context) => AuraCard(
    level: AuraLevel.solar,
    tone: color,
    watermark: false,
    elevated: false,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ToneIcon(
          reminder.isCompleted ? SFSymbols.checkmarkCircle : SFSymbols.circle,
          tone: color,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  if (reminder.priority > 0) ...[
                    Text(
                      '!' * reminder.priority,
                      style: TextStyle(
                        color: reminder.isCompleted
                            ? AppColors.textSecondary
                            : color,
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
                            ? AppColors.textSecondary
                            : AppColors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w500,
                        decoration: reminder.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                        decorationColor: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              if (reminder.notes.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  reminder.notes,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 15,
                    height: 1.25,
                  ),
                ),
              ],
              if (reminder.dueDate != null) ...[
                const SizedBox(height: 6),
                DueDateBadge(
                  date: reminder.dueDate!,
                  isPastDue:
                      !reminder.isCompleted &&
                      reminder.dueDate!.isBefore(DateTime(2026, 8, 7, 12)),
                ),
              ],
            ],
          ),
        ),
        if (reminder.isFlagged) ...[
          const SizedBox(width: 8),
          ToneIcon(SFSymbols.flagFill, tone: color),
        ],
        const SizedBox(width: 8),
        ToneIcon(SFSymbols.infoCircle, tone: color),
      ],
    ),
  );
}
