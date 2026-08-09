import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../constants/app_colors.dart';
import '../../l10n/app_localizations.dart';
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

  /// How many pages the onboarding has. Kept apart from the pages themselves,
  /// which need a [BuildContext] to read their text.
  static const _stepCount = 4;

  static List<_Step> _steps(AppLocalizations l10n) => [
    _Step(
      SFSymbols.book,
      l10n.onboardingBookTitle,
      l10n.onboardingBookDescription,
    ),
    _Step(
      SFSymbols.sparkles,
      l10n.onboardingAppTitle,
      l10n.onboardingAppDescription,
    ),
    _Step(
      SFSymbols.heart,
      l10n.onboardingHealingTitle,
      l10n.onboardingHealingDescription,
    ),
    _Step(
      SFSymbols.staroflife,
      l10n.onboardingJourneyTitle,
      l10n.onboardingJourneyDescription,
    ),
  ];

  AuraLevel get _level {
    final index = (_current / (_stepCount - 1) * 6).round();
    return AuraLevel.values[index];
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final steps = _steps(l10n);

    return Scaffold(
      body: GradientBackground(
        tone: _level.color(context),
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
                              child: Text(
                                l10n.skip,
                                style: TextStyle(
                                  color: AppColors.of(context).textSecondary,
                                ),
                              ),
                            )
                          : const SizedBox(width: 64),
                    ),
                  ),
                  Expanded(
                    child: PageView.builder(
                      controller: _controller,
                      itemCount: steps.length,
                      onPageChanged: (value) =>
                          setState(() => _current = value),
                      itemBuilder: (context, index) => _StepView(
                        step: steps[index],
                        level: AuraLevel.values[(index / 3 * 6).round()],
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _stepCount,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: index == _current
                              ? _level.color(context)
                              : AppColors.of(
                                  context,
                                ).textSecondary.withValues(alpha: .25),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    // The buttons share the row evenly so a long translation
                    // wraps inside its own half instead of crowding the other.
                    child: Row(
                      spacing: 12,
                      children: [
                        if (_current > 0)
                          Expanded(
                            child: AuraButton(
                              label: l10n.back,
                              level: _level,
                              onPressed: _back,
                            ),
                          ),
                        Expanded(
                          child: AuraButton(
                            label: _current == _stepCount - 1
                                ? l10n.done
                                : l10n.next,
                            level: _level,
                            onPressed: _next,
                          ),
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
  }

  void _next() {
    if (_current == _stepCount - 1) {
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
          style: TextStyle(
            // Source Serif 4 is the bundled cross-platform counterpart to New York.
            fontFamily: 'Source Serif 4',
            fontSize: 28,
            color: AppColors.of(context).textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          step.description,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.of(context).textSecondary,
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
