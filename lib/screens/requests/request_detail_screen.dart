import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../constants/app_colors.dart';
import '../../constants/design_constants.dart';
import '../../data/models.dart';
import '../../data/repository_scope.dart';
import '../../l10n/app_localizations.dart';
import '../../data/requests_repository.dart';
import '../../widgets/aura_widgets.dart';
import '../../widgets/bottom_bar.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/karmic_empty_state.dart';
import '../../widgets/scroll_blur.dart';
import '../../widgets/sf_symbols.dart';
import 'request_forms.dart';
import 'subrequest_row.dart';

/// Everything hanging under one request.
///
/// Subrequests keep the order they were written in, and none of them is hidden:
/// a request's own screen is where its whole shape is meant to be visible.
class RequestDetailScreen extends StatelessWidget {
  const RequestDetailScreen({super.key, required this.requestId});

  final String requestId;

  @override
  Widget build(BuildContext context) {
    final repository = RepositoryScope.requestsOf(context);

    return ListenableBuilder(
      listenable: repository,
      builder: (context, _) {
        final request = repository.requestById(requestId);
        // The request can be deleted from a search while its screen is open.
        if (request == null) return const SizedBox.shrink();
        return _build(context, repository, request);
      },
    );
  }

  Widget _build(
    BuildContext context,
    RequestsRepository repository,
    RequestsList request,
  ) {
    final subrequests = repository.subrequestsOf(request.id);

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
              level: AuraLevel.sacral,
            ),
          ),
          actions: [
            IconButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => RequestFormScreen(request: request),
                ),
              ),
              icon: ToneIcon(SFSymbols.infoCircle, tone: request.color),
            ),
          ],
        ),
        bottomNavigationBar: KarmicBottomBar(
          child: Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => _addSubrequest(context, repository, request),
              icon: ToneIcon(SFSymbols.plus, tone: request.color),
              label: Text(
                AppLocalizations.of(context).addSubRequest,
                style: TextStyle(color: request.color, fontSize: 17),
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
                child: ListView(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    DesignConstants.navigationBarInset(context) + 8,
                    20,
                    DesignConstants.bottomBarInset(context) +
                        DesignConstants.paddingXLarge,
                  ),
                  children: [
                    _RequestHeader(
                      request: request,
                      progress: repository.progressOf(request.id),
                    ),
                    const SizedBox(height: 20),
                    if (subrequests.isEmpty)
                      KarmicEmptyState(
                        icon: const AuraIcon.drawn(
                          SFGlyph.leaf,
                          level: AuraLevel.sacral,
                          size: 33,
                        ),
                        title: AppLocalizations.of(
                          context,
                        ).subrequestsEmptyTitle,
                        message: AppLocalizations.of(
                          context,
                        ).subrequestsEmptyMessage,
                        level: AuraLevel.sacral,
                        actionTitle: AppLocalizations.of(context).addSubRequest,
                        onAction: () =>
                            _addSubrequest(context, repository, request),
                      )
                    else
                      for (final subrequest in subrequests) ...[
                        SubrequestRow(subrequest: subrequest, request: request),
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

  Future<void> _addSubrequest(
    BuildContext context,
    RequestsRepository repository,
    RequestsList request,
  ) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => SubrequestFormScreen(
        subrequest: repository.draftSubrequest(request.id),
      ),
    ),
  );
}

class _RequestHeader extends StatelessWidget {
  const _RequestHeader({required this.request, required this.progress});

  final RequestsList request;
  final SubrequestProgress progress;

  @override
  Widget build(BuildContext context) {
    final repository = RepositoryScope.requestsOf(context);
    final canToggle = repository.canToggleCompletion(request);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AuraLabel(AppLocalizations.of(context).request, tone: request.color),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: canToggle
                  ? () => repository.toggleRequestCompletion(request.id)
                  : null,
              child: Opacity(
                opacity: canToggle ? 1 : .5,
                child: ToneIcon(
                  request.isCompleted
                      ? SFSymbols.checkmarkCircle
                      : SFSymbols.circle,
                  tone: request.color,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                request.title,
                style: TextStyle(
                  fontFamily: 'Source Serif 4',
                  fontSize: 20,
                  color: request.color,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          _hint(AppLocalizations.of(context)),
          style: TextStyle(
            color: AppColors.of(context).textSecondary,
            fontSize: 15,
          ),
        ),
        if (request.notes.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            request.notes,
            style: TextStyle(
              color: AppColors.of(context).textSecondary,
              fontSize: 15,
              height: 1.3,
            ),
          ),
        ],
        if (request.dueDate != null) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                SFSymbols.calendar,
                size: 12,
                color: AppColors.of(context).textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                DateFormat.yMMMd().add_jm().format(request.dueDate!),
                style: TextStyle(
                  color: AppColors.of(context).textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  /// What the request is waiting for, said plainly, so a radio button that will
  /// not move explains itself.
  String _hint(AppLocalizations l10n) {
    if (!progress.hasSubrequests) return l10n.requestReadyToBeFulfilled;
    if (progress.allCompleted) return l10n.requestEverySubrequestFulfilled;
    return '${l10n.requestLockedHint} '
        '${l10n.subrequestProgress(progress.completed, progress.total)}';
  }
}
