import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../constants/app_colors.dart';
import '../../constants/design_constants.dart';
import '../../widgets/aura_widgets.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/karmic_empty_state.dart';
import '../../widgets/karmic_search_bar.dart';
import '../../widgets/list_row.dart';
import '../../widgets/scroll_blur.dart';
import '../../widgets/sf_symbols.dart';
import 'request_detail_screen.dart';
import 'request_forms.dart';
import 'requests_help_screen.dart';

class RequestsScreen extends StatefulWidget {
  const RequestsScreen({super.key, this.showSamples = false});

  final bool showSamples;

  @override
  State<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen> {
  final _searchController = TextEditingController();

  static const _sampleGroups = [
    RequestGroup('Personal Request', Color(0xFF4A99EF), 5),
    RequestGroup('Family Request', Color(0xFFED8935), 3),
    RequestGroup('Business Request', Color(0xFFB25DD3), 3),
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
        title: const Text('Requests'),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const AuraIcon(SFSymbols.chevronLeft, level: AuraLevel.sacral),
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
              onPressed: () {},
              icon: const AuraIcon(SFSymbols.ellipsis, level: AuraLevel.sacral),
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
                    builder: (_) => const RequestFormScreen(),
                  ),
                ),
                icon: const AuraIcon(
                  SFSymbols.plus,
                  level: AuraLevel.sacral,
                  size: 20,
                ),
                label: const Text(
                  'Request',
                  style: TextStyle(color: AppColors.friendly, fontSize: 17),
                ),
              ),
            ),
          ),
        ),
      ),
      body: GradientBackground(
        tone: AppColors.friendly,
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
                        ? _buildGroups()
                        : const _RequestsEmptyState(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );

  Widget _buildGroups() => ListView(
    padding: const EdgeInsets.fromLTRB(
      DesignConstants.padding,
      DesignConstants.padding,
      DesignConstants.padding,
      DesignConstants.paddingXLarge,
    ),
    children: [
      const Text(
        'My requests',
        style: TextStyle(
          fontFamily: 'Source Serif 4',
          fontSize: 20,
          color: AppColors.textPrimary,
        ),
      ),
      const SizedBox(height: 8),
      const Text(
        'Every subrequest belongs to a request',
        style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
      ),
      const SizedBox(height: 8),
      for (final group in _filteredGroups) ...[
        ListRow(
          title: group.title,
          tone: group.color,
          count: group.count,
          showsCompletion: true,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) =>
                  RequestDetailScreen(title: group.title, color: group.color),
            ),
          ),
          onInfo: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const RequestFormScreen()),
          ),
        ),
        const SizedBox(height: 8),
      ],
    ],
  );

  List<RequestGroup> get _filteredGroups {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _sampleGroups;
    return _sampleGroups
        .where((group) => group.title.toLowerCase().contains(query))
        .toList();
  }
}

class _RequestsEmptyState extends StatelessWidget {
  const _RequestsEmptyState();

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(8, 0, 8, 24),
    children: [
      KarmicEmptyState(
        icon: const AuraIcon.drawn(
          SFGlyph.leaf,
          level: AuraLevel.sacral,
          size: 33,
        ),
        title: 'Start with a request',
        message:
            'Write down what you are asking for. If it cannot be fulfilled right away, break it into subrequests.',
        level: AuraLevel.sacral,
        actionTitle: 'Add Request',
        onAction: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const RequestFormScreen()),
        ),
      ),
    ],
  );
}

class RequestGroup {
  const RequestGroup(this.title, this.color, this.count);

  final String title;
  final Color color;
  final int count;
}
