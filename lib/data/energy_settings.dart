import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// How a meditation session is set up, and where that is kept.
///
/// The screens used to reach for [SharedPreferences] one loose key at a time,
/// which is how the session duration came to be written under one name and read
/// under another. There is one place for it now, and it carries the names the
/// SwiftUI app uses so the two apps mean the same thing by the same setting.
///
/// A [ChangeNotifier], like the repositories: a screen that follows it is
/// rebuilt when the settings screen changes something under it.
class EnergySettings extends ChangeNotifier {
  EnergySettings._(this._prefs);

  final SharedPreferences _prefs;

  /// The lengths a step may be given, in minutes, as the picker offers them.
  static const durationOptions = [1, 3, 5, 10, 15];

  /// How long the screen stays lit after a step before it rests, in seconds.
  static const restDelayOptions = [15, 30, 60, 120];

  static const sessionDurationKey = 'session_duration';
  static const soundEnabledKey = 'sound_enabled';
  static const vibrationEnabledKey = 'vibration_enabled';
  static const audioVolumeKey = 'audio_volume';
  static const screenRestEnabledKey = 'screen_rest_enabled';
  static const screenRestDelayKey = 'screen_rest_delay';
  static const initialProcessCompletedKey = 'initial_process_completed';
  static const activeSessionKindKey = 'active_session_kind';
  static const activeSessionStepKey = 'active_session_step';

  static Future<EnergySettings> load() async =>
      EnergySettings._(await SharedPreferences.getInstance());

  /// How long a step runs before the session moves on by itself.
  ///
  /// A stored zero means nothing was ever chosen, so it reads as the default
  /// rather than as a step that ends the instant it starts.
  Duration get stepDuration => Duration(minutes: sessionDuration);

  int get sessionDuration {
    final stored = _prefs.getInt(sessionDurationKey) ?? 0;
    return stored > 0 ? stored : 5;
  }

  Future<void> setSessionDuration(int minutes) =>
      _write(() => _prefs.setInt(sessionDurationKey, minutes));

  bool get soundEnabled => _prefs.getBool(soundEnabledKey) ?? false;

  Future<void> setSoundEnabled(bool enabled) =>
      _write(() => _prefs.setBool(soundEnabledKey, enabled));

  bool get vibrationEnabled => _prefs.getBool(vibrationEnabledKey) ?? false;

  Future<void> setVibrationEnabled(bool enabled) =>
      _write(() => _prefs.setBool(vibrationEnabledKey, enabled));

  double get audioVolume => _prefs.getDouble(audioVolumeKey) ?? .5;

  Future<void> setAudioVolume(double volume) =>
      _write(() => _prefs.setDouble(audioVolumeKey, volume));

  /// Darkening the screen between steps: on out of the box, since a meditation
  /// is meant to be done with the eyes closed.
  bool get screenRestEnabled => _prefs.getBool(screenRestEnabledKey) ?? true;

  Future<void> setScreenRestEnabled(bool enabled) =>
      _write(() => _prefs.setBool(screenRestEnabledKey, enabled));

  int get screenRestDelay {
    final stored = _prefs.getInt(screenRestDelayKey) ?? 0;
    return stored > 0 ? stored : 30;
  }

  Future<void> setScreenRestDelay(int seconds) =>
      _write(() => _prefs.setInt(screenRestDelayKey, seconds));

  /// Whether the initial process has been walked through once. Until it has,
  /// it is the first thing the balancing-energy list offers; afterwards it
  /// steps aside for the two parts that are meant to be repeated.
  bool get initialProcessCompleted =>
      _prefs.getBool(initialProcessCompletedKey) ?? false;

  Future<void> completeInitialProcess() =>
      _write(() => _prefs.setBool(initialProcessCompletedKey, true));

  /// Which meditation is running, and the step it has reached.
  ///
  /// Written as a session moves and cleared the moment it ends, whether it was
  /// walked to the end or left partway — so what is found here on a later
  /// launch is a session the app was killed in the middle of.
  ///
  /// Nothing reads it back into a session yet, here or in the SwiftUI app: an
  /// interrupted meditation is begun again rather than picked up halfway, and
  /// an interruption short enough to pick up from is a pause, not a kill. It is
  /// recorded because it is the one thing a session leaves behind about itself.
  String? get activeSessionKind => _prefs.getString(activeSessionKindKey);

  int get activeSessionStep => _prefs.getInt(activeSessionStepKey) ?? 0;

  /// Written without telling anyone, unlike every setting above it: a session
  /// records its own progress, and a screen rebuilt on each step it takes would
  /// be a screen that never gets to rest.
  Future<void> setActiveSession(String kind, int step) async {
    await _prefs.setString(activeSessionKindKey, kind);
    await _prefs.setInt(activeSessionStepKey, step);
  }

  Future<void> clearActiveSession() async {
    await _prefs.remove(activeSessionKindKey);
    await _prefs.remove(activeSessionStepKey);
  }

  /// Every setter takes the same shape: store it, then tell whoever is
  /// watching. Listeners hear about it before the write has landed on disk, so
  /// a switch answers the finger that flipped it rather than the file system.
  Future<void> _write(Future<void> Function() store) {
    final written = store();
    notifyListeners();
    return written;
  }
}

/// Hands the settings to the session and the screen that changes them.
class EnergySettingsScope extends InheritedNotifier<EnergySettings> {
  const EnergySettingsScope({
    super.key,
    required EnergySettings settings,
    required super.child,
  }) : super(notifier: settings);

  static EnergySettings of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<EnergySettingsScope>();
    assert(scope != null, 'No EnergySettingsScope above this widget');
    return scope!.notifier!;
  }
}
