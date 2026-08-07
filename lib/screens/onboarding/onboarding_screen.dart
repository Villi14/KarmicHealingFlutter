import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../constants/app_colors.dart';
import '../../widgets/aura_widgets.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/sf_symbols.dart';
import '../home/home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _current = 0;

  static const _steps = [
    _Step(
      SFSymbols.book,
      "Based on Diana Stein's Book",
      "This app is a supplement to the Russian edition 'Karmic Healing', which is a translation of the English edition 'Psychic Healing with Spirit Guides and Angels' by Diana Stein.",
    ),
    _Step(
      SFSymbols.sparkles,
      'Your Spiritual Companion',
      'Transform the teachings from the book into regular practice. Track your healing journey, manage requests, and work with the Lords of Karma step by step.',
    ),
    _Step(
      SFSymbols.heart,
      'Karmic Healing Process',
      'Learn to work with the Lords of Karma through guided requests. Heal relationships, overcome negative traits, and transform life situations with their guidance.',
    ),
    _Step(
      SFSymbols.staroflife,
      'Begin Your Transformation',
      'Change your past, present, and future with the help of the Lords of Karma. Start your journey of spiritual healing and personal transformation today.',
    ),
  ];

  AuraLevel get _level {
    final index = (_current / (_steps.length - 1) * 6).round();
    return AuraLevel.values[index];
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: GradientBackground(
      tone: _level.color,
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Column(
              children: [
                SizedBox(
                  height: 60,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: _current == 0
                        ? TextButton(
                            onPressed: _complete,
                            child: const Text(
                              'Skip',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          )
                        : const SizedBox(width: 64),
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: _steps.length,
                    onPageChanged: (value) => setState(() => _current = value),
                    itemBuilder: (context, index) => _StepView(
                      step: _steps[index],
                      level: AuraLevel.values[(index / 3 * 6).round()],
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _steps.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: index == _current
                            ? _level.color
                            : AppColors.textSecondary.withValues(alpha: .25),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      if (_current > 0)
                        AuraButton(
                          label: 'Back',
                          level: _level,
                          onPressed: _back,
                        ),
                      const Spacer(),
                      AuraButton(
                        label: _current == _steps.length - 1 ? 'Done' : 'Next',
                        level: _level,
                        onPressed: _next,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  void _next() {
    if (_current == _steps.length - 1) {
      _complete();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  void _back() => _controller.previousPage(
    duration: const Duration(milliseconds: 350),
    curve: Curves.easeInOut,
  );

  Future<void> _complete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    if (!mounted) return;
    await Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
      (_) => false,
    );
  }
}

class _StepView extends StatelessWidget {
  const _StepView({required this.step, required this.level});
  final _Step step;
  final AuraLevel level;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Column(
      children: [
        SizedBox(
          height: 92,
          child: Stack(
            alignment: Alignment.center,
            children: [
              AuraRings(level: level, size: 92, opacity: .35),
              AuraIcon(step.icon, level: level, size: 30),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          step.title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            // Source Serif 4 is the bundled cross-platform counterpart to New York.
            fontFamily: 'Source Serif 4',
            fontSize: 28,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          step.description,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 17,
            height: 1.55,
          ),
        ),
      ],
    ),
  );
}

class _Step {
  const _Step(this.icon, this.title, this.description);
  final IconData icon;
  final String title;
  final String description;
}
