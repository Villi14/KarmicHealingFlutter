import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/design_constants.dart';
import 'sf_symbols.dart';

enum AuraLevel { root, sacral, solar, heart, throat, brow, crown }

/// The spectrum shifts with the appearance — every level is a touch brighter on
/// a dark page — so a level only becomes a colour once it knows where it is
/// being painted.
extension AuraLevelStyle on AuraLevel {
  Color color(BuildContext context) {
    final colors = AppColors.of(context);
    return switch (this) {
      AuraLevel.root => colors.energy,
      AuraLevel.sacral => colors.friendly,
      AuraLevel.solar => colors.clarity,
      AuraLevel.heart => colors.health,
      AuraLevel.throat => colors.clam,
      AuraLevel.brow => colors.peace,
      AuraLevel.crown => colors.wisdom,
    };
  }

  /// The neighbour a level borrows its second tone from: the next one up the
  /// spectrum, except for sacral — requests sit between root and sacral, so
  /// their identity runs from red into orange rather than on into yellow.
  AuraLevel get companion {
    if (this == AuraLevel.sacral) return AuraLevel.root;
    final levels = AuraLevel.values;
    return levels[index == levels.length - 1 ? index - 1 : index + 1];
  }

  Color nextColor(BuildContext context) => companion.color(context);

  /// Sacral reads from its companion into itself, so the spectrum still runs
  /// red to orange rather than backwards.
  List<Color> gradientColors(BuildContext context) => this == AuraLevel.sacral
      ? [nextColor(context), color(context)]
      : [color(context), nextColor(context)];

  LinearGradient gradient(BuildContext context) => LinearGradient(
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
    colors: gradientColors(context),
  );

  /// The same two tones laid left to right, for a track or a bar.
  LinearGradient horizontalGradient(BuildContext context) =>
      LinearGradient(colors: gradientColors(context));
}

class AuraRings extends StatelessWidget {
  const AuraRings({
    super.key,
    required this.level,
    this.tone,
    this.size = 78,
    this.count = 3,
    this.opacity = .5,
    this.core = false,
  });

  final AuraLevel level;
  final Color? tone;
  final double size;
  final int count;
  final double opacity;
  final bool core;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(
      painter: _RingsPainter(
        colors: tone == null
            ? level.gradientColors(context)
            : [tone!, Color.lerp(tone!, Colors.white, .3)!],
        count: count,
        opacity: opacity,
        core: core,
      ),
    ),
  );
}

/// One inhale and exhale of the ambient breath.
const breathPeriod = Duration(seconds: 8);

/// Where the breath is at a given moment, 0 (emptied) to 1 (full).
///
/// Taken from the clock rather than from when a view appeared, so everything
/// breathing anywhere in the app is on the same inhale.
double breathPhaseAt(DateTime moment) {
  final period = breathPeriod.inMilliseconds;
  final turn = moment.millisecondsSinceEpoch % period / period;
  return (1 - math.cos(turn * 2 * math.pi)) / 2;
}

/// The session ring: [AuraRings] with a filled core, breathing on the ambient
/// curve — the rings widening and the core coming up to full over one inhale,
/// and back over the exhale, eight seconds for the pair.
///
/// The phase is read off the wall clock rather than counted from when the
/// widget was built, so rings on pages a [PageView] only builds when they are
/// swiped to are on the same breath as the one already on screen. It holds
/// still where the platform asks for reduced motion, and stops along with the
/// rest of the tickers under a disabled [TickerMode] — which is how a resting
/// session parks it rather than breathing at a black screen.
class BreathingRings extends StatefulWidget {
  const BreathingRings({
    super.key,
    required this.level,
    this.tone,
    this.size = DesignConstants.breathingRingSize,
    this.count = 3,
  });

  final AuraLevel level;
  final Color? tone;
  final double size;
  final int count;

  @override
  State<BreathingRings> createState() => _BreathingRingsState();
}

