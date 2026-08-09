import 'package:flutter/material.dart';
import 'package:karmic_healing_flutter/data/energy_settings.dart';
import 'package:karmic_healing_flutter/l10n/app_localizations.dart';

/// The app shell a screen needs under test: every screen reads its text from
/// [AppLocalizations], so a bare [MaterialApp] would leave it with nothing to
/// read.
///
/// The locale is pinned to English rather than left to the host, so a test that
/// looks for a word finds the same word wherever it runs.
///
/// A screen that reads the meditation settings is given [energySettings] to
/// read them from; the rest need none, and are left without the scope.
Widget testApp({
  required Widget home,
  Locale locale = const Locale('en'),
  ThemeData? theme,
  ThemeData? darkTheme,
  ThemeMode? themeMode,
  EnergySettings? energySettings,
}) {
  final app = MaterialApp(
    debugShowCheckedModeBanner: false,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: locale,
    theme: theme,
    darkTheme: darkTheme,
    themeMode: themeMode ?? ThemeMode.system,
    // Under test the app is told to hold its ambient motion still, as a device
    // asking for reduced motion would. The session ring breathes for as long
    // as it is on screen, and a tree with a never-ending animation in it is a
    // tree [WidgetTester.pumpAndSettle] can never settle. Applied through the
    // builder so it reaches pushed routes too, not only [home].
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: true),
      child: child!,
    ),
    home: home,
  );

  return energySettings == null
      ? app
      : EnergySettingsScope(settings: energySettings, child: app);
}
