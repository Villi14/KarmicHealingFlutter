import 'package:flutter/material.dart';

import '../constants/design_constants.dart';
import 'aura_widgets.dart';
import 'sf_symbols.dart';

/// A settings list: every cell in a card of its own.
///
/// The card in SwiftUI is put on the group's contents, and a modifier on a
/// several-view builder lands on each view separately — so what the iOS app
/// shows is one card per row, not one card holding the rows.
class DisclosureGroup extends StatelessWidget {
  const DisclosureGroup({
    super.key,
    required this.level,
    required this.children,
  });

  final AuraLevel level;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (final (index, child) in children.indexed) ...[
        if (index > 0) const SizedBox(height: DesignConstants.spacingSmall),
        AuraCard(level: level, padding: EdgeInsets.zero, child: child),
      ],
    ],
  );
}

class DisclosureCell extends StatelessWidget {
  const DisclosureCell({
    super.key,
    required this.title,
    required this.onTap,
    this.level = AuraLevel.throat,
  });

  final String title;
  final VoidCallback onTap;
  final AuraLevel level;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 56),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            AuraRings(level: level, size: 18, count: 2, opacity: 1),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Source Serif 4',
                  fontSize: 20,
                ),
              ),
            ),
            const SizedBox(width: 12),
            AuraIcon(SFSymbols.chevronRight, level: level, size: 18),
          ],
        ),
      ),
    ),
  );
}
