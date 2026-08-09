import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../l10n/app_localizations.dart';
import 'aura_widgets.dart';
import 'karmic_form.dart';

/// The colour a request or a topic wears.
///
/// The handful of swatches are the quick answer; the last one opens the whole
/// spectrum, so any colour the Swift app's system picker can reach can be
/// picked here too.
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
  Widget build(BuildContext context) {
    final swatches = palette(context);
    final custom = !swatches.contains(color);

    return KarmicFormCard(
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
          for (final swatch in swatches)
            _Swatch(
              color: swatch,
              selected: swatch == color,
              onTap: () => onChanged(swatch),
            ),
          _Swatch(
            color: custom ? color : null,
            selected: custom,
            onTap: () => _pickFreely(context),
          ),
        ],
      ),
    );
  }

  Future<void> _pickFreely(BuildContext context) async {
    final picked = await showColorPickerDialog(
      context,
      initial: color,
      level: level,
    );
    if (picked != null) onChanged(picked);
  }
}

/// One circle in the row. A swatch with no colour of its own wears the whole
/// spectrum: it is the way into the picker rather than a colour to pick.
class _Swatch extends StatelessWidget {
  const _Swatch({required this.color, required this.selected, this.onTap});

  final Color? color;
  final bool selected;
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
        gradient: color == null ? _spectrum : null,
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? AppColors.of(context).textPrimary : Colors.white,
          width: 3,
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: .2), blurRadius: 2),
        ],
      ),
    ),
  );

  static final _spectrum = SweepGradient(
    colors: [
      for (var hue = 0; hue <= 360; hue += 30)
        HSVColor.fromAHSV(1, hue % 360, .85, .95).toColor(),
    ],
  );
}

/// The whole spectrum on three bars: which colour, how much of it, and how
/// bright. Returns the chosen colour, or `null` if the sheet was dismissed.
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
  late HSVColor _color = HSVColor.fromColor(widget.initial);

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final hue = HSVColor.fromAHSV(1, _color.hue, 1, 1).toColor();

    return AuraCard(
      level: widget.level,
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            AppLocalizations.of(context).color,
            style: TextStyle(
              fontFamily: 'Source Serif 4',
              fontSize: 20,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: _color.toColor(),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .2),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _Bar(
            key: const Key('hue'),
            value: _color.hue / 360,
            colors: [
              for (var step = 0; step <= 360; step += 30)
                HSVColor.fromAHSV(1, step % 360, 1, 1).toColor(),
            ],
            onChanged: (value) =>
                setState(() => _color = _color.withHue(value * 360)),
          ),
          const SizedBox(height: 16),
          _Bar(
            key: const Key('saturation'),
            value: _color.saturation,
            colors: [Colors.white, hue],
            onChanged: (value) =>
                setState(() => _color = _color.withSaturation(value)),
          ),
          const SizedBox(height: 16),
          _Bar(
            key: const Key('brightness'),
            value: _color.value,
            colors: [Colors.black, hue],
            onChanged: (value) =>
                setState(() => _color = _color.withValue(value)),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: AuraButton(
              label: AppLocalizations.of(context).done,
              level: widget.level,
              onPressed: () =>
                  Navigator.of(context).pop(_color.withAlpha(1).toColor()),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: AuraButton(
              label: AppLocalizations.of(context).cancel,
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

/// One gradient bar with a thumb on it, dragged or tapped anywhere along its
/// length.
class _Bar extends StatelessWidget {
  const _Bar({
    super.key,
    required this.value,
    required this.colors,
    required this.onChanged,
  });

  final double value;
  final List<Color> colors;
  final ValueChanged<double> onChanged;

  static const _height = 28.0;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth;
      void report(Offset position) =>
          onChanged((position.dx / width).clamp(0, 1));

      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (details) => report(details.localPosition),
        onHorizontalDragStart: (details) => report(details.localPosition),
        onHorizontalDragUpdate: (details) => report(details.localPosition),
        child: SizedBox(
          height: _height,
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: colors),
                  borderRadius: BorderRadius.circular(_height / 2),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: .6),
                    width: 1,
                  ),
                ),
              ),
              Positioned(
                left: (value.clamp(0, 1) * width - _height / 2).clamp(
                  0,
                  width - _height,
                ),
                child: Container(
                  width: _height,
                  height: _height,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: .25),
                        blurRadius: 3,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
