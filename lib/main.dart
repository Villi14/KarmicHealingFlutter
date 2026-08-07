import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'constants/app_theme.dart';
import 'theme_controller.dart';
import 'screens/balancing_energy/balancing_energy_list_screen.dart';
import 'screens/balancing_energy/balancing_energy_screen.dart';
import 'screens/balancing_energy/energy_settings_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/reminders/reminder_forms.dart';
import 'screens/reminders/reminders_detail_screen.dart';
import 'screens/reminders/reminders_screen.dart';
import 'screens/requests/request_detail_screen.dart';
import 'screens/requests/request_forms.dart';
import 'screens/requests/requests_help_screen.dart';
import 'screens/requests/requests_screen.dart';
import 'screens/settings/privacy_policy_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/settings/theme_settings_screen.dart';

const _qaScreen = String.fromEnvironment('QA_SCREEN');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Initialize shared preferences
  await SharedPreferences.getInstance();

  runApp(KarmicHealingApp(controller: await ThemeController.load()));
}

class KarmicHealingApp extends StatelessWidget {
  const KarmicHealingApp({super.key, required this.controller});

  final ThemeController controller;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<ThemeMode>(
    valueListenable: controller,
    builder: (context, mode, _) => ThemeScope(
      controller: controller,
      child: MaterialApp(
        title: 'Karmic Healing',
        theme: appTheme(Brightness.light),
        darkTheme: appTheme(Brightness.dark),
        themeMode: mode,
        home: const AppWrapper(),
        debugShowCheckedModeBanner: false,
      ),
    ),
  );
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
    if (_qaScreen == 'home') return const HomeScreen();
    if (_qaScreen == 'energy_list') {
      return const BalancingEnergyListScreen();
    }
    if (_qaScreen == 'energy_help') {
      return const BalancingEnergyHelpScreen();
    }
    if (_qaScreen == 'energy_session') {
      return const BalancingEnergyScreen(
        title: 'Initial Process',
        steps: EnergySteps.part1,
      );
    }
    if (_qaScreen == 'energy_settings') {
      return const EnergySettingsScreen();
    }
    if (_qaScreen == 'requests_empty') return const RequestsScreen();
    if (_qaScreen == 'requests_list') {
      return const RequestsScreen(showSamples: true);
    }
    if (_qaScreen == 'request_detail') {
      return const RequestDetailScreen();
    }
    if (_qaScreen == 'subrequest_form') {
      return const SubrequestFormScreen();
    }
    if (_qaScreen == 'request_form') return const RequestFormScreen();
    if (_qaScreen == 'requests_help') return const RequestsHelpScreen();
    if (_qaScreen == 'reminders_empty') return const RemindersScreen();
    if (_qaScreen == 'reminders_list') {
      return const RemindersScreen(showSamples: true);
    }
    if (_qaScreen == 'reminders_detail') {
      return const RemindersDetailScreen();
    }
    if (_qaScreen == 'reminder_form') return const ReminderFormScreen();
    if (_qaScreen == 'topic_form') return const TopicFormScreen();
    if (_qaScreen == 'settings') return const SettingsScreen();
    if (_qaScreen == 'theme_settings') return const ThemeSettingsScreen();
    if (_qaScreen == 'privacy_policy') return const PrivacyPolicyScreen();

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return _hasCompletedOnboarding
        ? const HomeScreen()
        : const OnboardingScreen();
  }
}
