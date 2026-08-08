import 'dart:async';

import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/design_constants.dart';
import '../../data/energy_settings.dart';
import '../../data/session_effects.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/aura_widgets.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/scroll_blur.dart';
import '../../widgets/sf_symbols.dart';
import 'energy_settings_screen.dart';

class BalancingEnergyScreen extends StatefulWidget {
  const BalancingEnergyScreen({
    super.key,
    required this.title,
    required this.steps,
    this.onCompleted,
    this.effects,
    this.now = DateTime.now,
  });

  final String title;
  final List<EnergyStep> steps;
  final VoidCallback? onCompleted;

  /// What the session reaches the device with — the chime, the haptics and the
  /// screen's darkness. Left out, it takes the real device; a test hands one
  /// that only remembers what it was asked for.
  final SessionEffects? effects;

  /// The wall clock a session keeps its schedule by. A test hands one it can
  /// wind forward, so a step that takes five minutes need not take five.
  final DateTime Function() now;

  @override
  State<BalancingEnergyScreen> createState() => _BalancingEnergyScreenState();
}

class _BalancingEnergyScreenState extends State<BalancingEnergyScreen>
    with WidgetsBindingObserver {
  late final PageController _pageController;
  late final SessionEffects _effects;
  late EnergySettings _settings;
  int _currentStep = 0;
  Timer? _ticker;
  late DateTime _stepStartedAt = widget.now();
  Duration _stepDuration = const Duration(minutes: 5);
  Duration _pausedRemaining = Duration.zero;
  bool _isPaused = false;

  /// The screen has gone dark to let the user sit with the step.
  bool _isResting = false;

  /// When the screen last lit up — a step change or a touch.
  late DateTime _lastWokeAt = widget.now();

  /// The session was paused because the app left the screen, not because the
  /// user asked. Only such a pause is lifted again on the way back.
  bool _pausedByBackground = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pageController = PageController();
    _effects = widget.effects ?? DeviceSessionEffects();
    _effects.begin();
    _startTicker();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _settings = EnergySettingsScope.of(context);
    // A session picks up settings changed under it — the settings screen is
    // reachable from this one's toolbar, so the change usually arrives mid-run.
    // A rest the user has just switched off has to lift at once, so any change
    // brings the screen back and starts the delay again.
    _wake();
    if (_settings.stepDuration == _stepDuration) return;
    setState(() {
      _stepDuration = _settings.stepDuration;
      _restartStepTimer();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    _effects.end();
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Only a pause this screen put on is lifted: one the user chose stays.
      if (_pausedByBackground) {
        _pausedByBackground = false;
        _togglePause();
      }
      _effects.begin();
      _wake();
      _startTicker();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      // A session only runs while the user is with it. Nothing carries it once
      // the app is out of sight, so it holds its place rather than racing
      // ahead unwatched and chiming its way through a dozen steps on return.
      _ticker?.cancel();
      if (!_isPaused) {
        _pausedByBackground = true;
        _togglePause();
      }
      _wake();
    }
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _isPaused) return;
      if (_remaining == Duration.zero && !_isLastStep) _nextStep();
      if (!mounted) return;
      if (_shouldRest) _rest();
      setState(() {});
    });
  }

  /// A rest is due only once the screen has been left alone for the chosen
  /// delay, and never while the session is paused — a paused session is one the
  /// user is looking at.
  bool get _shouldRest {
    if (!_settings.screenRestEnabled || _isResting || _isPaused) return false;
    return widget.now().difference(_lastWokeAt).inSeconds >=
        _settings.screenRestDelay;
  }

  void _rest() {
    _isResting = true;
    _effects.setDimmed(true);
  }

  /// Brings the screen back and restarts the countdown to the next rest.
  void _wake() {
    _lastWokeAt = widget.now();
    if (!_isResting) return;
    _isResting = false;
    _effects.setDimmed(false);
  }

  /// The chime and the tap a step change makes, each only if it was asked for.
  void _feedback() {
    if (_settings.soundEnabled) _effects.chime(_settings.audioVolume);
    if (_settings.vibrationEnabled) _effects.vibrate();
  }

  Duration get _remaining {
    if (_isPaused) return _pausedRemaining;
    final remaining = _stepDuration - widget.now().difference(_stepStartedAt);
    return remaining.isNegative ? Duration.zero : remaining;
  }

  double get _timerProgress {
    if (_stepDuration.inMilliseconds == 0) return 0;
    return (1 - _remaining.inMilliseconds / _stepDuration.inMilliseconds).clamp(
      0,
      1,
    );
  }

  bool get _isLastStep => _currentStep == widget.steps.length - 1;

  double get _progress =>
      widget.steps.length <= 1 ? 0 : _currentStep / (widget.steps.length - 1);

  AuraLevel get _sessionLevel =>
      AuraLevel.values[(_progress * 6).round().clamp(0, 6)];

  Color get _sessionTone {
    final position = _progress * 6;
    final lower = position.floor().clamp(0, 6);
    final upper = (lower + 1).clamp(0, 6);
    return Color.lerp(
          AuraLevel.values[lower].color(context),
          AuraLevel.values[upper].color(context),
          position - lower,
        ) ??
        _sessionLevel.color(context);
  }

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [_buildSession(context), if (_isResting) _buildScreenRest()],
  );

  /// The darkness the screen rests in.
  ///
  /// The display underneath is really taken to black; this covers what it still
  /// leaks, and gives the touch that brings the step back somewhere to land.
  Widget _buildScreenRest() => Semantics(
    label: AppLocalizations.of(context).screenRest,
    button: true,
    child: GestureDetector(
      onTap: () => setState(_wake),
      behavior: HitTestBehavior.opaque,
      child: const ColoredBox(color: Colors.black),
    ),
  );

  Widget _buildSession(BuildContext context) => ScrollBlur(
    child: Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        flexibleSpace: const ScrollBlurBackdrop(),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(widget.title),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const AuraIcon(SFSymbols.chevronLeft, level: AuraLevel.heart),
        ),
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                fullscreenDialog: true,
                builder: (_) => const EnergySettingsScreen(),
              ),
            ),
            icon: const AuraIcon.drawn(
              SFGlyph.gearshape,
              level: AuraLevel.heart,
            ),
          ),
        ],
      ),
      body: GradientBackground(
        tone: _sessionTone,
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              SizedBox(height: DesignConstants.navigationBarInset(context)),
              Padding(
                padding: EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Text(
                  AppLocalizations.of(
                    context,
                  ).attentionBeforeProceeding.toUpperCase(),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: TextStyle(
                    color: AppColors.of(context).textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 700),
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 16),
                          child: _StepLadder(
                            count: widget.steps.length,
                            currentStep: _currentStep,
                            level: _sessionLevel,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: PageView.builder(
                            controller: _pageController,
                            itemCount: widget.steps.length,
                            // Every way a step can change comes through here —
                            // the buttons, a swipe, and the timer running out —
                            // so this is the one place the chime is rung and
                            // the screen brought back from its rest.
                            onPageChanged: (index) => setState(() {
                              _currentStep = index;
                              _restartStepTimer();
                              _feedback();
                              _wake();
                            }),
                            itemBuilder: (context, index) => Padding(
                              padding: const EdgeInsets.fromLTRB(8, 12, 16, 50),
                              child: _StepCard(
                                step: widget.steps[index],
                                number: index + 1,
                                count: widget.steps.length,
                                level:
                                    AuraLevel.values[(index /
                                            (widget.steps.length - 1) *
                                            6)
                                        .round()
                                        .clamp(0, 6)],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (!_isLastStep) _buildTimerBadge(),
              _buildNavigationButtons(),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _buildTimerBadge() {
    final l10n = AppLocalizations.of(context);
    final total = _remaining.inSeconds;
    final time = '${total ~/ 60}:${(total % 60).toString().padLeft(2, '0')}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox.square(
            dimension: 18,
            child: CircularProgressIndicator(
              value: _isPaused ? 1 : _timerProgress,
              strokeWidth: 1,
              color: _sessionLevel.color(context),
              backgroundColor: _sessionLevel
                  .color(context)
                  .withValues(alpha: .5),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _isPaused
                ? l10n.paused.toUpperCase()
                : l10n.nextStepIn(time).toUpperCase(),
            style: TextStyle(
              color: _sessionTone,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          IconButton(
            onPressed: _togglePause,
            visualDensity: VisualDensity.compact,
            tooltip: _isPaused ? l10n.resume : l10n.pause,
            icon: AuraIcon(
              _isPaused ? SFSymbols.play : SFSymbols.pause,
              level: _sessionLevel,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 700),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        child: Row(
          children: [
            if (_currentStep > 0)
              AuraButton(
                label: AppLocalizations.of(context).back,
                level: _sessionLevel,
                onPressed: _previousStep,
              ),
            const Spacer(),
            AuraButton(
              label: _isLastStep
                  ? AppLocalizations.of(context).done
                  : AppLocalizations.of(context).next,
              level: _sessionLevel,
              onPressed: _nextStep,
            ),
          ],
        ),
      ),
    ),
  );

  void _restartStepTimer() {
    _stepStartedAt = widget.now();
    _pausedRemaining = _stepDuration;
  }

  void _togglePause() => setState(() {
    // Either way the user is looking at the screen again.
    _wake();
    if (_isPaused) {
      _stepStartedAt = widget.now().subtract(
        _stepDuration - _pausedRemaining,
      );
    } else {
      _pausedRemaining = _remaining;
    }
    _isPaused = !_isPaused;
  });

  void _nextStep() {
    if (!_isLastStep) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _ticker?.cancel();
      widget.onCompleted?.call();
      Navigator.of(context).pop();
    }
  }

  void _previousStep() {
    if (_currentStep == 0) return;
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.step,
    required this.number,
    required this.count,
    required this.level,
  });

  final EnergyStep step;
  final int number;
  final int count;
  final AuraLevel level;

  @override
  Widget build(BuildContext context) => AuraCard(
    level: level,
    watermark: false,
    padding: const EdgeInsets.all(24),
    child: SizedBox.expand(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(
              context,
            ).stepCounter(number, count).toUpperCase(),
            style: TextStyle(
              color: level.color(context),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Center(child: AuraRings(level: level, size: 78, core: true)),
          const SizedBox(height: 20),
          Text(
            step.title,
            style: TextStyle(
              fontFamily: 'Source Serif 4',
              fontSize: 20,
              color: AppColors.of(context).textPrimary,
            ),
          ),
          if (step.description.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              step.description,
              style: TextStyle(
                color: AppColors.of(context).textSecondary,
                fontSize: 15,
                height: 1.35,
              ),
            ),
          ],
          const Spacer(),
        ],
      ),
    ),
  );
}

class _StepLadder extends StatelessWidget {
  const _StepLadder({
    required this.count,
    required this.currentStep,
    required this.level,
  });

  final int count;
  final int currentStep;
  final AuraLevel level;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      for (var index = count - 1; index >= 0; index--)
        Container(
          width: 9,
          height: 9,
          margin: EdgeInsets.only(bottom: index == 0 ? 0 : 8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: index <= currentStep ? level.gradient(context) : null,
            border: Border.all(
              color: level
                  .color(context)
                  .withValues(alpha: index <= currentStep ? 1 : .5),
            ),
            boxShadow: index == currentStep
                ? [
                    BoxShadow(
                      color: AppColors.of(
                        context,
                      ).health.withValues(alpha: .22),
                      spreadRadius: 4,
                    ),
                  ]
                : null,
          ),
        ),
    ],
  );
}

