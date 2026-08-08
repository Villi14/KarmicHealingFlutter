import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/design_constants.dart';
import '../../data/reminders_repository.dart';
import '../../data/repository_scope.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/aura_widgets.dart';
import '../../widgets/bottom_bar.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/karmic_empty_state.dart';
import '../../widgets/scroll_blur.dart';
import '../../widgets/sf_symbols.dart';
import 'reminder_forms.dart';
import 'reminder_row.dart';

/// The reminders one screen is looking at: a topic's own, or one of the five
/// cuts across every topic.
class RemindersDetailScreen extends StatefulWidget {
  const RemindersDetailScreen({
    super.key,
    this.topicId,
    this.type = RemindersDetailType.topic,
  }) : assert(
         topicId != null || type != RemindersDetailType.topic,
         'A topic screen needs a topic',
       );

  final String? topicId;
  final RemindersDetailType type;

  @override
  State<RemindersDetailScreen> createState() => _RemindersDetailScreenState();
}

class _RemindersDetailScreenState extends State<RemindersDetailScreen> {
  late bool _showCompleted = RemindersRepository.showsCompletedByDefault(
    widget.type,
  );
  RemindersOrdering _ordering = RemindersOrdering.dueDate;

  @override
  Widget build(BuildContext context) {
    final repository = RepositoryScope.remindersOf(context);

    return ListenableBuilder(
      listenable: repository,
      builder: (context, _) {
        final topic = widget.topicId == null
            ? null
            : repository.topicById(widget.topicId!);
        // The topic can be deleted from the list while its screen is open.
        if (widget.type == RemindersDetailType.topic && topic == null) {
          return const SizedBox.shrink();
        }

        final tone = topic?.color ?? _toneOf(context, widget.type);
        final reminders = repository.remindersFor(
          widget.type,
          topicId: widget.topicId,
          showCompleted: _showCompleted,
          ordering: _ordering,
        );

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
              leading: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const AuraIcon(
                  SFSymbols.chevronLeft,
                  level: AuraLevel.solar,
                ),
              ),
              actions: [_menu(context, tone)],
            ),
            bottomNavigationBar: topic == null
                ? null
                : KarmicBottomBar(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                ReminderFormScreen(topicId: topic.id),
                          ),
                        ),
                        icon: ToneIcon(SFSymbols.plus, tone: tone),
                        label: Text(
                          AppLocalizations.of(context).reminder,
                          style: TextStyle(color: tone, fontSize: 17),
                        ),
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
                    child: ListView(
                      padding: EdgeInsets.fromLTRB(
                        20,
                        DesignConstants.navigationBarInset(context) + 8,
                        20,
                        DesignConstants.bottomBarInset(context) +
                            DesignConstants.paddingXLarge,
                      ),
                      children: [
                        _Header(
                          title:
                              topic?.title ??
                              _titleOf(
                                AppLocalizations.of(context),
                                widget.type,
                              ),
                          // A topic's screen names itself as one; the mixed
                          // screens leave the eyebrow off.
                          eyebrow: topic == null
                              ? null
                              : AppLocalizations.of(context).list,
                          color: tone,
                        ),
                        const SizedBox(height: 20),
                        if (reminders.isEmpty)
                          KarmicEmptyState(
                            icon: const AuraIcon(
                              SFSymbols.bell,
                              level: AuraLevel.solar,
                              size: 33,
                            ),
                            title: AppLocalizations.of(
                              context,
                            ).remindersNothingHereTitle,
                            message: topic == null
                                ? AppLocalizations.of(
                                    context,
                                  ).remindersNoMatchesMessage
                                : AppLocalizations.of(
                                    context,
                                  ).remindersTopicEmptyMessage,
                            level: AuraLevel.solar,
                          )
                        else
                          for (final reminder in reminders) ...[
                            ReminderRow(
                              reminder: reminder,
                              topic: repository.topicById(
                                reminder.remindersListId,
                              )!,
                              tone: tone,
                              showsTopic: topic == null,
                            ),
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
      },
    );
  }

  /// How the screen is arranged, and whether it shows what is already done.
  Widget _menu(BuildContext context, Color tone) => PopupMenuButton<Object>(
    onSelected: (value) => setState(() {
      if (value is RemindersOrdering) {
        _ordering = value;
      } else {
        _showCompleted = !_showCompleted;
      }
    }),
    color: AppColors.of(context).backgroundSecondary,
    icon: ToneIcon(SFSymbols.ellipsis, tone: tone),
    itemBuilder: (context) => [
      for (final ordering in RemindersOrdering.values)
        PopupMenuItem(
          value: ordering,
          child: Row(
            children: [
              Icon(_orderingIcon(ordering), size: 18),
              const SizedBox(width: 8),
              Text(_orderingLabel(AppLocalizations.of(context), ordering)),
              if (ordering == _ordering) ...[
                const Spacer(),
                const Icon(SFSymbols.checkmark, size: 16),
              ],
            ],
          ),
        ),
      const PopupMenuDivider(),
      PopupMenuItem(
        value: 'completed',
        child: Row(
          children: [
            const Icon(SFSymbols.eye, size: 18),
            const SizedBox(width: 8),
            Text(
              _showCompleted
                  ? AppLocalizations.of(context).hideCompleted
                  : AppLocalizations.of(context).showCompleted,
            ),
          ],
        ),
      ),
    ],
  );

  static String _orderingLabel(
    AppLocalizations l10n,
    RemindersOrdering ordering,
  ) => switch (ordering) {
    RemindersOrdering.dueDate => l10n.dueDate,
    RemindersOrdering.priority => l10n.priority,
    RemindersOrdering.title => l10n.title,
  };

  static IconData _orderingIcon(RemindersOrdering ordering) =>
      switch (ordering) {
        RemindersOrdering.dueDate => SFSymbols.calendar,
        RemindersOrdering.priority => SFSymbols.chartBar,
        RemindersOrdering.title => SFSymbols.textformatCharacters,
      };

  static String _titleOf(AppLocalizations l10n, RemindersDetailType type) =>
      switch (type) {
        RemindersDetailType.all => l10n.all,
        RemindersDetailType.completed => l10n.completed,
        RemindersDetailType.flagged => l10n.flagged,
        RemindersDetailType.scheduled => l10n.scheduled,
        RemindersDetailType.today => l10n.today,
        RemindersDetailType.topic => '',
      };

  /// Each cut wears the colour of the cell it was opened from.
  static Color _toneOf(BuildContext context, RemindersDetailType type) {
    final colors = AppColors.of(context);
    return switch (type) {
      RemindersDetailType.all => colors.textPrimary,
      RemindersDetailType.completed => colors.health,
      RemindersDetailType.flagged => colors.friendly,
      RemindersDetailType.scheduled => colors.energy,
      RemindersDetailType.today => colors.clarity,
      RemindersDetailType.topic => colors.clarity,
    };
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title, required this.color, this.eyebrow});

  final String title;
  final Color color;
  final String? eyebrow;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (eyebrow != null) ...[
        AuraLabel(eyebrow!, tone: color),
        const SizedBox(height: 8),
      ],
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
