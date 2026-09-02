import 'package:flutter/widgets.dart';

import 'app_localizations.dart';

/// Which of the app's fifteen languages a device gets, and what it gets when it
/// asks for none of them.
abstract final class AppLocales {
  /// The language the app falls back on.
  ///
  /// Named rather than taken as the first of `supportedLocales`, which Flutter
  /// would otherwise fall back to: that list is alphabetical by ARB file, and
  /// as the twelve new languages arrived its first entry became Bengali.
  static const fallback = Locale('en');

  /// The first language the device asks for that the app can answer in.
  ///
  /// Matched on the language alone, so a device set to Austrian German or
  /// Brazilian Portuguese is answered by the German or the Portuguese the app
  /// has rather than falling through to English.
  static Locale resolve(List<Locale>? preferred) {
    for (final locale in preferred ?? const <Locale>[]) {
      for (final supported in AppLocalizations.supportedLocales) {
        if (supported.languageCode == locale.languageCode) return supported;
      }
    }
    return fallback;
  }
}
