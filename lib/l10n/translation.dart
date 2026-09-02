import 'package:flutter/widgets.dart';

/// Which of the app's languages a person has actually read.
///
/// The rest were translated by machine. That is worth saying out loud rather
/// than hiding: the only people who can tell a wrong word from a right one are
/// the ones reading it, and they will only write in if they know the app would
/// welcome hearing from them.
abstract final class Translation {
  /// The languages the author can vouch for. The same three the Swift app
  /// vouches for, and the two lists are meant to move together — a language
  /// read through by a native speaker is added to both at once.
  static const reviewed = {'en', 'uk', 'ru'};

  /// Whether the words on screen came from a machine.
  ///
  /// Asked of the locale the app resolved to rather than of the one the device
  /// asked for: what matters is the language actually being read, which is not
  /// always the first the user requested.
  static bool isMachineTranslated(Locale locale) =>
      !reviewed.contains(locale.languageCode);
}
