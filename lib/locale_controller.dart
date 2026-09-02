import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'l10n/app_locales.dart';
import 'l10n/app_localizations.dart';

/// Which language the app speaks, and where that choice is kept.
///
/// The app used to speak whatever the device did and nothing else, sending
/// anyone who wanted another language out to the system settings. That works on
/// iOS, and on Android 13 and up, where a per-app language screen exists; on
/// every older Android there is no such screen and the journey ended nowhere.
/// So the choice is made here instead, and it holds on every device.
///
/// A value of `null` means the app follows the device, which is what it did
/// before anyone chose otherwise and what it goes back to when they choose
/// [systemName].
///
/// The stored key matches the SwiftUI app's `user_language`, so the same
/// preference means the same thing on both. What it holds is a language code —
/// `uk`, `ja` — or [systemName].
class LocaleController extends ValueNotifier<Locale?> {
  LocaleController([super.locale]);

  static const storageKey = 'user_language';

  /// What is stored for "follow the device". Anything else is a language code.
  static const systemName = 'system';

  /// Reads the stored choice, falling back to following the device.
  ///
  /// A stored language the app no longer speaks — one dropped between two
  /// releases — reads as no choice at all rather than as a language nobody can
  /// be shown.
  static Future<LocaleController> load() async {
    final prefs = await SharedPreferences.getInstance();
    return LocaleController(_localeFromName(prefs.getString(storageKey)));
  }

  /// The languages a person can pick, in the order the picker lists them.
  static List<Locale> get choices => AppLocalizations.supportedLocales;

  Future<void> setLocale(Locale? locale) async {
    if (locale == value) return;
    value = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(storageKey, locale?.languageCode ?? systemName);
  }

  static Locale? _localeFromName(String? name) {
    if (name == null || name == systemName) return null;
    for (final supported in AppLocalizations.supportedLocales) {
      if (supported.languageCode == name) return supported;
    }
    return null;
  }

  /// Each language's name written in that language, which is the one name a
  /// reader looking for their own can recognise on a screen they cannot read.
  static const names = <String, String>{
    'bn': 'বাংলা',
    'de': 'Deutsch',
    'en': 'English',
    'es': 'Español',
    'fr': 'Français',
    'hi': 'हिन्दी',
    'it': 'Italiano',
    'ja': '日本語',
    'ko': '한국어',
    'pl': 'Polski',
    'pt': 'Português',
    'ru': 'Русский',
    'tr': 'Türkçe',
    'uk': 'Українська',
    'zh': '中文',
  };

  /// What to call [locale] in the picker, falling back to its code so that a
  /// language added to the ARB files but not to [names] is still pickable.
  static String nameOf(Locale locale) =>
      names[locale.languageCode] ?? locale.languageCode;

  /// The language the app is actually speaking: the chosen one, or the first
  /// one the device asks for that the app can answer in.
  static Locale resolved(Locale? chosen) =>
      chosen ?? AppLocales.resolve(PlatformDispatcher.instance.locales);
}

/// Hands the controller to the settings screen that changes it, from wherever
/// in the navigation stack that screen was pushed.
class LocaleScope extends InheritedNotifier<LocaleController> {
  const LocaleScope({
    super.key,
    required LocaleController controller,
    required super.child,
  }) : super(notifier: controller);

  static LocaleController of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<LocaleScope>()!.notifier!;
}