class _BreathingRingsState extends State<BreathingRings>
    with SingleTickerProviderStateMixin {
  /// How often the ring is redrawn. A curve this slow is smooth at 30 a
  /// second, and the ticker offers up to four times that.
  static const _tick = Duration(milliseconds: 33);

  /// The ticker only paces the redraws; where the breath is comes from the
  /// clock, so a frame dropped or skipped costs nothing.
  late final _heartbeat =
      AnimationController(vsync: this, duration: breathPeriod)
        ..addListener(_redraw);

  final _phase = ValueNotifier<double>(1);
  Duration _last = Duration.zero;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _heartbeat.stop();
      // Reduced motion leaves the ring where the breath is fullest.
      _phase.value = 1;
    } else if (!_heartbeat.isAnimating) {
      _heartbeat.repeat();
    }
  }

  void _redraw() {
    final elapsed = _heartbeat.lastElapsedDuration ?? Duration.zero;
    if ((elapsed - _last).abs() < _tick) return;
    _last = elapsed;
    _phase.value = breathPhaseAt(DateTime.now());
  }

  @override
  void dispose() {
    _heartbeat.dispose();
    _phase.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: widget.size,
    child: CustomPaint(
      painter: _RingsPainter(
        colors: widget.tone == null
            ? widget.level.gradientColors(context)
            : [
                widget.tone!,
                Color.lerp(widget.tone!, Colors.white, .3)!,
              ],
        count: widget.count,
        opacity: .5,
        core: true,
        phase: _phase,
      ),
    ),
  );
}

class _RingsPainter extends CustomPainter {
  _RingsPainter({
    required this.colors,
    required this.count,
    required this.opacity,
    required this.core,
    this.phase,
  }) : super(repaint: phase);

  final List<Color> colors;
  final int count;
  final double opacity;
  final bool core;

  /// Where the breath is, 0 (emptied) to 1 (full). A ring that does not
  /// breathe leaves this off and is drawn at full.
  final ValueListenable<double>? phase;

  double get _breath => phase?.value ?? 1;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final shader = LinearGradient(colors: colors).createShader(rect);
    final paint = Paint()
      ..shader = shader
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.white.withValues(alpha: opacity);
    // The rings draw in from their full width as the breath empties.
    final scale = DesignConstants.breathScale +
        (1 - DesignConstants.breathScale) * _breath;
    for (var i = 0; i < count; i++) {
      final radius = size.shortestSide / 2 * (i + 1) / count;
      canvas.drawCircle(rect.center, (radius - .5) * scale, paint);
    }
    if (core) {
      canvas.drawCircle(
        rect.center,
        DesignConstants.ringCoreSize / 2,
        Paint()
          ..shader = shader
          ..style = PaintingStyle.fill
          // And the core dims with them, never below half.
          ..color = Colors.white.withValues(alpha: .5 + .5 * _breath),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RingsPainter oldDelegate) => false;
}

/// The two-tone sheen built from a colour the row or card carries itself:
/// that colour, and the same colour lightened.
LinearGradient toneGradient(Color tone) => LinearGradient(
  begin: Alignment.bottomLeft,
  end: Alignment.topRight,
  colors: [tone, Color.lerp(tone, Colors.white, .3)!],
);

/// How far off what is under it a card is lifted.
enum AuraElevation {
  /// A panel on the screen's own background.
  raised,

  /// An inset lying on top of a panel: it is only a little way above what it
  /// covers, so its shadow is shorter and softer than a panel's.
  inset,

  /// A row or a field flush with the surface it belongs to.
  flat;

  List<BoxShadow>? shadows() => switch (this) {
    raised => [
      BoxShadow(
        color: Colors.black.withValues(
          alpha: DesignConstants.opacityCardShadow,
        ),
        blurRadius: DesignConstants.shadowRadiusCard,
        offset: const Offset(0, DesignConstants.shadowOffsetCard),
      ),
    ],
    inset => [
      BoxShadow(
        color: Colors.black.withValues(
          alpha: DesignConstants.opacityInsetShadow,
        ),
        blurRadius: DesignConstants.shadowRadiusInset,
        offset: const Offset(0, DesignConstants.shadowOffsetInset),
      ),
    ],
    flat => null,
  };
}

class AuraCard extends StatelessWidget {
  const AuraCard({
    super.key,
    required this.level,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.watermark = true,
    this.onTap,
    this.tone,
    this.elevation = AuraElevation.raised,
  });

  final AuraLevel level;
  final Widget child;
  final EdgeInsets padding;
  final bool watermark;
  final VoidCallback? onTap;
  final Color? tone;
  final AuraElevation elevation;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.of(context).backgroundSecondary,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color:
              (tone == null
                      ? level.nextColor(context)
                      : Color.lerp(tone!, Colors.white, .3)!)
                  .withValues(alpha: .45),
          width: .5,
        ),
        boxShadow: elevation.shadows(),
      ),
      child: Stack(
        children: [
          if (watermark)
            Positioned(
              right: -34,
              bottom: -34,
              child: AuraRings(level: level, tone: tone, size: 96, opacity: .3),
            ),
          Padding(padding: padding, child: child),
        ],
      ),
    );
    return onTap == null
        ? card
        : InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onTap,
            child: card,
          );
  }
}

