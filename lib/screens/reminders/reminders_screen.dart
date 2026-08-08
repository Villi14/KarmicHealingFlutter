import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/design_constants.dart';
import '../../data/models.dart';
import '../../data/reminders_repository.dart';
import '../../data/repository_scope.dart';
import '../../l10n/app_localizations.dart';
import '../../data/seed_sample_data.dart';
import '../../widgets/aura_widgets.dart';
import '../../widgets/bottom_bar.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/grid_cell.dart';
import '../../widgets/karmic_empty_state.dart';
import '../../widgets/karmic_search_bar.dart';
import '../../widgets/list_row.dart';
import '../../widgets/scroll_blur.dart';
import '../../widgets/sf_symbols.dart';
import 'reminder_forms.dart';
import 'reminder_row.dart';
import 'reminders_detail_screen.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  final _searchController = TextEditingController();

  bool _showCompletedInSearch = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String get _query => _searchController.text.trim();

  @override
  Widget build(BuildContext context) {
    final repository = RepositoryScope.remindersOf(context);

    return ScrollBlur(
      child: Scaffold(
        extendBodyBehindAppBar: true,
        extendBody: true,
        appBar: AppBar(
          flexibleSpace: const ScrollBlurBackdrop(),
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          shadowColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          title: Text(AppLocalizations.of(context).reminders),
          leading: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const AuraIcon(SFSymbols.chevronLeft, level: AuraLevel.solar),
          ),
          actions: [
            if (kDebugMode)
              IconButton(
                onPressed: () => seedSampleData(
                  RepositoryScope.requestsOf(context),
                  repository,
                ),
                icon: const AuraIcon(
                  SFSymbols.ellipsis,
                  level: AuraLevel.solar,
                ),
              ),
          ],
        ),
        bottomNavigationBar: KarmicBottomBar(
          child: ListenableBuilder(
            listenable: repository,
            builder: (context, _) => Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // A reminder has to land in a topic, so it is only offered once
                // there is one to land in.
                if (!repository.isEmpty)
                  _BottomAction(
                    label: AppLocalizations.of(context).reminder,
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => ReminderFormScreen(
                          topicId: repository.topics.first.id,
                        ),
                      ),
                    ),
                  )
                else
                  const SizedBox.shrink(),
                _BottomAction(
                  label: AppLocalizations.of(context).list,
                  onPressed: () => _openTopicForm(context),
                ),
              ],
            ),
          ),
        ),
        body: GradientBackground(
          tone: AppColors.of(context).clarity,
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
                      onChanged: (_) => setState(() {
                        if (_query.isEmpty) _showCompletedInSearch = false;
                      }),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListenableBuilder(
                        listenable: repository,
                        builder: (context, _) => _body(context, repository),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _body(BuildContext context, RemindersRepository repository) {
    if (_query.isNotEmpty) return _searchResults(context, repository);
    if (repository.isEmpty) return _emptyState(context);
    return _topics(context, repository);
  }

  EdgeInsets get _listPadding => EdgeInsets.fromLTRB(
    DesignConstants.padding,
    DesignConstants.padding,
    DesignConstants.padding,
    DesignConstants.bottomBarInset(context) + DesignConstants.paddingXLarge,
  );

  Widget _emptyState(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(8, 0, 8, 24),
    children: [
      KarmicEmptyState(
        icon: const AuraIcon.drawn(
          SFGlyph.leaf,
          level: AuraLevel.solar,
          size: 33,
        ),
        title: AppLocalizations.of(context).remindersEmptyTitle,
        message: AppLocalizations.of(context).remindersEmptyMessage,
        level: AuraLevel.solar,
        actionTitle: AppLocalizations.of(context).addList,
        onAction: () => _openTopicForm(context),
      ),
    ],
  );

  Widget _topics(BuildContext context, RemindersRepository repository) =>
      ListView(
        padding: _listPadding,
        children: [
          _StatsGrid(stats: repository.stats),
          const SizedBox(height: 20),
          Text(
            AppLocalizations.of(context).myReminders,
            style: TextStyle(
              fontFamily: 'Source Serif 4',
              fontSize: 20,
              color: AppColors.of(context).textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          // A list here is a topic, so the header says out loud what the rows
          // below are.
          Text(
            AppLocalizations.of(context).topicsHint,
            style: TextStyle(
              color: AppColors.of(context).textSecondary,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 8),
          for (final topic in repository.topics) ...[
            SwipeToDelete(
              id: topic.id,
              onDelete: () => repository.deleteTopic(topic.id),
              child: ListRow(
                title: topic.title,
                tone: topic.color,
                count: repository.openCountOf(topic.id),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => RemindersDetailScreen(topicId: topic.id),
                  ),
                ),
                onInfo: () => _openTopicForm(context, topic: topic),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ],
      );

  Widget _searchResults(BuildContext context, RemindersRepository repository) {
    final results = repository.search(
      _query,
      showCompleted: _showCompletedInSearch,
    );

    return ListView(
      padding: _listPadding,
      children: [
        _SearchTally(
          completedCount: results.completedCount,
          showsCompleted: _showCompletedInSearch,
          tone: AppColors.of(context).clarity,
          onToggleCompleted: () =>
              setState(() => _showCompletedInSearch = !_showCompletedInSearch),
          onClear: (monthsAgo) =>
              repository.deleteCompletedMatching(_query, monthsAgo: monthsAgo),
        ),
        const SizedBox(height: 8),
        if (results.reminders.isEmpty)
          KarmicEmptyState(
            icon: const AuraIcon(
              SFSymbols.magnifyingglass,
              level: AuraLevel.solar,
              size: 33,
            ),
            title: AppLocalizations.of(context).noResults,
            message: AppLocalizations.of(context).tryAnotherSearch,
            level: AuraLevel.solar,
          )
        else
          for (final reminder in results.reminders) ...[
            ReminderRow(
              reminder: reminder,
              topic: repository.topicById(reminder.remindersListId)!,
              showsTopic: true,
            ),
            const SizedBox(height: 8),
          ],
      ],
    );
  }

  Future<void> _openTopicForm(BuildContext context, {RemindersList? topic}) =>
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => TopicFormScreen(topic: topic)),
      );
}

/// The five cells that cut across topics: what is due today, what is scheduled
/// at all, everything open, what is flagged, and what is done.
class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.stats});

  final ReminderStats stats;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      _row(
        GridCell(
          title: AppLocalizations.of(context).today,
          icon: SFSymbols.calendar,
          level: AuraLevel.solar,
          count: stats.todayCount,
          onTap: () => _open(context, RemindersDetailType.today),
        ),
        GridCell(
          title: AppLocalizations.of(context).scheduled,
          icon: SFSymbols.calendar,
          level: AuraLevel.root,
          count: stats.scheduledCount,
          onTap: () => _open(context, RemindersDetailType.scheduled),
        ),
      ),
      const SizedBox(height: 8),
      _row(
        GridCell(
          title: AppLocalizations.of(context).all,
          icon: SFSymbols.tray,
          level: AuraLevel.throat,
          count: stats.allCount,
          onTap: () => _open(context, RemindersDetailType.all),
        ),
        GridCell(
          title: AppLocalizations.of(context).flagged,
          icon: SFSymbols.flag,
          level: AuraLevel.sacral,
          count: stats.flaggedCount,
          onTap: () => _open(context, RemindersDetailType.flagged),
        ),
      ),
      const SizedBox(height: 8),
      _row(
        GridCell(
          title: AppLocalizations.of(context).completed,
          icon: SFSymbols.checkmark,
          level: AuraLevel.heart,
          onTap: () => _open(context, RemindersDetailType.completed),
        ),
        null,
      ),
    ],
  );

  void _open(BuildContext context, RemindersDetailType type) =>
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => RemindersDetailScreen(type: type),
        ),
      );

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

