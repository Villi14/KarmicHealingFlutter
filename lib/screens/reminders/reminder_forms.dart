import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../constants/app_colors.dart';
import '../../data/models.dart';
import '../../data/repository_scope.dart';
import '../../widgets/aura_alert.dart';
import '../../widgets/aura_widgets.dart';
import '../../widgets/color_picker_row.dart';
import '../../widgets/karmic_form.dart';
import '../../widgets/sf_symbols.dart';

/// The form behind a reminder: what it says, when it is due, and how loudly
/// it asks to be seen.
class ReminderFormScreen extends StatefulWidget {
  const ReminderFormScreen({
    super.key,
    required this.topicId,
    this.reminder,
    this.screenTitle,
  });

  /// The topic the form opens on. An edited reminder may be moved to another.
  final String topicId;

  /// The reminder being edited, or `null` for one that does not exist yet.
  final Reminder? reminder;
  final String? screenTitle;

  @override
  State<ReminderFormScreen> createState() => _ReminderFormScreenState();
}

class _ReminderFormScreenState extends State<ReminderFormScreen> {
  late final _title = TextEditingController(text: widget.reminder?.title ?? '');
  late final _notes = TextEditingController(text: widget.reminder?.notes ?? '');

  late DateTime? _dueDate = widget.reminder?.dueDate;
  late bool _isFlagged = widget.reminder?.isFlagged ?? false;
  late Priority? _priority = widget.reminder?.priority;
  late String _topicId = widget.reminder?.remindersListId ?? widget.topicId;

  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repository = RepositoryScope.remindersOf(context);
    final topic = repository.topicById(_topicId);

