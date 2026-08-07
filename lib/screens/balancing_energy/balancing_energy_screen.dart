import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/aura_widgets.dart';
import '../../constants/design_constants.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_strings.dart';

class BalancingEnergyScreen extends StatefulWidget {
  final String title;
  final List<EnergyStep> steps;
  final VoidCallback? onCompleted;

  const BalancingEnergyScreen({
    super.key,
    required this.title,
    required this.steps,
    this.onCompleted,
  });

  @override
  State<BalancingEnergyScreen> createState() => _BalancingEnergyScreenState();
}

class _BalancingEnergyScreenState extends State<BalancingEnergyScreen>
    with WidgetsBindingObserver {
  late PageController _pageController;
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
      _handleElapsedSteps();
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
      _handleElapsedSteps();
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
      0.0,
      1.0,
    );
  }

  void _handleElapsedSteps() {
    if (_isPaused) return;
    final elapsed = DateTime.now().difference(_stepStartedAt);
    if (elapsed < _stepDuration) return;
    final elapsedSteps = elapsed.inMilliseconds ~/ _stepDuration.inMilliseconds;
    final target = (_currentStep + elapsedSteps).clamp(
      0,
      widget.steps.length - 1,
    );
    _stepStartedAt = _stepStartedAt.add(_stepDuration * elapsedSteps);
    if (target != _currentStep) {
      _pageController.animateToPage(
        target,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _restartStepTimer() {
    _stepStartedAt = DateTime.now();
    _pausedRemaining = _stepDuration;
  }

  void _togglePause() {
    setState(() {
      if (_isPaused) {
        _stepStartedAt = DateTime.now().subtract(
          _stepDuration - _pausedRemaining,
        );
      } else {
        _pausedRemaining = _remaining;
      }
      _isPaused = !_isPaused;
    });
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(widget.title),
        backgroundColor: Colors.transparent,
        border: null,
        leading: CupertinoButton(
          onPressed: () => Get.back(),
          child: const Icon(CupertinoIcons.back, color: AppColors.clam),
        ),
      ),
      child: GradientBackground(
        tone: _sessionLevel.color,
        child: SafeArea(
          child: Column(
            children: [
              _buildAttentionBanner(),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentStep = index;
                      _restartStepTimer();
                    });
                  },
                  itemCount: widget.steps.length,
                  itemBuilder: (context, index) {
                    return _buildStepContent(widget.steps[index]);
                  },
                ),
              ),
              _buildStepIndicator(),
              if (_currentStep < widget.steps.length - 1) _buildTimerBadge(),
              _buildNavigationButtons(),
            ],
          ),
        ),
      ),
    );
  }

  AuraLevel get _sessionLevel {
    if (widget.steps.length <= 1) return AuraLevel.root;
    final value = (_currentStep / (widget.steps.length - 1) * 6).round();
    return AuraLevel.values[value.clamp(0, 6)];
  }

  Widget _buildAttentionBanner() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Text(
        AppStrings.attentionBeforeProceeding,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: .8,
          color: _sessionLevel.color,
        ),
      ),
    );
  }

  Widget _buildStepContent(EnergyStep step) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
      child: AuraCard(
        level: _sessionLevel,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'STEP ${_currentStep + 1} OF ${widget.steps.length}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: _sessionLevel.color,
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: AuraRings(level: _sessionLevel, size: 78, core: true),
            ),
            const SizedBox(height: 24),
            Text(
              step.title,
              style: const TextStyle(
                fontFamily: '.SF Pro Display',
                fontSize: 24,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: DesignConstants.spacing),
            Text(
              step.description,
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),

            if (step.instructions.isNotEmpty) ...[
              const SizedBox(height: DesignConstants.spacingLarge),
              Container(
                padding: const EdgeInsets.all(DesignConstants.paddingLarge),
                decoration: BoxDecoration(
                  color: _sessionLevel.color.withValues(alpha: .07),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Instructions:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: DesignConstants.padding),
                    ...step.instructions.map(
                      (instruction) => Padding(
                        padding: const EdgeInsets.only(
                          bottom: DesignConstants.paddingSmall,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '• ',
                              style: TextStyle(
                                fontSize: 16,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                instruction,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Padding(
      padding: const EdgeInsets.all(DesignConstants.paddingLarge),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 4,
        runSpacing: 4,
        children: List.generate(
          widget.steps.length,
          (index) => Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              color: index <= _currentStep
                  ? _sessionLevel.color
                  : AppColors.textSecondary.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimerBadge() {
    final totalSeconds = _remaining.inSeconds;
    final time =
        '${totalSeconds ~/ 60}:${(totalSeconds % 60).toString().padLeft(2, '0')}';
    return Semantics(
      label: _isPaused ? 'Session paused' : 'Next step in $time',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              value: _isPaused ? 1 : _timerProgress,
              strokeWidth: 2,
              color: AppColors.clam,
              backgroundColor: AppColors.clam.withValues(alpha: 0.2),
            ),
          ),
          const SizedBox(width: DesignConstants.padding),
          Text(
            _isPaused ? 'Paused' : 'Next step in $time',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          IconButton(
            onPressed: _togglePause,
            tooltip: _isPaused ? 'Resume' : 'Pause',
            icon: Icon(_isPaused ? Icons.play_arrow : Icons.pause),
            color: AppColors.clam,
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Padding(
      padding: const EdgeInsets.all(DesignConstants.paddingLarge),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: CupertinoButton(
                onPressed: _previousStep,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: DesignConstants.paddingLarge,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.clam),
                    borderRadius: BorderRadius.circular(
                      DesignConstants.cornerRadiusMedium,
                    ),
                  ),
                  child: const Center(
                    child: Text(
                      AppStrings.back,
                      style: TextStyle(
                        color: AppColors.clam,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),

          if (_currentStep > 0) const SizedBox(width: DesignConstants.padding),

          AuraButton(
            label: _currentStep == widget.steps.length - 1
                ? AppStrings.done
                : AppStrings.next,
            level: _sessionLevel,
            onPressed: _nextStep,
          ),
        ],
      ),
    );
  }

  void _nextStep() {
    if (_currentStep < widget.steps.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeProcess();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _completeProcess() {
    _ticker?.cancel();
    widget.onCompleted?.call();
    Get.back();
  }
}

class EnergyStep {
  final String title;
  final String description;
  final List<String> instructions;
  final IconData? icon;

  EnergyStep({
    required this.title,
    required this.description,
    this.instructions = const [],
    this.icon,
  });
}

class EnergySteps {
  static final List<EnergyStep> part1 = [
    EnergyStep(
      title: 'Prepare Your Space',
      description:
          'Find a quiet, comfortable place where you won\'t be disturbed.',
      instructions: [
        'Turn off your phone or put it in another room',
        'Dim the lights or use natural lighting',
        'Sit or lie down in a comfortable position',
        'Close your eyes and take three deep breaths',
      ],
      icon: Icons.home,
    ),
    EnergyStep(
      title: 'Ground Yourself',
      description: 'Connect with the earth and center your energy.',
      instructions: [
        'Imagine roots growing from your feet into the earth',
        'Feel the earth\'s energy flowing up through your body',
        'Visualize a warm, golden light surrounding you',
        'Take slow, deep breaths for 2-3 minutes',
      ],
      icon: Icons.eco,
    ),
    EnergyStep(
      title: 'Set Your Intention',
      description: 'Clearly state what you want to achieve from this session.',
      instructions: [
        'Think about what you want to heal or balance',
        'Say out loud or in your mind: "I intend to balance my energy"',
        'Feel gratitude for this opportunity to heal',
        'Release any expectations and be open to what comes',
      ],
      icon: Icons.psychology,
    ),
  ];

  static final List<EnergyStep> part2 = [
    EnergyStep(
      title: 'Connect with Your Essential Self',
      description: 'Access the core of who you truly are.',
      instructions: [
        'Place your hand over your heart',
        'Feel your heartbeat and breathe with it',
        'Ask yourself: "Who am I at my core?"',
        'Listen for the answer without judgment',
      ],
      icon: Icons.favorite,
    ),
    EnergyStep(
      title: 'Release Old Patterns',
      description: 'Let go of limiting beliefs and patterns.',
      instructions: [
        'Identify one pattern you want to release',
        'Visualize it as a dark cloud leaving your body',
        'Say: "I release this pattern with love"',
        'Feel the lightness as it leaves',
      ],
      icon: Icons.cloud_off,
    ),
  ];

  static final List<EnergyStep> part3 = [
    EnergyStep(
      title: 'Connect with Your Divine Self',
      description: 'Access your highest, most spiritual aspect.',
      instructions: [
        'Imagine a beam of light from above entering your crown',
        'Feel this divine energy flowing through your body',
        'Ask: "What does my Divine Self want me to know?"',
        'Listen for guidance and wisdom',
      ],
      icon: Icons.wb_sunny,
    ),
    EnergyStep(
      title: 'Integrate and Ground',
      description: 'Bring the energy work into your daily life.',
      instructions: [
        'Feel the energy settling into your body',
        'Visualize yourself carrying this energy throughout your day',
        'Set an intention for how you\'ll use this energy',
        'Slowly open your eyes and return to the present',
      ],
      icon: Icons.self_improvement,
    ),
  ];
}
