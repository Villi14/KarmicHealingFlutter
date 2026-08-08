import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/design_constants.dart';
import '../../data/models.dart';
import '../../data/repository_scope.dart';
import '../../l10n/app_localizations.dart';
import '../../data/requests_repository.dart';
import '../../data/seed_sample_data.dart';
import '../../widgets/aura_widgets.dart';
import '../../widgets/bottom_bar.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/karmic_empty_state.dart';
import '../../widgets/karmic_search_bar.dart';
import '../../widgets/list_row.dart';
import '../../widgets/scroll_blur.dart';
import '../../widgets/sf_symbols.dart';
import 'request_detail_screen.dart';
import 'request_forms.dart';
import 'requests_help_screen.dart';
import 'subrequest_row.dart';

class RequestsScreen extends StatefulWidget {
  const RequestsScreen({super.key});

  @override
  State<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen> {
  final _searchController = TextEditingController();

  /// Search hides what is fulfilled on both levels; this is the tally's offer
  /// to bring it back, and it lasts only as long as the search does.
  bool _showCompletedInSearch = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String get _query => _searchController.text.trim();

  @override
  Widget build(BuildContext context) {
    final repository = RepositoryScope.requestsOf(context);

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
          title: Text(AppLocalizations.of(context).requests),
          leading: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const AuraIcon(
              SFSymbols.chevronLeft,
              level: AuraLevel.sacral,
            ),
          ),
          actions: [
            IconButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const RequestsHelpScreen(),
                  fullscreenDialog: true,
                ),
              ),
              icon: const AuraIcon(
                SFSymbols.questionmarkCircle,
                level: AuraLevel.sacral,
              ),
            ),
            if (kDebugMode)
              IconButton(
                onPressed: () => seedSampleData(
                  repository,
                  RepositoryScope.remindersOf(context),
                ),
                icon: const AuraIcon(
                  SFSymbols.ellipsis,
                  level: AuraLevel.sacral,
                ),
              ),
          ],
        ),
        bottomNavigationBar: KarmicBottomBar(
          child: Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => _openRequestForm(context),
              icon: const AuraIcon(
                SFSymbols.plus,
                level: AuraLevel.sacral,
                size: 20,
              ),
              label: Text(
                AppLocalizations.of(context).request,
                style: TextStyle(
                  color: AppColors.of(context).friendly,
                  fontSize: 17,
                ),
              ),
            ),
          ),
        ),
        body: GradientBackground(
          tone: AppColors.of(context).friendly,
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

  Widget _body(BuildContext context, RequestsRepository repository) {
    if (_query.isNotEmpty) return _searchResults(context, repository);
    if (repository.isEmpty) return _emptyState(context);
    return _requests(context, repository);
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
        icon: const AuraIcon(
          SFSymbols.sparkles,
          level: AuraLevel.sacral,
          size: 33,
        ),
        title: AppLocalizations.of(context).requestsEmptyTitle,
        message: AppLocalizations.of(context).requestsEmptyMessage,
        level: AuraLevel.sacral,
        actionTitle: AppLocalizations.of(context).addRequest,
        onAction: () => _openRequestForm(context),
      ),
    ],
  );

  Widget _requests(BuildContext context, RequestsRepository repository) =>
      ListView(
        padding: _listPadding,
        children: [
          Text(
            AppLocalizations.of(context).myRequests,
            style: TextStyle(
              fontFamily: 'Source Serif 4',
              fontSize: 20,
              color: AppColors.of(context).textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          // The rows are requests; what hangs under them is the second level.
          Text(
            AppLocalizations.of(context).subrequestsHint,
            style: TextStyle(
              color: AppColors.of(context).textSecondary,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 8),
          for (final request in repository.requests) ...[
            _requestRow(context, repository, request),
            const SizedBox(height: 8),
          ],
        ],
      );

  Widget _requestRow(
    BuildContext context,
    RequestsRepository repository,
    RequestsList request,
  ) => SwipeToDelete(
    id: request.id,
    onDelete: () => repository.deleteRequest(request.id),
    child: ListRow(
      title: request.title,
      tone: request.color,
      count: repository.subrequestsOf(request.id).length,
      isCompleted: request.isCompleted,
      showsCompletion: true,
      canToggle: repository.canToggleCompletion(request),
      onToggle: () => repository.toggleRequestCompletion(request.id),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => RequestDetailScreen(requestId: request.id),
        ),
      ),
      onInfo: () => _openRequestForm(context, request: request),
    ),
  );

  Widget _searchResults(BuildContext context, RequestsRepository repository) {
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
          tone: AppColors.of(context).friendly,
          onToggleCompleted: () =>
              setState(() => _showCompletedInSearch = !_showCompletedInSearch),
          onClear: () => repository.deleteCompletedMatching(_query),
        ),
        const SizedBox(height: 8),
        if (!results.hasResults)
          KarmicEmptyState(
            icon: const AuraIcon(
              SFSymbols.magnifyingglass,
              level: AuraLevel.sacral,
              size: 33,
            ),
            title: AppLocalizations.of(context).noResults,
            message: AppLocalizations.of(context).tryAnotherSearch,
            level: AuraLevel.sacral,
          )
        else ...[
          if (results.requests.isNotEmpty) ...[
            _sectionHeader(context, AppLocalizations.of(context).request),
            for (final request in results.requests) ...[
              _requestRow(context, repository, request),
              const SizedBox(height: 8),
            ],
          ],
          if (results.subrequests.isNotEmpty) ...[
            _sectionHeader(context, AppLocalizations.of(context).subRequest),
            for (final subrequest in results.subrequests) ...[
              SubrequestRow(
                subrequest: subrequest,
                // A subrequest found in search stands beside rows from other
                // requests, so it names the one it serves.
                request: repository.requestById(subrequest.requestsListId)!,
                showsRequest: true,
              ),
              const SizedBox(height: 8),
            ],
          ],
        ],
      ],
    );
  }

  Widget _sectionHeader(BuildContext context, String title) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      title,
      style: TextStyle(
        color: AppColors.of(context).textSecondary,
        fontSize: 15,
      ),
    ),
  );

  Future<void> _openRequestForm(
    BuildContext context, {
    RequestsList? request,
  }) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => RequestFormScreen(request: request),
    ),
  );
}

/// How many fulfilled matches a search turned up, and what can be done with
/// them.
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
  final VoidCallback onClear;

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
        TextButton(
          onPressed: onClear,
          child: Text(
            AppLocalizations.of(context).clear,
            style: TextStyle(color: tone),
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