    return KarmicFormShell(
      title: widget.screenTitle ?? (widget.reminder == null ? 'New' : 'Edit'),
      tone: AppColors.of(context).clarity,
      onSave: _save,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          KarmicFormField(
            controller: _title,
            hint: 'Title',
            level: AuraLevel.solar,
            serif: true,
          ),
          const SizedBox(height: 20),
          KarmicFormField(
            controller: _notes,
            hint: 'Notes',
            level: AuraLevel.solar,
            minLines: 4,
          ),
          const SizedBox(height: 20),
          KarmicFormToggle(
            icon: SFSymbols.calendar,
            title: 'Date',
            level: AuraLevel.solar,
            value: _dueDate != null,
            onChanged: (isEnabled) => setState(
              () => _dueDate = isEnabled ? (_dueDate ?? DateTime.now()) : null,
            ),
          ),
          if (_dueDate != null) ...[
            const SizedBox(height: 12),
            KarmicFormCard(
              level: AuraLevel.solar,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _pickDate,
                    child: Text(
                      DateFormat.yMMMd().add_jm().format(_dueDate!),
                      style: TextStyle(
                        color: AppColors.of(context).clarity,
                        fontSize: 17,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          KarmicFormToggle(
            icon: SFSymbols.flag,
            title: 'Flag',
            level: AuraLevel.solar,
            value: _isFlagged,
            onChanged: (value) => setState(() => _isFlagged = value),
          ),
          const SizedBox(height: 12),
          // A menu entry has to carry a value to be picked at all, so "None" is
          // a choice of its own rather than a null.
          KarmicFormPicker<_PriorityChoice>(
            icon: SFSymbols.exclamationmark,
            title: 'Priority',
            level: AuraLevel.solar,
            value: _PriorityChoice.of(_priority),
            options: _PriorityChoice.values,
            label: (choice) => choice.label,
            onSelected: (choice) => setState(() => _priority = choice.priority),
          ),
          const SizedBox(height: 12),
          KarmicFormPicker<String>(
            icon: SFSymbols.tag,
            title: 'Topic',
            level: AuraLevel.solar,
            iconTone: topic?.color,
            value: _topicId,
            options: repository.topics.map((topic) => topic.id).toList(),
            label: (id) => repository.topicById(id)?.title ?? '',
            onSelected: (value) => setState(() => _topicId = value),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final current = _dueDate ?? DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(current.year - 5),
      lastDate: DateTime(current.year + 5),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
    );
    if (!mounted) return;

    setState(
      () => _dueDate = DateTime(
        date.year,
        date.month,
        date.day,
        time?.hour ?? current.hour,
        time?.minute ?? current.minute,
      ),
    );
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    if (title.isEmpty) return;

    // A reminder set for a moment already gone would never be able to remind
    // anyone of anything, so it is refused rather than quietly saved.
    final dueDate = _dueDate;
    if (dueDate != null && !dueDate.isAfter(DateTime.now())) {
      await showAuraAlert(
        context,
        title: 'That moment has passed',
        message: 'Pick a date and time still ahead of you.',
        level: AuraLevel.root,
      );
      return;
    }

    if (!mounted) return;
    final navigator = Navigator.of(context);
    final repository = RepositoryScope.remindersOf(context);
    final reminder = widget.reminder ?? repository.draftReminder(_topicId);

    await repository.saveReminder(
      reminder.copyWith(
        title: title,
        notes: _notes.text,
        dueDate: dueDate,
        clearDueDate: dueDate == null,
        isFlagged: _isFlagged,
        priority: _priority,
        clearPriority: _priority == null,
        remindersListId: _topicId,
      ),
    );
    navigator.maybePop();
  }
}

/// The four things the priority menu offers, "None" among them.
enum _PriorityChoice {
  none('None', null),
  high('High', Priority.high),
  medium('Medium', Priority.medium),
  low('Low', Priority.low);

  const _PriorityChoice(this.label, this.priority);

  final String label;
  final Priority? priority;

  static _PriorityChoice of(Priority? priority) {
    for (final choice in _PriorityChoice.values) {
      if (choice.priority == priority) return choice;
    }
    return _PriorityChoice.none;
  }
}

/// The form behind a topic: a name, wearing the colour being picked below it,
/// so the picker shows its effect where the user is looking.
class TopicFormScreen extends StatefulWidget {
  const TopicFormScreen({super.key, this.topic, this.screenTitle});

  /// The topic being edited, or `null` for one that does not exist yet.
  final RemindersList? topic;
  final String? screenTitle;

  @override
  State<TopicFormScreen> createState() => _TopicFormScreenState();
}

class _TopicFormScreenState extends State<TopicFormScreen> {
  late Color _color = widget.topic?.color ?? const Color(0xFF4A99EF);
  late final _controller = TextEditingController(
    text: widget.topic?.title ?? '',
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => KarmicFormShell(
    title: widget.screenTitle ?? (widget.topic == null ? 'New' : 'Edit'),
    tone: AppColors.of(context).clarity,
    onSave: _save,
    child: ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      children: [
        KarmicFormCard(
          level: AuraLevel.solar,
          child: TextField(
            controller: _controller,
            maxLines: null,
            textAlign: TextAlign.center,
            cursorColor: AppColors.of(context).clarity,
            style: TextStyle(
              fontFamily: 'Source Serif 4',
              fontSize: 20,
              color: _color,
            ),
            decoration: InputDecoration(
              hintText: 'New topic',
              hintStyle: TextStyle(
                fontFamily: 'Source Serif 4',
                color: AppColors.of(context).textSecondary,
              ),
              border: InputBorder.none,
            ),
          ),
        ),
        const SizedBox(height: 20),
        ColorPickerRow(
          level: AuraLevel.solar,
          color: _color,
          onChanged: (color) => setState(() => _color = color),
        ),
      ],
    ),
  );

  Future<void> _save() async {
    final title = _controller.text.trim();
    if (title.isEmpty) return;

    final navigator = Navigator.of(context);
    final repository = RepositoryScope.remindersOf(context);
    final topic = widget.topic ?? repository.draftTopic(_color);

    await repository.saveTopic(topic.copyWith(title: title, color: _color));
    navigator.maybePop();
  }
}
