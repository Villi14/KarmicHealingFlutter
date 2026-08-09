import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'constants/app_colors.dart';
import 'constants/app_theme.dart';
import 'l10n/app_localizations.dart';
import 'data/app_database.dart';
import 'data/energy_settings.dart';
import 'data/reminder_notifications.dart';
import 'data/reminders_repository.dart';
import 'data/repository_scope.dart';
import 'data/requests_repository.dart';
import 'data/seed_sample_data.dart';
import 'data/session_effects.dart';
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
import 'widgets/gradient_background.dart';

const _qaScreen = String.fromEnvironment('QA_SCREEN');

/// The QA screens that want a store with something in it. The rest are shot
/// against an empty one, which is the whole point of the empty states.
const _seededQaScreens = {
  'requests_list',
  'request_detail',
  'request_form',
  'subrequest_form',
  'reminders_list',
  'reminders_detail',
  'reminder_form',
  'topic_form',
};

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
Locale _deviceLocale() {
  for (final locale in PlatformDispatcher.instance.locales) {
    for (final supported in AppLocalizations.supportedLocales) {
      if (supported.languageCode == locale.languageCode) return supported;
    }
  }
  return AppLocalizations.supportedLocales.first;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Initialize shared preferences
  await SharedPreferences.getInstance();

  // A QA run must not touch the store the user keeps, nor put anything in the
  // notification tray, so it gets a store that lives only as long as the
  // process and no scheduler at all.
  final scheduler = _qaScreen.isEmpty
      ? await LocalReminderScheduler.start(
          channelName: (await AppLocalizations.delegate.load(
            _deviceLocale(),
          )).reminders,
          onOpened: _openReminder,
        )
      : const NoReminderScheduler();

  final repositories = await loadRepositories(
    database: _qaScreen.isEmpty ? null : await AppDatabase.openInMemory(),
    scheduler: scheduler,
  );
  if (_seededQaScreens.contains(_qaScreen)) {
    await seedSampleData(repositories.requests, repositories.reminders);
  }

  _reminders = repositories.reminders;

  runApp(
    KarmicHealingApp(
      controller: await ThemeController.load(),
      energySettings: await EnergySettings.load(),
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
    required this.requests,
    required this.reminders,
  });

  final ThemeController controller;
  final EnergySettings energySettings;
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
          child: MaterialApp(
            navigatorKey: _navigatorKey,
            onGenerateTitle: (context) =>
                AppLocalizations.of(context).karmicHealing,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: appTheme(Brightness.light),
            darkTheme: appTheme(Brightness.dark),
            themeMode: mode,
            home: const AppWrapper(),
            debugShowCheckedModeBanner: false,
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

    setState(() {
      _hasCompletedOnboarding = hasCompleted;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_qaScreen.isNotEmpty) {
      final screen = _qaBuild(context);
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

  /// The screen a QA run was launched to photograph, wired to the seeded store
  /// so the shot shows the app rather than a mock of it.
  Widget? _qaBuild(BuildContext context) {
    final requests = RepositoryScope.requestsOf(context);
    final reminders = RepositoryScope.remindersOf(context);

    switch (_qaScreen) {
      case 'home':
        return const HomeScreen();
      case 'energy_list':
        return const BalancingEnergyListScreen();
      case 'energy_help':
        return const BalancingEnergyHelpScreen();
      case 'energy_session':
        final l10n = AppLocalizations.of(context);
        return BalancingEnergyScreen(
          kind: SessionKind.initialProcess,
          title: SessionKind.initialProcess.title(l10n),
          steps: SessionKind.initialProcess.steps(l10n),
          // A run that is only here to take a photograph must not dim the
          // screen out from under the camera, nor chime at whoever is watching.
          effects: const NoSessionEffects(),
        );
      case 'energy_settings':
        return const EnergySettingsScreen();
      case 'requests_empty':
      case 'requests_list':
        return const RequestsScreen();
      case 'request_detail':
        return RequestDetailScreen(requestId: requests.requests.first.id);
      case 'subrequest_form':
        return SubrequestFormScreen(
          subrequest: requests.draftSubrequest(requests.requests.first.id),
        );
      case 'request_form':
        return const RequestFormScreen();
      case 'requests_help':
        return const RequestsHelpScreen();
      case 'reminders_empty':
      case 'reminders_list':
        return const RemindersScreen();
      case 'reminders_detail':
        return RemindersDetailScreen(topicId: reminders.topics.first.id);
      case 'reminder_form':
        return ReminderFormScreen(topicId: reminders.topics.first.id);
      case 'topic_form':
        return const TopicFormScreen();
      case 'settings':
        return const SettingsScreen();
      case 'theme_settings':
        return const ThemeSettingsScreen();
      case 'privacy_policy':
        return const PrivacyPolicyScreen();
      default:
        return null;
    }
  }
}
