import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../data/models.dart';
import '../../data/repository_scope.dart';
import '../../widgets/aura_widgets.dart';
import '../../widgets/list_row.dart';
import '../../widgets/sf_symbols.dart';
import 'request_forms.dart';

/// One subrequest, wherever it stands: under its own request, or beside rows
/// from other requests in a search.
class SubrequestRow extends StatelessWidget {
  const SubrequestRow({
    super.key,
    required this.subrequest,
    required this.request,
    this.showsRequest = false,
  });

  final Subrequest subrequest;
  final RequestsList request;

  /// Screens that mix requests — search, and the All screen — name the request
  /// each subrequest serves. A request's own screen carries it in the header,
  /// so it stays quiet there.
  final bool showsRequest;

  @override
  Widget build(BuildContext context) {
    final repository = RepositoryScope.requestsOf(context);
    final colors = AppColors.of(context);
    final color = request.color;

    return SwipeToDelete(
      id: subrequest.id,
      onDelete: () => repository.deleteSubrequest(subrequest.id),
      child: AuraCard(
        level: AuraLevel.sacral,
        tone: color,
        watermark: false,
        elevated: false,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () => repository.toggleSubrequest(subrequest.id),
              child: ToneIcon(
                subrequest.isCompleted
                    ? SFSymbols.checkmarkCircle
                    : SFSymbols.circle,
                tone: color,
              ),
            ),
            const SizedBox(width: 8),
            // Everything beside the radio button opens the subrequest.
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _openForm(context),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showsRequest) ...[
                      RowBadge(
                        title: request.title,
                        tone: color,
                        icon: SFSymbols.arrowRight,
                      ),
                      const SizedBox(height: 4),
                    ],
                    Text(
                      subrequest.title,
                      style: TextStyle(
                        color: subrequest.isCompleted
                            ? colors.textSecondary
                            : colors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w500,
                        decoration: subrequest.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                        decorationColor: colors.textSecondary,
                      ),
                    ),
                    if (subrequest.notes.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        // Notes read as one line in a row; the whole of them
                        // waits in the form.
                        subrequest.notes.replaceAll('\n', ' '),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 15,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
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
      builder: (_) =>
          SubrequestFormScreen(subrequest: subrequest, screenTitle: 'Details'),
    ),
  );
}
