import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Which appearance the app follows, and where that choice is kept.
///
/// The stored values match the SwiftUI app's — `user_theme`, holding
/// `system`, `light` or `dark` — so the same preference survives a device
/// moving between the two.
class ThemeController extends ValueNotifier<ThemeMode> {
  ThemeController([super.mode = ThemeMode.system]);

  static const storageKey = 'user_theme';

  /// Reads the stored choice, falling back to following the system.
  static Future<ThemeController> load() async {
    final prefs = await SharedPreferences.getInstance();
    return ThemeController(_modeFromName(prefs.getString(storageKey)));
  }

  Future<void> setMode(ThemeMode mode) async {
    if (mode == value) return;
    value = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(storageKey, _nameOf(mode));
  }

  static ThemeMode _modeFromName(String? name) => switch (name) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };

  static String _nameOf(ThemeMode mode) => switch (mode) {
    ThemeMode.light => 'light',
    ThemeMode.dark => 'dark',
    ThemeMode.system => 'system',
  };
}

/// Hands the controller to the settings screen that changes it, from wherever
/// in the navigation stack that screen was pushed.
class ThemeScope extends InheritedNotifier<ThemeController> {
  const ThemeScope({
    super.key,
    required ThemeController controller,
    required super.child,
  }) : super(notifier: controller);

  static ThemeController of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ThemeScope>()!.notifier!;
}
