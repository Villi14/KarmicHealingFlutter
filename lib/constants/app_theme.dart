import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';

/// Status bar ink for a page of the given appearance: dark glyphs on a light
/// page, light glyphs on a dark one.
SystemUiOverlayStyle statusBarStyle(Brightness brightness) =>
    brightness == Brightness.dark
    ? SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarContrastEnforced: false,
      )
    : SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarContrastEnforced: false,
      );

/// A fill that only appears under the chosen day, hour or year.
WidgetStateProperty<Color?> _selected(Color color, {Color? unselected}) =>
    WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.selected) ? color : unselected,
    );

/// Ink over that fill: dark on the spectrum, which stays light enough in both
/// appearances to carry it, and [rest] everywhere else.
WidgetStateProperty<Color?> _selectedInk(Color rest) =>
    WidgetStateProperty.resolveWith(
      (states) =>
          states.contains(WidgetState.selected) ? AppColors.onAccent : rest,
    );

/// The same choice as a plain colour, for the time picker, whose slots take a
/// [Color] rather than a property and resolve it per state themselves.
WidgetStateColor _ink({required Color selected, required Color rest}) =>
    WidgetStateColor.resolveWith(
      (states) => states.contains(WidgetState.selected) ? selected : rest,
    );

/// The one [ThemeData] the app wears, built twice — once per appearance.
///
/// Only the two entries that widgets read off the theme rather than off
/// [AppColors] live here: the page colour behind every route, and the
/// navigation bar, which is transparent everywhere so the frosted backdrop
/// behind it can show through.
ThemeData appTheme(Brightness brightness) {
  final colors = AppColors.forBrightness(brightness);
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    scaffoldBackgroundColor: colors.backgroundPrimary,
    fontFamily: 'Inter',
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: colors.textPrimary,
      elevation: 0,
      centerTitle: true,
      scrolledUnderElevation: 0,
      // A transparent bar leaves Material guessing at the status bar's ink, so
      // the page's own appearance says it instead.
      systemOverlayStyle: statusBarStyle(brightness),
      titleTextStyle: TextStyle(
        color: colors.textPrimary,
        fontFamily: 'Inter',
        fontSize: 17,
        fontWeight: FontWeight.w600,
      ),
    ),
    colorScheme: ColorScheme.fromSeed(
      seedColor: colors.friendly,
      brightness: brightness,
      surface: colors.backgroundPrimary,
      onSurface: colors.textPrimary,
    ),
    cupertinoOverrideTheme: CupertinoThemeData(
      brightness: brightness,
      primaryColor: colors.clam,
      scaffoldBackgroundColor: colors.backgroundPrimary,
    ),
    // A menu dropped from a row is a piece of the same paper the row is on:
    // Material 3 would otherwise tint it towards the seed colour and leave a
    // lilac panel over the card it came out of.
    popupMenuTheme: PopupMenuThemeData(
      color: colors.backgroundSecondary,
      surfaceTintColor: Colors.transparent,
      elevation: 8,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(14)),
      ),
      textStyle: TextStyle(
        color: colors.textPrimary,
        fontFamily: 'Inter',
        fontSize: 17,
      ),
    ),
    // The pickers Material hands us are the one part of the app not drawn
    // here, and left alone they arrive as a lilac panel: Material 3 fills a
    // dialog with a surface tinted towards the seed colour. They are put on the
    // same paper, with the same corner, as the cards and alerts around them —
    // the date picker in a form is a piece of that form, not a visitor.
    dialogTheme: DialogThemeData(
      backgroundColor: colors.backgroundSecondary,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
    ),
    datePickerTheme: DatePickerThemeData(
      backgroundColor: colors.backgroundSecondary,
      surfaceTintColor: Colors.transparent,
      // The header is part of the sheet rather than a coloured band across
      // its top, as the iOS picker has no band of its own.
      headerBackgroundColor: colors.backgroundSecondary,
      headerForegroundColor: colors.textSecondary,
      dividerColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
      // Left to itself Material picks the day out in a dark ochre — what its
      // algorithm makes of the seed colour, not a colour the app owns. The
      // date belongs to a request, so it wears the requests' own orange.
      dayBackgroundColor: _selected(colors.friendly),
      dayForegroundColor: _selectedInk(colors.textPrimary),
      todayBackgroundColor: _selected(colors.friendly),
      todayForegroundColor: _selectedInk(colors.friendly),
      todayBorder: BorderSide(color: colors.friendly),
      yearBackgroundColor: _selected(colors.friendly),
      yearForegroundColor: _selectedInk(colors.textPrimary),
      cancelButtonStyle: TextButton.styleFrom(foregroundColor: colors.friendly),
      confirmButtonStyle: TextButton.styleFrom(
        foregroundColor: colors.friendly,
      ),
    ),
    timePickerTheme: TimePickerThemeData(
      backgroundColor: colors.backgroundSecondary,
      // The dial and the two number fields read as wells cut into the card,
      // so they take the page colour the card is lifted off.
      dialBackgroundColor: colors.backgroundPrimary,
      dialHandColor: colors.friendly,
      dialTextColor: _ink(
        selected: AppColors.onAccent,
        rest: colors.textPrimary,
      ),
      // The field being typed into is picked out by a wash of the tone, not by
      // a filled block: the numbers stay dark ink either way.
      hourMinuteColor: _ink(
        selected: colors.friendly.withValues(alpha: .18),
        rest: colors.backgroundPrimary,
      ),
      hourMinuteTextColor: _ink(
        selected: colors.textPrimary,
        rest: colors.textSecondary,
      ),
      dayPeriodColor: _ink(
        selected: colors.friendly.withValues(alpha: .18),
        rest: Colors.transparent,
      ),
      dayPeriodTextColor: _ink(
        selected: colors.textPrimary,
        rest: colors.textSecondary,
      ),
      cancelButtonStyle: TextButton.styleFrom(foregroundColor: colors.friendly),
      confirmButtonStyle: TextButton.styleFrom(
        foregroundColor: colors.friendly,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
    ),
    cardTheme: CardThemeData(
      color: colors.backgroundSecondary,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
    ),
  );
}
