import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karmic_healing_flutter/constants/app_colors.dart';
import 'package:karmic_healing_flutter/main.dart';
import 'package:karmic_healing_flutter/screens/settings/theme_settings_screen.dart';
import 'package:karmic_healing_flutter/theme_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('picking Dark repaints the app and is remembered', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final controller = ThemeController();

    await tester.pumpWidget(
      ThemeScope(
        controller: controller,
        child: MaterialApp(
          theme: ThemeData(brightness: Brightness.light),
          darkTheme: ThemeData(brightness: Brightness.dark),
          themeMode: ThemeMode.light,
          home: const ThemeSettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();

    expect(controller.value, ThemeMode.dark);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(ThemeController.storageKey), 'dark');
  });

  testWidgets('a stored choice is what the app launches in', (tester) async {
    SharedPreferences.setMockInitialValues({ThemeController.storageKey: 'dark'});

    final controller = await ThemeController.load();
    await tester.pumpWidget(KarmicHealingApp(controller: controller));
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(Scaffold).first);
    expect(Theme.of(context).brightness, Brightness.dark);
    expect(AppColors.of(context).isDark, isTrue);
  });
}
