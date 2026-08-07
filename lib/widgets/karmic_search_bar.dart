import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/design_constants.dart';
import 'aura_widgets.dart';
import 'sf_symbols.dart';

/// The search field every list screen wears: a flat card holding a glyph, the
/// field itself and a clear button that only shows once there is something to clear.
class KarmicSearchBar extends StatelessWidget {
  const KarmicSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    this.hint = 'Search',
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String hint;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(
      horizontal: DesignConstants.paddingLarge,
    ),
    child: AuraCard(
      level: AuraLevel.throat,
      watermark: false,
      padding: const EdgeInsets.all(DesignConstants.paddingMedium),
      child: Row(
        children: [
          const AuraIcon(
            SFSymbols.magnifyingglass,
            level: AuraLevel.throat,
            size: 20,
          ),
          const SizedBox(width: DesignConstants.spacingSmall),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              cursorColor: AppColors.of(context).clam,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(
                  color: AppColors.of(context).textSecondary,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            // A plain tap target rather than an IconButton: the button's 48pt
            // minimum would set the height of the whole bar.
            GestureDetector(
              onTap: () {
                controller.clear();
                onChanged('');
              },
              behavior: HitTestBehavior.opaque,
              child: const AuraIcon(
                SFSymbols.xmarkCircle,
                level: AuraLevel.throat,
                size: 20,
              ),
            ),
        ],
      ),
    ),
  );
}
