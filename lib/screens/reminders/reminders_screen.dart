import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../constants/app_colors.dart';
import '../../constants/design_constants.dart';
import '../../widgets/aura_widgets.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/grid_cell.dart';
import '../../widgets/karmic_empty_state.dart';
import '../../widgets/karmic_search_bar.dart';
import '../../widgets/list_row.dart';
import '../../widgets/scroll_blur.dart';
import '../../widgets/sf_symbols.dart';
import 'reminder_forms.dart';
import 'reminders_detail_screen.dart';

/// A topic of reminders, and how many of them are still open.
class ReminderTopic {
  const ReminderTopic(this.title, this.color, this.count);

  final String title;
  final Color color;
  final int count;
}

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key, this.showSamples = false});

  final bool showSamples;

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  final _searchController = TextEditingController();

  static const _sampleTopics = [
    ReminderTopic('Personal', Color(0xFF4A99EF), 5),
    ReminderTopic('Family', Color(0xFFED8935), 3),
    ReminderTopic('Practice', Color(0xFFB25DD3), 4),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
        title: const Text('Reminders'),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const AuraIcon(SFSymbols.chevronLeft, level: AuraLevel.solar),
        ),
        actions: [
          if (kDebugMode)
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (widget.showSamples)
                  _BottomAction(
                    label: 'Reminder',
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const ReminderFormScreen(),
                      ),
                    ),
                  )
                else
                  const SizedBox.shrink(),
                _BottomAction(
                  label: 'Topic',
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const TopicFormScreen(),
                    ),
                  ),
                ),
              ],
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
              child: Column(
                children: [
                  SizedBox(
                    height: DesignConstants.navigationBarInset(context) + 8,
                  ),
                  KarmicSearchBar(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: widget.showSamples
                        ? _buildTopics()
                        : const _RemindersEmptyState(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );

  Widget _buildTopics() => ListView(
    padding: const EdgeInsets.fromLTRB(
      DesignConstants.padding,
      DesignConstants.padding,
      DesignConstants.padding,
      DesignConstants.paddingXLarge,
    ),
    children: [
      const _StatsGrid(),
      const SizedBox(height: 20),
      const Text(
        'Reminder topics',
        style: TextStyle(
          fontFamily: 'Source Serif 4',
          fontSize: 20,
          color: AppColors.textPrimary,
        ),
      ),
      const SizedBox(height: 8),
      const Text(
        'Every reminder belongs to a topic',
        style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
      ),
      const SizedBox(height: 8),
      for (final topic in _filteredTopics) ...[
        ListRow(
          title: topic.title,
          tone: topic.color,
          count: topic.count,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) =>
                  RemindersDetailScreen(title: topic.title, color: topic.color),
            ),
          ),
          onInfo: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => TopicFormScreen(
                screenTitle: 'Edit',
                title: topic.title,
                color: topic.color,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    ],
  );

  List<ReminderTopic> get _filteredTopics {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _sampleTopics;
    return _sampleTopics
        .where((topic) => topic.title.toLowerCase().contains(query))
        .toList();
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid();

  @override
  Widget build(BuildContext context) => Column(
    children: [
      _row(
        const GridCell(
          title: 'Today',
          icon: SFSymbols.calendar,
          level: AuraLevel.solar,
          count: 3,
          onTap: _noop,
        ),
        const GridCell(
          title: 'Scheduled',
          icon: SFSymbols.calendar,
          level: AuraLevel.root,
          count: 5,
          onTap: _noop,
        ),
      ),
      const SizedBox(height: 8),
      _row(
        const GridCell(
          title: 'All',
          icon: SFSymbols.tray,
          level: AuraLevel.throat,
          count: 12,
          onTap: _noop,
        ),
        const GridCell(
          title: 'Flagged',
          icon: SFSymbols.flag,
          level: AuraLevel.sacral,
          count: 2,
          onTap: _noop,
        ),
      ),
      const SizedBox(height: 8),
      _row(
        const GridCell(
          title: 'Completed',
          icon: SFSymbols.checkmark,
          level: AuraLevel.heart,
          onTap: _noop,
        ),
        null,
      ),
    ],
  );

  static void _noop() {}

  Widget _row(Widget first, Widget? second) => SizedBox(
    height: 78,
    child: Row(
      children: [
        Expanded(child: first),
        const SizedBox(width: 8),
        Expanded(child: second ?? const SizedBox.shrink()),
      ],
    ),
  );
}

class _RemindersEmptyState extends StatelessWidget {
  const _RemindersEmptyState();

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(8, 0, 8, 24),
    children: [
      KarmicEmptyState(
        icon: const AuraIcon.drawn(
          SFGlyph.leaf,
          level: AuraLevel.solar,
          size: 33,
        ),
        title: 'Create your first topic',
        message:
            'Reminders live in topics. Create one, and small reminders will turn the practice into a steady ritual.',
        level: AuraLevel.solar,
        actionTitle: 'Add Topic',
        onAction: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const TopicFormScreen()),
        ),
      ),
    ],
  );
}

class _BottomAction extends StatelessWidget {
  const _BottomAction({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => TextButton.icon(
    onPressed: onPressed,
    icon: const AuraIcon(SFSymbols.plus, level: AuraLevel.solar, size: 20),
    label: Text(
      label,
      style: const TextStyle(color: AppColors.clarity, fontSize: 17),
    ),
  );
}
