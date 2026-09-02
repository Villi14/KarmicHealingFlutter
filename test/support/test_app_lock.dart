import 'package:karmic_healing_flutter/data/app_lock.dart';
import 'package:karmic_healing_flutter/data/biometrics.dart';
import 'package:karmic_healing_flutter/data/passcode.dart';

/// The lock a widget test hands to `KarmicHealingApp`.
///
/// Off unless the test's own `SharedPreferences` say otherwise, over a device
/// that offers no biometrics and a code that lives only as long as the test —
/// neither the keychain nor a real prompt is reachable under `flutter test`.
Future<AppLockSettings> testAppLock() => AppLockSettings.load(
  biometrics: const UnavailableBiometrics(),
  passcode: InMemoryPasscodeStore(),
);