class AuraIcon extends StatelessWidget {
  const AuraIcon(
    IconData icon, {
    super.key,
    required this.level,
    this.size = 24,
  }) : _symbol = icon,
       _glyph = null;

  /// For the SF Symbols that Cupertino Icons has no glyph for, so they take the
  /// same gradient as the ones that do.
  const AuraIcon.drawn(
    SFGlyph glyph, {
    super.key,
    required this.level,
    this.size = 24,
  }) : _glyph = glyph,
       _symbol = null;

  final IconData? _symbol;
  final SFGlyph? _glyph;
  final AuraLevel level;
  final double size;

  @override
  Widget build(BuildContext context) => ShaderMask(
    shaderCallback: level.gradient(context).createShader,
    child: _symbol != null
        ? Icon(_symbol, size: size, color: Colors.white)
        : SFIcon(_glyph!, size: size, color: Colors.white),
  );
}

/// The same glyph treatment as [AuraIcon], tinted by a colour a topic or a
/// request carries rather than by a spectrum level.
class ToneIcon extends StatelessWidget {
  const ToneIcon(this.icon, {super.key, required this.tone, this.size = 18});

  final IconData icon;
  final Color tone;
  final double size;

  @override
  Widget build(BuildContext context) => ShaderMask(
    shaderCallback: toneGradient(tone).createShader,
    child: Icon(icon, size: size, color: Colors.white),
  );
}

/// A word under the same gradient the glyph beside it takes.
///
/// The Swift app gives the label of a bar button the level's gradient, exactly
/// as it gives it to the plus in front of it — each carries the whole ramp
/// across its own width rather than sharing one sweep, so this wraps the text
/// on its own and leaves the glyph to [AuraIcon].
class AuraText extends StatelessWidget {
  const AuraText(this.text, {super.key, required this.level, this.fontSize});

  final String text;
  final AuraLevel level;
  final double? fontSize;

  @override
  Widget build(BuildContext context) => ShaderMask(
    shaderCallback: level.gradient(context).createShader,
    child: Text(
      text,
      style: TextStyle(color: Colors.white, fontSize: fontSize),
    ),
  );
}

/// The same treatment as [AuraText], tinted by a colour a topic or a request
/// carries rather than by a spectrum level.
class ToneText extends StatelessWidget {
  const ToneText(this.text, {super.key, required this.tone, this.fontSize});

  final String text;
  final Color tone;
  final double? fontSize;

  @override
  Widget build(BuildContext context) => ShaderMask(
    shaderCallback: toneGradient(tone).createShader,
    child: Text(
      text,
      style: TextStyle(color: Colors.white, fontSize: fontSize),
    ),
  );
}

/// The uppercase eyebrow above a step or a section: "STEP 4 OF 14".
///
/// The spectrum sits in the middle of the range, so as tiny uppercase text it
/// washes out against the page unless the tone moves away from it — down on a
/// light page, up on a dark one.
class AuraLabel extends StatelessWidget {
  const AuraLabel(this.text, {super.key, this.tone});

  final String text;
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        color: tone == null ? colors.textSecondary : colors.contrasting(tone!),
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
      ),
    );
  }
}

/// A switch whose active track carries the same two-tone aura as the screen,
/// in place of the platform's single tint.
class AuraSwitch extends StatelessWidget {
  const AuraSwitch({
    super.key,
    required this.value,
    required this.level,
    required this.onChanged,
    this.label,
  });

  final bool value;
  final AuraLevel level;
  final ValueChanged<bool> onChanged;

  /// What a screen reader calls the switch, since the row's own text sits in a
  /// separate widget.
  final String? label;

  static const _width = 51.0;
  static const _height = 31.0;
  static const _knobInset = 2.0;

