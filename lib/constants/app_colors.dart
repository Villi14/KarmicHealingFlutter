import 'package:flutter/material.dart';

/// The palette in one appearance.
///
/// Mirrors `KarmicHealing/Features/Resources/Assets/Colors.xcassets`, which
/// carries a light and a dark entry for every colour. Read it from the widget
/// that needs it — `final colors = AppColors.of(context)` — so the tree repaints
/// when the appearance changes. Nothing here can be `const` at a call site any
/// more, which is the point: a colour baked into a `const` widget would survive
/// the switch into dark mode.
@immutable
class AppColors {
  const AppColors._({
    required this.brightness,
    required this.textPrimary,
    required this.textSecondary,
    required this.textInvert,
    required this.energy,
    required this.friendly,
    required this.clarity,
    required this.health,
    required this.clam,
    required this.peace,
    required this.wisdom,
    required this.backgroundPrimary,
    required this.backgroundSecondary,
  });

  final Brightness brightness;

  final Color textPrimary;
  final Color textSecondary;

  /// Text on a surface of the opposite appearance.
  final Color textInvert;

  // The spectrum, root to crown.
  final Color energy;
  final Color friendly;
  final Color clarity;
  final Color health;
  final Color clam;
  final Color peace;
  final Color wisdom;

  /// The page.
  final Color backgroundPrimary;

  /// A card or a row lifted off the page.
  final Color backgroundSecondary;

  /// Text and glyphs on a surface filled with a spectrum colour. The spectrum
  /// stays light enough in both appearances for the dark ink to read, so this
  /// one colour has no dark variant.
  static const onAccent = Color(0xFF2F2F2D);

  static const _light = AppColors._(
    brightness: Brightness.light,
    textPrimary: Color(0xFF2F2F2D),
    textSecondary: Color(0xFF6B6B69),
    textInvert: Color(0xFFEDEDF0),
    energy: Color(0xFFF26E77),
    friendly: Color(0xFFE08536),
    clarity: Color(0xFFE1B929),
    health: Color(0xFF26BD47),
    clam: Color(0xFF47ACD1),
    peace: Color(0xFF8D95EE),
    wisdom: Color(0xFFC282D2),
    backgroundPrimary: Color(0xFFFEFEFF),
    backgroundSecondary: Color(0xFFE5E9F5),
  );

  static const _dark = AppColors._(
    brightness: Brightness.dark,
    textPrimary: Color(0xFFEDEDEB),
    textSecondary: Color(0xFFB1B1AF),
    textInvert: Color(0xFF2F2F2D),
    energy: Color(0xFFFF7A82),
    friendly: Color(0xFFF79A4E),
    clarity: Color(0xFFE7BB32),
    health: Color(0xFF4BD76D),
    clam: Color(0xFF5FC2E8),
    peace: Color(0xFF8F97F0),
    wisdom: Color(0xFFD08FE0),
    backgroundPrimary: Color(0xFF1F2128),
    backgroundSecondary: Color(0xFF2A2D39),
  );

  static AppColors of(BuildContext context) =>
      forBrightness(Theme.of(context).brightness);

  static AppColors forBrightness(Brightness brightness) =>
      brightness == Brightness.dark ? _dark : _light;

  bool get isDark => brightness == Brightness.dark;

  /// Where a colour has to move away from the page to stay legible — the
  /// darkened tone under a badge in light mode has to lighten in dark mode.
  Color contrasting(Color color, [double amount = .3]) =>
      Color.lerp(color, isDark ? Colors.white : Colors.black, amount)!;

  Color get success => health;
  Color get warning => clarity;
  Color get error => energy;
}
