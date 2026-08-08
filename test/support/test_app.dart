import 'package:flutter/material.dart';
import 'package:karmic_healing_flutter/l10n/app_localizations.dart';

/// The app shell a screen needs under test: every screen reads its text from
/// [AppLocalizations], so a bare [MaterialApp] would leave it with nothing to
/// read.
///
/// The locale is pinned to English rather than left to the host, so a test that
/// looks for a word finds the same word wherever it runs.
MaterialApp testApp({
  required Widget home,
  Locale locale = const Locale('en'),
  ThemeData? theme,
  ThemeData? darkTheme,
  ThemeMode? themeMode,
}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: locale,
  theme: theme,
  darkTheme: darkTheme,
  themeMode: themeMode ?? ThemeMode.system,
  home: home,
);