/// How many fulfilled matches a search turned up, and what can be done with
/// them. Unlike a request, a reminder carries a date, so clearing can be asked
/// to spare the recent ones.
class _SearchTally extends StatelessWidget {
  const _SearchTally({
    required this.completedCount,
    required this.showsCompleted,
    required this.tone,
    required this.onToggleCompleted,
    required this.onClear,
  });

  final int completedCount;
  final bool showsCompleted;
  final Color tone;
  final VoidCallback onToggleCompleted;
  final void Function(int? monthsAgo) onClear;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Text(
        AppLocalizations.of(context).completedTally(completedCount),
        style: TextStyle(
          color: AppColors.of(context).textSecondary,
          fontSize: 15,
        ),
      ),
      if (completedCount > 0) ...[
        const SizedBox(width: 8),
        PopupMenuButton<int?>(
          onSelected: (months) => onClear(months == 0 ? null : months),
          color: AppColors.of(context).backgroundSecondary,
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 1,
              child: Text(AppLocalizations.of(context).olderThan1Month),
            ),
            PopupMenuItem(
              value: 6,
              child: Text(AppLocalizations.of(context).olderThan6Months),
            ),
            PopupMenuItem(
              value: 12,
              child: Text(AppLocalizations.of(context).olderThan1Year),
            ),
            PopupMenuItem(
              value: 0,
              child: Text(AppLocalizations.of(context).allCompleted),
            ),
          ],
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Text(
              AppLocalizations.of(context).clear,
              style: TextStyle(color: tone),
            ),
          ),
        ),
        const Spacer(),
        TextButton(
          onPressed: onToggleCompleted,
          child: Text(
            showsCompleted
                ? AppLocalizations.of(context).hide
                : AppLocalizations.of(context).show,
            style: TextStyle(color: tone),
          ),
        ),
      ],
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
      style: TextStyle(color: AppColors.of(context).clarity, fontSize: 17),
    ),
  );
}
