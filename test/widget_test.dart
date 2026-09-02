// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:karmic_healing_flutter/data/energy_settings.dart';
import 'package:karmic_healing_flutter/main.dart';
import 'package:karmic_healing_flutter/theme_controller.dart';

import 'support/test_app_lock.dart';
import 'support/test_repositories.dart';

void main() {
  setUpAll(useTestDatabaseFactory);

  late TestRepositories repositories;
  setUp(() async => repositories = await emptyRepositories());

  testWidgets('shows onboarding on first launch', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      KarmicHealingApp(
        controller: ThemeController(),
        energySettings: await EnergySettings.load(),
        appLock: await testAppLock(),
        requests: repositories.requests,
        reminders: repositories.reminders,
      ),
    );

    // Verify that our counter starts at 0.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text("Based on Diana Stein's Book"), findsOneWidget);
  });
}
