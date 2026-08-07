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
    cardTheme: CardThemeData(
      color: colors.backgroundSecondary,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
    ),
  );
}
