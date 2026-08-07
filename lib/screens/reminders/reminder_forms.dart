import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../widgets/aura_widgets.dart';
import '../../widgets/karmic_form.dart';
import '../../widgets/sf_symbols.dart';

/// The form behind a reminder: what it says, when it is due, and how loudly
/// it asks to be seen.
class ReminderFormScreen extends StatefulWidget {
  const ReminderFormScreen({
    super.key,
    this.screenTitle = 'New',
    this.topicColor = const Color(0xFF4A99EF),
  });

  final String screenTitle;
  final Color topicColor;

  @override
  State<ReminderFormScreen> createState() => _ReminderFormScreenState();
}

class _ReminderFormScreenState extends State<ReminderFormScreen> {
  static const _priorities = ['None', 'High', 'Medium', 'Low'];
  static const _topics = ['Personal', 'Family', 'Practice'];

  bool _hasDate = false;
  bool _isFlagged = false;
  String _priority = 'None';
  String _topic = 'Personal';

  @override
  Widget build(BuildContext context) => KarmicFormShell(
    title: widget.screenTitle,
    tone: AppColors.clarity,
    child: ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      children: [
        const KarmicFormField(
          hint: 'Title',
          level: AuraLevel.solar,
          serif: true,
        ),
        const SizedBox(height: 20),
        const KarmicFormField(
          hint: 'Notes',
          level: AuraLevel.solar,
          minLines: 4,
        ),
        const SizedBox(height: 20),
        KarmicFormToggle(
          icon: SFSymbols.calendar,
          title: 'Date',
          level: AuraLevel.solar,
          value: _hasDate,
          onChanged: (value) => setState(() => _hasDate = value),
        ),
        if (_hasDate) ...[
          const SizedBox(height: 12),
          const KarmicFormCard(
            level: AuraLevel.solar,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Aug 7, 2026 at 8:00 PM',
                  style: TextStyle(color: AppColors.clarity, fontSize: 17),
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
        KarmicFormPicker<String>(
          icon: SFSymbols.exclamationmark,
          title: 'Priority',
          level: AuraLevel.solar,
          value: _priority,
          options: _priorities,
          label: (value) => value,
          onSelected: (value) => setState(() => _priority = value),
        ),
        const SizedBox(height: 12),
        KarmicFormPicker<String>(
          icon: SFSymbols.tag,
          title: 'Topic',
          level: AuraLevel.solar,
          iconTone: widget.topicColor,
          value: _topic,
          options: _topics,
          label: (value) => value,
          onSelected: (value) => setState(() => _topic = value),
        ),
      ],
    ),
  );
}

/// The form behind a topic: a name, wearing the colour being picked below it,
/// so the picker shows its effect where the user is looking.
class TopicFormScreen extends StatefulWidget {
  const TopicFormScreen({
    super.key,
    this.screenTitle = 'New',
    this.title = '',
    this.color = const Color(0xFF4A99EF),
  });

  final String screenTitle;
  final String title;
  final Color color;

  @override
  State<TopicFormScreen> createState() => _TopicFormScreenState();
}

class _TopicFormScreenState extends State<TopicFormScreen> {
  static const _palette = [
    Color(0xFF4A99EF),
    AppColors.friendly,
    AppColors.health,
    Color(0xFFB25DD3),
  ];

  late Color _color = widget.color;
  late final _controller = TextEditingController(text: widget.title);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => KarmicFormShell(
    title: widget.screenTitle,
    tone: AppColors.clarity,
    child: ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      children: [
        KarmicFormCard(
          level: AuraLevel.solar,
          child: TextField(
            controller: _controller,
            maxLines: null,
            textAlign: TextAlign.center,
            cursorColor: AppColors.clarity,
            style: TextStyle(
              fontFamily: 'Source Serif 4',
              fontSize: 20,
              color: _color,
            ),
            decoration: const InputDecoration(
              hintText: 'New topic',
              hintStyle: TextStyle(
                fontFamily: 'Source Serif 4',
                color: AppColors.textSecondary,
              ),
              border: InputBorder.none,
            ),
          ),
        ),
        const SizedBox(height: 20),
        KarmicFormCard(
          level: AuraLevel.solar,
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Color',
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 17),
                ),
              ),
              for (final color in _palette)
                GestureDetector(
                  onTap: () => setState(() => _color = color),
                  child: Container(
                    width: 28,
                    height: 28,
                    margin: const EdgeInsets.only(left: 8),
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: color == _color
                            ? AppColors.textPrimary
                            : Colors.white,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: .2),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    ),
  );
}
