import 'package:flutter/material.dart';

import 'aura_widgets.dart';

class DisclosureCell extends StatelessWidget {
  const DisclosureCell({super.key, required this.title, required this.onTap});

  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 56),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            const AuraRings(
              level: AuraLevel.throat,
              size: 18,
              count: 2,
              opacity: 1,
            ),
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
            const AuraIcon(
              Icons.chevron_right,
              level: AuraLevel.throat,
              size: 18,
            ),
          ],
        ),
      ),
    ),
  );
}
