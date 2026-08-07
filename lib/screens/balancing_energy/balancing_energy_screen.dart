import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../constants/app_colors.dart';
import '../../constants/design_constants.dart';
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
  });

  final String title;
  final List<EnergyStep> steps;
  final VoidCallback? onCompleted;

  @override
  State<BalancingEnergyScreen> createState() => _BalancingEnergyScreenState();
}

class _BalancingEnergyScreenState extends State<BalancingEnergyScreen>
    with WidgetsBindingObserver {
  late final PageController _pageController;
  int _currentStep = 0;
  Timer? _ticker;
  DateTime _stepStartedAt = DateTime.now();
  Duration _stepDuration = const Duration(minutes: 5);
  Duration _pausedRemaining = Duration.zero;
  bool _isPaused = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pageController = PageController();
    _loadTimerSettings();
    _startTicker();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startTicker();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      _ticker?.cancel();
    }
  }

  Future<void> _loadTimerSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final minutes = prefs.getInt('energy_step_duration_minutes') ?? 5;
    if (!mounted) return;
    setState(() {
      _stepDuration = Duration(minutes: minutes > 0 ? minutes : 5);
      _restartStepTimer();
    });
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _isPaused) return;
      if (_remaining == Duration.zero && !_isLastStep) _nextStep();
      if (mounted) setState(() {});
    });
  }

  Duration get _remaining {
    if (_isPaused) return _pausedRemaining;
    final remaining = _stepDuration - DateTime.now().difference(_stepStartedAt);
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
          AuraLevel.values[lower].color,
          AuraLevel.values[upper].color,
          position - lower,
        ) ??
        _sessionLevel.color;
  }

  @override
  Widget build(BuildContext context) => ScrollBlur(
    child: Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        flexibleSpace: const ScrollBlurBackdrop(),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
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
              const Padding(
                padding: EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Text(
                  'COMPLETE THE PREVIOUS STEP BEFORE MOVING ON TO THE NEXT ONE. EACH STEP TAKES ABOUT FIVE MINUTES.',
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: TextStyle(
                    color: AppColors.textSecondary,
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
                            onPageChanged: (index) => setState(() {
                              _currentStep = index;
                              _restartStepTimer();
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
              color: _sessionLevel.color,
              backgroundColor: _sessionLevel.color.withValues(alpha: .5),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _isPaused ? 'PAUSED' : 'NEXT STEP IN $time',
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
            tooltip: _isPaused ? 'Resume' : 'Pause',
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
                label: 'Back',
                level: _sessionLevel,
                onPressed: _previousStep,
              ),
            const Spacer(),
            AuraButton(
              label: _isLastStep ? 'Done' : 'Next',
              level: _sessionLevel,
              onPressed: _nextStep,
            ),
          ],
        ),
      ),
    ),
  );

  void _restartStepTimer() {
    _stepStartedAt = DateTime.now();
    _pausedRemaining = _stepDuration;
  }

  void _togglePause() => setState(() {
    if (_isPaused) {
      _stepStartedAt = DateTime.now().subtract(
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
            'STEP $number OF $count',
            style: TextStyle(
              color: level.color,
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
            style: const TextStyle(
              fontFamily: 'Source Serif 4',
              fontSize: 20,
              color: AppColors.textPrimary,
            ),
          ),
          if (step.description.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              step.description,
              style: const TextStyle(
                color: AppColors.textSecondary,
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
            gradient: index <= currentStep ? level.gradient : null,
            border: Border.all(
              color: level.color.withValues(
                alpha: index <= currentStep ? 1 : .5,
              ),
            ),
            boxShadow: index == currentStep
                ? [
                    BoxShadow(
                      color: AppColors.health.withValues(alpha: .22),
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
  static const _step1 = EnergyStep(
    'Ask permission to speak with the Lords of Karma.',
  );
  static const _step2 = EnergyStep(
    'Ask them to align your energy bodies and set up contacts between them.',
  );
  static const _step3 = EnergyStep(
    'Ask to clear, heal, activate and open:',
    'a) Ka Matrix;\nb) Etheric Matrix;\nc) Ketheric Matrix;\nd) Celestial Matrix;\nd) I-Am Matrix.\n\nDo this in order. Move on to the next request, having finished with the previous one.',
  );
  static const _part1Step4 = EnergyStep(
    'Ask to restore, heal and activate your twelve strand DNA.',
  );
  static const _part1Step5 = EnergyStep(
    'Ask for the healing of the central soul to be completed.',
  );
  static const _part1Step6 = EnergyStep(
    'Optional process',
    'Ask the Lords of Karma to cleanse, release, and heal the Kundalini chakras from all negative connections',
  );
  static const _part1Step7 = EnergyStep(
    'Optional process',
    'Ask the Lords of Karma to cleanse, release, and heal the Kundalini chakras from all negative hooks.',
  );
  static const _part1Step8 = EnergyStep(
    'Optional process',
    'Ask the Lords of Karma to cleanse, release, and heal the chakras of the Hara line from all negative hooks.',
  );
  static const _part1Step9 = EnergyStep(
    'Optional process',
    'Ask the Lords of Karma to free, heal, and cleanse your energy from all heart wounds.',
  );
  static const _part1Step10 = EnergyStep(
    'Ask your Higher Self to come to you, and then:',
    'a) ask his name;\nb) ask him for a gift;\nc) listen to his request for a return gift;\nd) ask that it remain with you always.',
  );
  static const _part1Step11 = EnergyStep(
    'Ask your Higher Self to clear, align, open, activate and fill the Hara line channels and chakras.',
  );
  static const _part1Step12 = EnergyStep(
    'Ask your Higher Self to clear, align, open, activate and fill the Kundalini channels and chakras.',
  );
  static const _part1Step13 = EnergyStep(
    'Ask that the process that has just been completed become permanent.',
  );
  static const _part1Step14 = EnergyStep('Come back to today.');
  static const _part2Step4 = EnergyStep(
    'Ask to restore, heal and activate your Silver Cord.',
  );
  static const _part2Step5 = EnergyStep('Ask your Higher Self to come to you.');
  static const _part2Step8 = EnergyStep(
    'Ask to clear, heal, align, open and activate the three Galactic Matrices.',
  );
  static const _part2Step9 = EnergyStep(
    'Ask to clear, heal, align, open and activate the five Galactic Chakras.',
  );
  static const _part2Step10 = EnergyStep(
    'Ask your Essence Self/Star Self to come forth and merge with your Higher Self.',
  );
  static const _part2Step11 = EnergyStep(
    'Talk to him a little and ask him to connect with you forever.',
  );
  static const _part3Step11 = EnergyStep(
    'Ask to clear, heal, align, open and activate the three Matrices of the causal body.',
  );
  static const _part3Step12 = EnergyStep(
    'Ask to clear, heal, align, open and activate the five chakras of the causal body.',
  );
  static const _part3Step13 = EnergyStep(
    'Ask your Divine Self/OverSoul to come and merge with your Higher Self and Essential Self.',
  );
  static const _part3Step14 = EnergyStep('Ask his name, talk to him.');
  static const _part3Step15 = EnergyStep(
    'Ask your Divine Self to stay with you forever (the process may take several days).',
  );
  static const _part3Step16 = EnergyStep(
    'Invite your Goddess to come into you and merge with your Divine Self, and also connect your energy with the energy of all your bodies. Talk to her, ask her name.',
  );
  static const _part3Step17 = EnergyStep(
    'Ask that the process just completed become permanent.',
  );
  static const _last = EnergyStep(
    'Return to today, but continue to lie down for at least two hours.',
  );

  static const part1 = [
    _step1,
    _step2,
    _step3,
    _part1Step4,
    _part1Step5,
    _part1Step6,
    _part1Step7,
    _part1Step8,
    _part1Step9,
    _part1Step10,
    _part1Step11,
    _part1Step12,
    _part1Step13,
    _part1Step14,
  ];

  static const part2 = [
    _step1,
    _step2,
    _step3,
    _part2Step4,
    _part2Step5,
    _part1Step11,
    _part1Step12,
    _part2Step8,
    _part2Step9,
    _part2Step10,
    _part2Step11,
    _last,
  ];

  static const part3 = [
    _step1,
    _step2,
    _step3,
    _part2Step4,
    _part2Step5,
    _part1Step11,
    _part1Step12,
    _part2Step8,
    _part2Step9,
    _part2Step10,
    _part3Step11,
    _part3Step12,
    _part3Step13,
    _part3Step14,
    _part3Step15,
    _part3Step16,
    _part3Step17,
    _last,
  ];
}
