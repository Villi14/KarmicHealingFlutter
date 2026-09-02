import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'constants/app_colors.dart';
import 'constants/app_theme.dart';
import 'l10n/app_locales.dart';
import 'l10n/app_localizations.dart';
import 'data/app_database.dart';
import 'data/app_lock.dart';
import 'data/biometrics.dart';
import 'data/energy_settings.dart';
import 'data/reminder_notifications.dart';
import 'data/reminders_repository.dart';
import 'data/passcode.dart';
import 'data/repository_scope.dart';
import 'data/requests_repository.dart';
import 'data/seed_sample_data.dart';
import 'qa/qa_routes.dart';
import 'theme_controller.dart';
import 'screens/app_lock/app_lock_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/reminders/reminders_detail_screen.dart';
import 'widgets/gradient_background.dart';

/// The navigator a tapped notification reaches for, since it arrives from
/// outside the tree and has no context of its own.
final _navigatorKey = GlobalKey<NavigatorState>();

/// The same reason: the store has to be reachable from outside the tree to find
/// out which topic a tapped reminder belongs to.
RemindersRepository? _reminders;

/// Opens the topic a notification's reminder lives in.
///
/// The reminder may be gone by the time its notification is tapped — deleted on
/// another device, say — in which case nothing happens, which is the honest
/// answer to a tap on something that is no longer there.
void _openReminder(String reminderId) {
  final topicId = _reminders?.reminderById(reminderId)?.remindersListId;
  if (topicId == null) return;

  _navigatorKey.currentState?.push(
    MaterialPageRoute<void>(
      builder: (_) => RemindersDetailScreen(topicId: topicId),
    ),
  );
}

/// The locale the notification channel is named in — the app itself has not
/// been built yet when the channel is created, so the device is asked directly.
Locale _deviceLocale() =>
    AppLocales.resolve(PlatformDispatcher.instance.locales);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // A QA run must not touch the store the user keeps, nor put anything in the
  // notification tray, so it gets a store that lives only as long as the
  // process and no scheduler at all.
  final scheduler = qaScreen.isEmpty
      ? await LocalReminderScheduler.start(
          channelName: (await AppLocalizations.delegate.load(
            _deviceLocale(),
          )).reminders,
          onOpened: _openReminder,
        )
      : const NoReminderScheduler();

  final repositories = await loadRepositories(
    database: qaScreen.isEmpty ? null : await AppDatabase.openInMemory(),
    scheduler: scheduler,
  );
  if (seededQaScreens.contains(qaScreen)) {
    await seedSampleData(repositories.requests, repositories.reminders);
  }

  _reminders = repositories.reminders;

  runApp(
    KarmicHealingApp(
      controller: await ThemeController.load(),
      energySettings: await EnergySettings.load(),
      // A QA run gets a device that offers nothing and a code that lives only
      // as long as the process, so no screenshot waits behind a lock.
      appLock: await AppLockSettings.load(
        biometrics: qaScreen.isEmpty ? null : const UnavailableBiometrics(),
        passcode: qaScreen.isEmpty ? null : InMemoryPasscodeStore(),
      ),
      requests: repositories.requests,
      reminders: repositories.reminders,
    ),
  );

  if (scheduler is! LocalReminderScheduler) return;

  WidgetsBinding.instance.addPostFrameCallback((_) {
    // Both of these wait for the first frame: the permission sheet so it opens
    // over the app rather than over an empty window, and a notification tapped
    // while the app was closed because until now there was no navigator to
    // carry it anywhere.
    scheduler.requestPermission();

    final launched = scheduler.launchReminderId;
    if (launched != null) _openReminder(launched);
  });
}

class KarmicHealingApp extends StatelessWidget {
  const KarmicHealingApp({
    super.key,
    required this.controller,
    required this.energySettings,
    required this.appLock,
    required this.requests,
    required this.reminders,
  });

  final ThemeController controller;
  final EnergySettings energySettings;
  final AppLockSettings appLock;
  final RequestsRepository requests;
  final RemindersRepository reminders;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<ThemeMode>(
    valueListenable: controller,
    builder: (context, mode, _) => ThemeScope(
      controller: controller,
      child: RepositoryScope(
        requests: requests,
        reminders: reminders,
        child: EnergySettingsScope(
          settings: energySettings,
          child: AppLockScope(
            settings: appLock,
            child: MaterialApp(
              navigatorKey: _navigatorKey,
              onGenerateTitle: (context) =>
                  AppLocalizations.of(context).karmicHealing,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              localeListResolutionCallback: (preferred, _) =>
                  AppLocales.resolve(preferred),
              theme: appTheme(Brightness.light),
              darkTheme: appTheme(Brightness.dark),
              themeMode: mode,
              // The lock goes on the builder rather than on `home`: `home` is
              // only the first route, and a lock there left every pushed screen
              // above it on display. The builder wraps the navigator itself, so
              // nothing the app is guarding is on screen — or in the task
              // switcher's snapshot — until the lock opens.
              builder: (context, child) => AppLockGate(child: child!),
              home: const AppWrapper(),
              debugShowCheckedModeBanner: false,
            ),
          ),
        ),
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

    if (!mounted) return;
    setState(() {
      _hasCompletedOnboarding = hasCompleted;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (qaScreen.isNotEmpty) {
      final screen = buildQaScreen(context);
      if (screen != null) return screen;
    }

    if (_isLoading) {
      // The one moment before the first screen. On the aura like everything
      // after it, so the app does not open on a flash of bare white.
      return Scaffold(
        body: GradientBackground(
          tone: AppColors.of(context).health,
          child: Center(
            child: CircularProgressIndicator(
              color: AppColors.of(context).health,
            ),
          ),
        ),
      );
    }

    return _hasCompletedOnboarding
        ? const HomeScreen()
        : const OnboardingScreen();
  }
}
