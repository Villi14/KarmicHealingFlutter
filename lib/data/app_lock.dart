import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'biometrics.dart';
import 'passcode.dart';

/// Whether the app asks who is holding it before it opens, and what it asks
/// with.
///
/// Carries the name the SwiftUI app stores the switch under, so the two apps
/// mean the same thing by the same setting.
class AppLockSettings extends ChangeNotifier {
  AppLockSettings._(this._prefs, {required this.biometrics, required this.passcode});

  static const enabledKey = 'app_lock_enabled';

  final SharedPreferences _prefs;

  /// The device, asked whether the person holding it is its owner.
  final Biometrics biometrics;

  /// The app's own code, for when the device cannot answer.
  final PasscodeStore passcode;

  static Future<AppLockSettings> load({
    Biometrics? biometrics,
    PasscodeStore? passcode,
  }) async => AppLockSettings._(
    await SharedPreferences.getInstance(),
    biometrics: biometrics ?? LocalAuthBiometrics(),
    passcode: passcode ?? SecurePasscodeStore(),
  );

  bool get isEnabled => _prefs.getBool(enabledKey) ?? false;

  Future<void> setEnabled(bool enabled) async {
    if (enabled == isEnabled) return;
    await _prefs.setBool(enabledKey, enabled);
    notifyListeners();
  }
}

/// Hands the settings to the screens that read and change them, from wherever
/// in the navigation stack they were pushed.
class AppLockScope extends InheritedNotifier<AppLockSettings> {
  const AppLockScope({
    super.key,
    required AppLockSettings settings,
    required super.child,
  }) : super(notifier: settings);

  static AppLockSettings of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppLockScope>();
    assert(scope != null, 'No AppLockScope above this widget');
    return scope!.notifier!;
  }
}
