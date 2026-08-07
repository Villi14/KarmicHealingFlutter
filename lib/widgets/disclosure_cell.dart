import 'package:flutter/material.dart';

import 'aura_widgets.dart';
import 'sf_symbols.dart';

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
