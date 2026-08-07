import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/design_constants.dart';
import '../../widgets/aura_widgets.dart';
import '../../widgets/bottom_bar.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/scroll_blur.dart';
import '../../widgets/sf_symbols.dart';
import 'request_forms.dart';

class RequestDetailScreen extends StatelessWidget {
  const RequestDetailScreen({
    super.key,
    this.title = 'Personal Request',
    this.color = const Color(0xFF4A99EF),
  });

  final String title;
  final Color color;

  static const _items = [
    _Subrequest('Groceries', notes: 'Milk\nEggs\nApples\nOatmeal\nSpinach'),
    _Subrequest('Haircut'),
    _Subrequest('Doctor appointment', notes: 'Ask about diet'),
    _Subrequest('Take a walk', completed: true),
    _Subrequest('Buy concert tickets'),
  ];

  @override
  Widget build(BuildContext context) => ScrollBlur(
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
          icon: const AuraIcon(SFSymbols.chevronLeft, level: AuraLevel.sacral),
        ),
      ),
      bottomNavigationBar: KarmicBottomBar(
        child: Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const SubrequestFormScreen(),
              ),
            ),
            icon: ToneIcon(SFSymbols.plus, tone: color),
            label: Text(
              'Add Subrequest',
              style: TextStyle(color: color, fontSize: 17),
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
                  _RequestHeader(title: title, color: color),
                  const SizedBox(height: 20),
                  for (final item in _items) ...[
                    _SubrequestRow(item: item, color: color),
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

class _RequestHeader extends StatelessWidget {
  const _RequestHeader({required this.title, required this.color});

  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      AuraLabel('Request', tone: color),
      const SizedBox(height: 4),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Opacity(opacity: .5, child: ToneIcon(SFSymbols.circle, tone: color)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontFamily: 'Source Serif 4',
                fontSize: 20,
                color: color,
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 4),
      Text(
        'Fulfil every subrequest first',
        style: TextStyle(
          color: AppColors.of(context).textSecondary,
          fontSize: 15,
        ),
      ),
    ],
  );
}

class _SubrequestRow extends StatelessWidget {
  const _SubrequestRow({required this.item, required this.color});

  final _Subrequest item;
  final Color color;

  @override
  Widget build(BuildContext context) => AuraCard(
    level: AuraLevel.sacral,
    tone: color,
    watermark: false,
    elevated: false,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ToneIcon(
          item.completed ? SFSymbols.checkmarkCircle : SFSymbols.circle,
          tone: color,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.title,
                style: TextStyle(
                  color: item.completed
                      ? AppColors.of(context).textSecondary
                      : AppColors.of(context).textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                  decoration: item.completed
                      ? TextDecoration.lineThrough
                      : null,
                ),
              ),
              if (item.notes.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  item.notes,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.of(context).textSecondary,
                    fontSize: 15,
                    height: 1.25,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 8),
        ToneIcon(SFSymbols.infoCircle, tone: color),
      ],
    ),
  );
}

class _Subrequest {
  const _Subrequest(this.title, {this.notes = '', this.completed = false});

  final String title;
  final String notes;
  final bool completed;
}