  @override
  Widget build(BuildContext context) => Semantics(
    label: label,
    toggled: value,
    child: GestureDetector(
      onTap: () => onChanged(!value),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        width: _width,
        height: _height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_height / 2),
          gradient: value ? level.horizontalGradient(context) : null,
          color: value
              ? null
              : AppColors.of(context).textSecondary.withValues(alpha: .28),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.all(_knobInset),
            width: _height - _knobInset * 2,
            height: _height - _knobInset * 2,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .16),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

/// A slider with a gradient-filled progress track, so the control reads as part
/// of the screen's spectrum rather than as a platform accent.
class AuraSlider extends StatelessWidget {
  const AuraSlider({
    super.key,
    required this.value,
    required this.level,
    required this.onChanged,
    this.divisions,
    this.label,
  });

  final double value;
  final AuraLevel level;

  /// A null callback disables the slider, as it does on [Slider].
  final ValueChanged<double>? onChanged;
  final int? divisions;
  final String? label;

  static const _thumbDiameter = 28.0;
  static const _trackHeight = 6.0;

  double _steppedValue(double raw) {
    final clamped = raw.clamp(0.0, 1.0);
    if (divisions == null) return clamped;
    return (clamped * divisions!).roundToDouble() / divisions!;
  }

  @override
  Widget build(BuildContext context) {
    final enabled = onChanged != null;
    final progress = value.clamp(0.0, 1.0);

    return Semantics(
      label: label,
      slider: true,
      value: '${(progress * 100).round()}%',
      child: SizedBox(
        height: 32,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final travel = (constraints.maxWidth - _thumbDiameter).clamp(
              1.0,
              double.infinity,
            );

            void update(Offset position) {
              if (!enabled) return;
              onChanged!(
                _steppedValue((position.dx - _thumbDiameter / 2) / travel),
              );
            }

            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (details) => update(details.localPosition),
              onHorizontalDragStart: (details) => update(details.localPosition),
              onHorizontalDragUpdate: (details) =>
                  update(details.localPosition),
              child: Opacity(
                opacity: enabled ? 1 : DesignConstants.opacityMedium,
                child: Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: _thumbDiameter / 2,
                      ),
                      child: Container(
                        height: _trackHeight,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(_trackHeight / 2),
                          color: AppColors.of(
                            context,
                          ).textSecondary.withValues(alpha: .20),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: _thumbDiameter / 2),
                      child: Container(
                        width: travel * progress,
                        height: _trackHeight,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(_trackHeight / 2),
                          gradient: level.horizontalGradient(context),
                        ),
                      ),
                    ),
                    Positioned(
                      left: travel * progress,
                      child: Container(
                        width: _thumbDiameter,
                        height: _thumbDiameter,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: .16),
                              blurRadius: 3,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: CustomPaint(
                          painter: _ThumbRingPainter(
                            gradient: level.gradient(context),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ThumbRingPainter extends CustomPainter {
  const _ThumbRingPainter({required this.gradient});

  final LinearGradient gradient;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawCircle(
      rect.center,
      size.shortestSide / 2 - DesignConstants.lineWidth / 2,
      Paint()
        ..shader = gradient.createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = DesignConstants.lineWidth,
    );
  }

  @override
  bool shouldRepaint(covariant _ThumbRingPainter oldDelegate) =>
      oldDelegate.gradient != gradient;
}

/// How loudly a button asks to be pressed: filled with the tone for the one
/// action that moves the screen forward, the tone on a wash of itself otherwise.
enum AuraProminence { filled, quiet }

class AuraButton extends StatelessWidget {
  const AuraButton({
    super.key,
    required this.label,
    required this.level,
    required this.onPressed,
    this.icon,
    this.prominence = AuraProminence.filled,
  });

  final String label;
  final AuraLevel level;
  final VoidCallback onPressed;
  final IconData? icon;
  final AuraProminence prominence;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      gradient: prominence == AuraProminence.filled
          ? level.gradient(context)
          : LinearGradient(
              begin: Alignment.bottomLeft,
              end: Alignment.topRight,
              colors: [
                level.gradientColors(context)[0].withValues(alpha: .22),
                level.gradientColors(context)[1].withValues(alpha: .16),
              ],
            ),
      borderRadius: BorderRadius.circular(20),
    ),
    child: TextButton.icon(
      onPressed: onPressed,
      icon: icon == null ? const SizedBox.shrink() : Icon(icon, size: 18),
      label: Text(label, textAlign: TextAlign.center),
      style: TextButton.styleFrom(
        foregroundColor: prominence == AuraProminence.filled
            ? AppColors.onAccent
            : level.color(context),
        minimumSize: const Size(80, 48),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    ),
  );
}
