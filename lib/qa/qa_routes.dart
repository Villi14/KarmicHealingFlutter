import 'package:flutter/widgets.dart';

import '../data/repository_scope.dart';
import '../data/session_effects.dart';
import '../l10n/app_localizations.dart';
import '../screens/balancing_energy/balancing_energy_list_screen.dart';
import '../screens/balancing_energy/balancing_energy_screen.dart';
import '../screens/balancing_energy/energy_settings_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/reminders/reminder_forms.dart';
import '../screens/reminders/reminders_detail_screen.dart';
import '../screens/reminders/reminders_screen.dart';
import '../screens/requests/request_detail_screen.dart';
import '../screens/requests/request_forms.dart';
import '../screens/requests/requests_help_screen.dart';
import '../screens/requests/requests_screen.dart';
import '../screens/settings/privacy_policy_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/settings/theme_settings_screen.dart';

const qaScreen = String.fromEnvironment('QA_SCREEN');

/// The QA screens that want a store with something in it. The rest are shot
/// against an empty one, which is the whole point of the empty states.
const seededQaScreens = {
  'requests_list',
  'request_detail',
  'request_form',
  'subrequest_form',
  'reminders_list',
  'reminders_detail',
  'reminder_form',
  'topic_form',
};

/// The screen a QA run was launched to photograph, wired to the seeded store
/// so the shot shows the app rather than a mock of it.
Widget? buildQaScreen(BuildContext context) {
  final requests = RepositoryScope.requestsOf(context);
  final reminders = RepositoryScope.remindersOf(context);

  switch (qaScreen) {
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
