import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karmic_healing_flutter/data/energy_settings.dart';
import 'package:karmic_healing_flutter/data/repository_scope.dart';
import 'package:karmic_healing_flutter/data/seed_sample_data.dart';
import 'package:karmic_healing_flutter/data/session_effects.dart';
import 'package:karmic_healing_flutter/l10n/app_localizations.dart';
import 'package:karmic_healing_flutter/screens/balancing_energy/balancing_energy_list_screen.dart';
import 'package:karmic_healing_flutter/screens/balancing_energy/balancing_energy_screen.dart';
import 'package:karmic_healing_flutter/screens/balancing_energy/energy_settings_screen.dart';
import 'package:karmic_healing_flutter/screens/home/home_screen.dart';
import 'package:karmic_healing_flutter/screens/onboarding/onboarding_screen.dart';
import 'package:karmic_healing_flutter/screens/reminders/reminder_forms.dart';
import 'package:karmic_healing_flutter/screens/reminders/reminders_detail_screen.dart';
import 'package:karmic_healing_flutter/screens/reminders/reminders_screen.dart';
import 'package:karmic_healing_flutter/screens/requests/request_detail_screen.dart';
import 'package:karmic_healing_flutter/screens/requests/request_forms.dart';
import 'package:karmic_healing_flutter/screens/requests/requests_help_screen.dart';
import 'package:karmic_healing_flutter/screens/requests/requests_screen.dart';
import 'package:karmic_healing_flutter/screens/settings/privacy_policy_screen.dart';
import 'package:karmic_healing_flutter/screens/settings/settings_screen.dart';
import 'package:karmic_healing_flutter/screens/settings/theme_settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:karmic_healing_flutter/theme_controller.dart';

import 'support/test_app.dart';
import 'support/test_app_lock.dart';
import 'support/test_repositories.dart';

/// Every screen, laid out in the window a tablet gives it on its side.
///
/// The app turns with a tablet but not with a phone, so these are the widest
/// and shortest windows it has to hold: an iPad mini, a 11" and a 13" iPad, and
/// the 4:3 Android tablet, all of them short enough that a screen laid out for
/// a phone's height has nowhere to put the overflow.
void main() {
  setUpAll(useTestDatabaseFactory);

  late TestRepositories repositories;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    repositories = await emptyRepositories();
  });

  const landscapes = [
    Size(1133, 744), // iPad mini
    Size(1194, 834), // iPad Pro 11"
    Size(1366, 1024), // iPad Pro 13"
    Size(1024, 768), // the 4:3 tablet
    Size(1280, 800), // the 16:10 Android tablet
    Size(960, 600), // a Pixel Tablet — the shortest window the app turns in
  ];

  /// Pumps [screen] into a window of [size] and hands back whatever the layout
  /// threw — an overflow among it.
  Future<void> pump(WidgetTester tester, Size size, Widget screen) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ThemeScope(
        controller: ThemeController(),
        child: RepositoryScope(
          requests: repositories.requests,
          reminders: repositories.reminders,
          child: testApp(
            home: screen,
            energySettings: await tester.runAsync(EnergySettings.load),
            appLock: await tester.runAsync(testAppLock),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    // A screen that measures itself settles into its second arrangement on the
    // frame after the first.
    await tester.pump();
  }

  /// The screens that read an empty store, by the name their failure is
  /// reported under.
  final screens = <String, Widget Function(BuildContext)>{
    'home': (_) => const HomeScreen(),
    'onboarding': (_) => const OnboardingScreen(),
    'energy list': (_) => const BalancingEnergyListScreen(),
    'energy help': (_) => const BalancingEnergyHelpScreen(),
    'energy session': (context) {
      final l10n = AppLocalizations.of(context);
      return BalancingEnergyScreen(
        kind: SessionKind.initialProcess,
        title: SessionKind.initialProcess.title(l10n),
        steps: SessionKind.initialProcess.steps(l10n),
        // Nothing under test wants the screen dimmed or a chime sounded.
        effects: const NoSessionEffects(),
      );
    },
    'energy settings': (_) => const EnergySettingsScreen(),
    'requests': (_) => const RequestsScreen(),
    'request form': (_) => const RequestFormScreen(),
    'requests help': (_) => const RequestsHelpScreen(),
    'reminders': (_) => const RemindersScreen(),
    'topic form': (_) => const TopicFormScreen(),
    'settings': (_) => const SettingsScreen(),
    'theme settings': (_) => const ThemeSettingsScreen(),
    'privacy policy': (_) => const PrivacyPolicyScreen(),
  };

  for (final size in landscapes) {
    for (final entry in screens.entries) {
      testWidgets('${entry.key} lays out at $size', (tester) async {
        await pump(
          tester,
          size,
          Builder(builder: (context) => entry.value(context)),
        );
        expect(tester.takeException(), isNull);
      });
    }

    // The screens that need something in the store to draw at all.
    testWidgets('the seeded screens lay out at $size', (tester) async {
      await tester.runAsync(
        () => seedSampleData(repositories.requests, repositories.reminders),
      );

      for (final screen in [
        RequestDetailScreen(requestId: repositories.requests.requests.first.id),
        RemindersDetailScreen(topicId: repositories.reminders.topics.first.id),
        ReminderFormScreen(topicId: repositories.reminders.topics.first.id),
        SubrequestFormScreen(
          subrequest: repositories.requests.draftSubrequest(
            repositories.requests.requests.first.id,
          ),
        ),
      ]) {
        await pump(tester, size, screen);
        expect(tester.takeException(), isNull, reason: '$screen at $size');
      }
    });
  }
}
