import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../l10n/app_localizations.dart';
import 'aura_widgets.dart';
import 'karmic_form.dart';

/// The colour a request or a topic wears.
///
/// One swatch, wearing the colour it stands for: tapping it opens the whole
/// spectrum, the same as the Swift app's system picker does.
class ColorPickerRow extends StatelessWidget {
  const ColorPickerRow({
    super.key,
    required this.level,
    required this.color,
    required this.onChanged,
  });

  final AuraLevel level;
  final Color color;
  final ValueChanged<Color> onChanged;

  @override
  Widget build(BuildContext context) => KarmicFormCard(
    level: level,
    child: Row(
      children: [
        Expanded(
          child: Text(
            AppLocalizations.of(context).color,
            style: TextStyle(
              color: AppColors.of(context).textPrimary,
              fontSize: 17,
            ),
          ),
        ),
        _Swatch(color: color, onTap: () => _pick(context)),
      ],
    ),
  );

  Future<void> _pick(BuildContext context) async {
    final picked = await showColorPickerDialog(
      context,
      initial: color,
      level: level,
    );
    if (picked != null) onChanged(picked);
  }
}

/// The circle standing for the chosen colour, and the way into the picker.
class _Swatch extends StatelessWidget {
  const _Swatch({required this.color, this.onTap});

  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 28,
      height: 28,
      margin: const EdgeInsets.only(left: 8),
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: .2), blurRadius: 2),
        ],
      ),
    ),
  );
}

/// The whole spectrum on a wheel, in the app's own card. Returns the chosen
/// colour, or `null` if the sheet was dismissed.
Future<Color?> showColorPickerDialog(
  BuildContext context, {
  required Color initial,
  AuraLevel level = AuraLevel.throat,
}) => showDialog<Color>(
  context: context,
  barrierColor: Colors.black.withValues(alpha: .3),
  builder: (context) => Dialog(
    backgroundColor: Colors.transparent,
    elevation: 0,
    insetPadding: const EdgeInsets.all(16),
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 480),
      child: _ColorPickerDialog(initial: initial, level: level),
    ),
  ),
);

class _ColorPickerDialog extends StatefulWidget {
  const _ColorPickerDialog({required this.initial, required this.level});

  final Color initial;
  final AuraLevel level;

  @override
  State<_ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<_ColorPickerDialog> {
  late Color _color = widget.initial;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context);

    return AuraCard(
      level: widget.level,
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.color,
            style: TextStyle(
              fontFamily: 'Source Serif 4',
              fontSize: 20,
              color: colors.textPrimary,
            ),
          ),
          // The wheel alone: the palettes the package can also show are the
          // presets this row deliberately does without.
          ColorPicker(
            color: _color,
            onColorChanged: (color) => setState(() => _color = color),
            pickersEnabled: const {
              ColorPickerType.wheel: true,
              ColorPickerType.primary: false,
              ColorPickerType.accent: false,
            },
            enableShadesSelection: false,
            wheelDiameter: 220,
            wheelWidth: 22,
            wheelSquarePadding: 6,
            padding: const EdgeInsets.symmetric(vertical: 16),
            columnSpacing: 16,
            showColorCode: true,
            colorCodeHasColor: true,
            colorCodeTextStyle: TextStyle(color: colors.textPrimary),
            enableTooltips: false,
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: AuraButton(
              label: l10n.done,
              level: widget.level,
              onPressed: () =>
                  Navigator.of(context).pop(_color.withValues(alpha: 1)),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: AuraButton(
              label: l10n.cancel,
              level: widget.level,
              prominence: AuraProminence.quiet,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }
}
