import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_colors.dart';
import '../constants/design_constants.dart';
import '../data/passcode.dart';
import 'aura_widgets.dart';
import 'sf_symbols.dart';

/// The app's own way of asking for a code: a row of dots and a grid of digits,
/// in place of a text field and the system keyboard.
///
/// The pad owns the digits typed into it and hands them over only once there
/// are enough of them. [onComplete] answers whether they were the right ones —
/// `false` shakes the dots empty for another try, `true` leaves them filled
/// while the screen behind moves on.
class PasscodePad extends StatefulWidget {
  const PasscodePad({
    super.key,
    required this.title,
    required this.onComplete,
    this.message,
    this.level = AuraLevel.brow,
    this.length = PasscodeStore.length,
    this.biometryIcon,
    this.isDisabled = false,
    this.onBiometry,
  });

  final String title;
  final String? message;
  final AuraLevel level;
  final int length;

  /// The glyph on the corner key that goes back to the device's own proof,
  /// shown only when there is one to go back to.
  final Widget? biometryIcon;
  final bool isDisabled;
  final VoidCallback? onBiometry;

  /// Answers a full code: `true` when it was accepted. A code is checked
  /// against a digest rather than against itself, so the answer is a future and
  /// the dots stay filled until it arrives.
  final Future<bool> Function(String code) onComplete;

  @override
  State<PasscodePad> createState() => _PasscodePadState();
}

class _PasscodePadState extends State<PasscodePad>
    with SingleTickerProviderStateMixin {
  static const _rows = [
    [1, 2, 3],
    [4, 5, 6],
    [7, 8, 9],
  ];

  String _entered = '';
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 400),
  );

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  /// Comfortably past the 48dp the guidelines ask for, and small enough that
  /// four rows still fit above the fold on a short phone.
  double _keySize(BuildContext context) =>
      DesignConstants.compact(context, 72, 62);

  void _append(int digit) {
    if (_entered.length >= widget.length) return;

    setState(() => _entered += '$digit');
    HapticFeedback.selectionClick();

    if (_entered.length < widget.length) return;

    final code = _entered;
    // A beat, so the last dot is seen filling before the screen answers.
    Future<void>.delayed(const Duration(milliseconds: 120), () async {
      if (!mounted || _entered != code) return;
      if (await widget.onComplete(code)) return;
      if (!mounted || _entered != code) return;
      _reject();
    });
  }

  void _delete() {
    if (_entered.isEmpty) return;
    setState(() => _entered = _entered.substring(0, _entered.length - 1));
    HapticFeedback.selectionClick();
  }

  void _reject() {
    HapticFeedback.heavyImpact();
    setState(() => _entered = '');
    _shake.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final keySize = _keySize(context);

    return Opacity(
      opacity: widget.isDisabled ? DesignConstants.opacityMedium : 1,
      child: IgnorePointer(
        ignoring: widget.isDisabled,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: DesignConstants.spacingMedium),
            _dots(context),
            const SizedBox(height: DesignConstants.spacingMedium),
            // Held even when there is nothing to say, so the keypad does not
            // jump a line up and down as messages come and go.
            SizedBox(
              height: 34,
              child: Text(
                widget.message ?? '',
                textAlign: TextAlign.center,
                maxLines: 2,
                style: TextStyle(color: colors.textSecondary, fontSize: 13),
              ),
            ),
            SizedBox(height: DesignConstants.sectionSpacing(context)),
            for (final row in _rows) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (final digit in row) ...[
                    _DigitKey(
                      digit: digit,
                      level: widget.level,
                      size: keySize,
                      onPressed: () => _append(digit),
                    ),
                    if (digit != row.last)
                      const SizedBox(width: DesignConstants.spacingLarge),
                  ],
                ],
              ),
              const SizedBox(height: DesignConstants.spacingMedium),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Both corners keep their room whether or not they hold a key,
                // so the zero stays under the eight.
                _corner(
                  keySize,
                  widget.biometryIcon == null || widget.onBiometry == null
                      ? null
                      : _CornerKey(
                          size: keySize,
                          onPressed: widget.onBiometry!,
                          child: widget.biometryIcon!,
                        ),
                ),
                const SizedBox(width: DesignConstants.spacingLarge),
                _DigitKey(
                  digit: 0,
                  level: widget.level,
                  size: keySize,
                  onPressed: () => _append(0),
                ),
                const SizedBox(width: DesignConstants.spacingLarge),
                _corner(
                  keySize,
                  _entered.isEmpty
                      ? null
                      : _CornerKey(
                          size: keySize,
                          onPressed: _delete,
                          child: Icon(
                            SFSymbols.deleteLeft,
                            size: 28,
                            color: colors.textSecondary,
                          ),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _corner(double size, Widget? child) =>
      SizedBox.square(dimension: size, child: child);

  /// The side-to-side refusal of a wrong code: three quick passes, ending where
  /// it started.
  Widget _dots(BuildContext context) => AnimatedBuilder(
    animation: _shake,
    builder: (context, child) => Transform.translate(
      offset: Offset(math.sin(_shake.value * math.pi * 6) * 10, 0),
      child: child,
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var index = 0; index < widget.length; index++) ...[
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: DesignConstants.rungSize + DesignConstants.padding,
            height: DesignConstants.rungSize + DesignConstants.padding,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: index < _entered.length
                  ? widget.level.gradient(context)
                  : null,
              border: Border.all(
                color: widget.level.color(context).withValues(alpha: .6),
                width: DesignConstants.lineWidth,
              ),
            ),
          ),
          if (index != widget.length - 1)
            const SizedBox(width: DesignConstants.spacingMedium),
        ],
      ],
    ),
  );
}

/// A key settles a little deeper than a card does — it is meant to feel like a
/// button.
class _DigitKey extends StatefulWidget {
  const _DigitKey({
    required this.digit,
    required this.level,
    required this.size,
    required this.onPressed,
  });

  final int digit;
  final AuraLevel level;
  final double size;
  final VoidCallback onPressed;

  @override
  State<_DigitKey> createState() => _DigitKeyState();
}

class _DigitKeyState extends State<_DigitKey> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final tones = widget.level.gradientColors(context);

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: () {
        setState(() => _pressed = false);
        widget.onPressed();
      },
      child: AnimatedScale(
        scale: _pressed ? 0.92 : 1,
        duration: const Duration(milliseconds: 120),
        child: AnimatedOpacity(
          opacity: _pressed ? DesignConstants.opacityMedium : 1,
          duration: const Duration(milliseconds: 120),
          child: Container(
            width: widget.size,
            height: widget.size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.bottomLeft,
                end: Alignment.topRight,
                colors: [
                  tones[0].withValues(alpha: .22),
                  tones[1].withValues(alpha: .16),
                ],
              ),
              border: Border.all(
                color: widget.level.nextColor(context).withValues(alpha: .45),
                width: DesignConstants.lineWidthThin,
              ),
            ),
            child: Text(
              '${widget.digit}',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 28,
                fontWeight: FontWeight.w300,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The biometry and delete keys: a glyph alone, with no disc under it.
class _CornerKey extends StatelessWidget {
  const _CornerKey({
    required this.size,
    required this.onPressed,
    required this.child,
  });

  final double size;
  final VoidCallback onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onPressed,
    behavior: HitTestBehavior.opaque,
    child: SizedBox.square(dimension: size, child: Center(child: child)),
  );
}
