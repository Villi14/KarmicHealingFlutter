import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/home/home_screen.dart';
import 'constants/app_colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize shared preferences
  await SharedPreferences.getInstance();

  runApp(const KarmicHealingApp());
}

class KarmicHealingApp extends StatelessWidget {
  const KarmicHealingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Karmic Healing',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.backgroundPrimary,
        fontFamily: '.SF Pro Text',
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.backgroundPrimary,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          centerTitle: true,
          scrolledUnderElevation: 0,
          titleTextStyle: TextStyle(
            color: AppColors.textPrimary,
            fontFamily: '.SF Pro Display',
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.friendly,
          brightness: Brightness.light,
        ),
        cupertinoOverrideTheme: const CupertinoThemeData(
          primaryColor: AppColors.clam,
          scaffoldBackgroundColor: AppColors.backgroundPrimary,
        ),
        cardTheme: CardThemeData(
          color: AppColors.backgroundSecondary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(20)),
          ),
        ),
      ),
      home: const AppWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AppWrapper extends StatefulWidget {
  const AppWrapper({super.key});

  @override
  State<AppWrapper> createState() => _AppWrapperState();
}

class _AppWrapperState extends State<AppWrapper> {
  bool _hasCompletedOnboarding = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkOnboardingStatus();
  }

  Future<void> _checkOnboardingStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final hasCompleted = prefs.getBool('onboarding_completed') ?? false;

    setState(() {
      _hasCompletedOnboarding = hasCompleted;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return _hasCompletedOnboarding
        ? const HomeScreen()
        : const OnboardingScreen();
  }
}
