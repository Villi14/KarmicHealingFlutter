import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import 'aura_widgets.dart';
import 'karmic_form.dart';

/// The colour a request or a topic wears, picked from a handful.
///
/// The Swift app opens the system colour picker here; a row of swatches says
/// the same thing in a form that is already on screen, and keeps every colour
/// legible against both appearances.
class ColorPickerRow extends StatelessWidget {
  const ColorPickerRow({
    super.key,
    required this.level,
    required this.color,
    required this.onChanged,
    this.title = 'Color',
  });

  final AuraLevel level;
  final Color color;
  final ValueChanged<Color> onChanged;
  final String title;

  /// The two in the middle come from the spectrum, so they follow the
  /// appearance.
  static List<Color> palette(BuildContext context) {
    final colors = AppColors.of(context);
    return [
      const Color(0xFF4A99EF),
      colors.friendly,
      colors.health,
      const Color(0xFFB25DD3),
    ];
  }

  @override
  Widget build(BuildContext context) => KarmicFormCard(
    level: level,
    child: Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: AppColors.of(context).textPrimary,
              fontSize: 17,
            ),
          ),
        ),
        for (final swatch in palette(context))
          GestureDetector(
            onTap: () => onChanged(swatch),
            child: Container(
              width: 28,
              height: 28,
              margin: const EdgeInsets.only(left: 8),
              decoration: BoxDecoration(
                color: swatch,
                shape: BoxShape.circle,
                border: Border.all(
                  color: swatch == color
                      ? AppColors.of(context).textPrimary
                      : Colors.white,
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .2),
                    blurRadius: 2,
                  ),
                ],
              ),
            ),
          ),
      ],
    ),
  );
}