class EnergyStep {
  const EnergyStep(this.title, [this.description = '']);

  final String title;
  final String description;
}

class EnergySteps {
  /// The steps of a part, in the order they are walked. They read their text
  /// from [AppLocalizations], so a part is built where a [BuildContext] is at
  /// hand rather than held as a constant.
  static List<EnergyStep> part1(AppLocalizations l10n) => [
    ..._opening(l10n),
    EnergyStep(l10n.part1Step4),
    EnergyStep(l10n.part1Step5),
    EnergyStep(l10n.part1Step6, l10n.part1Step6Text),
    EnergyStep(l10n.part1Step6, l10n.part1Step7Text),
    EnergyStep(l10n.part1Step6, l10n.part1Step8Text),
    EnergyStep(l10n.part1Step6, l10n.part1Step9Text),
    EnergyStep(l10n.part1Step10, l10n.part1Step10Text),
    EnergyStep(l10n.part1Step11),
    EnergyStep(l10n.part1Step12),
    EnergyStep(l10n.part1Step13),
    EnergyStep(l10n.part1Step14),
  ];

  static List<EnergyStep> part2(AppLocalizations l10n) => [
    ..._ascent(l10n),
    EnergyStep(l10n.part2Step10),
    EnergyStep(l10n.part2Step11),
    EnergyStep(l10n.stepLast),
  ];

  static List<EnergyStep> part3(AppLocalizations l10n) => [
    ..._ascent(l10n),
    EnergyStep(l10n.part2Step10),
    EnergyStep(l10n.part3Step11),
    EnergyStep(l10n.part3Step12),
    EnergyStep(l10n.part3Step13),
    EnergyStep(l10n.part3Step14),
    EnergyStep(l10n.part3Step15),
    EnergyStep(l10n.part3Step16),
    EnergyStep(l10n.part3Step17),
    EnergyStep(l10n.stepLast),
  ];

  /// The three steps every part opens with.
  static List<EnergyStep> _opening(AppLocalizations l10n) => [
    EnergyStep(l10n.step1),
    EnergyStep(l10n.step2),
    EnergyStep(l10n.step3, l10n.step3Text),
  ];

  /// What parts two and three share before they part ways.
  static List<EnergyStep> _ascent(AppLocalizations l10n) => [
    ..._opening(l10n),
    EnergyStep(l10n.part2Step4),
    EnergyStep(l10n.part2Step5),
    EnergyStep(l10n.part1Step11),
    EnergyStep(l10n.part1Step12),
    EnergyStep(l10n.part2Step8),
    EnergyStep(l10n.part2Step9),
  ];
}
