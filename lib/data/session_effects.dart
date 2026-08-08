import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// What a meditation session does to the device rather than to the screen it
/// draws: the chime between steps, the tap of the haptics, and the darkness the
/// screen rests in.
///
/// The session screen knows only this much of it, so a test — which has no
/// speaker, no taptic engine and no backlight to speak of — can hand it one
/// that only remembers what it was asked for.
abstract class SessionEffects {
  const SessionEffects();

  /// The session is on screen: hold the device awake.
  ///
  /// Sleeping is exactly what has to be avoided. The app is suspended seconds
  /// after the display goes off and can no longer move the session on by
  /// itself, so the screen is darkened by brightness instead — the same trick
  /// the SwiftUI app plays.
  Future<void> begin();

  /// The session is over: give brightness and sleep back to the system.
  Future<void> end();

  /// Takes the display to black, or back to where the user had it.
  Future<void> setDimmed(bool dimmed);

  /// The sound a step change makes, at [volume] from 0 to 1.
  Future<void> chime(double volume);

  /// The tap a step change makes.
  Future<void> vibrate();
}

/// The effects a test gets: it accepts everything and does nothing.
class NoSessionEffects extends SessionEffects {
  const NoSessionEffects();

  @override
  Future<void> begin() async {}

  @override
  Future<void> end() async {}

  @override
  Future<void> setDimmed(bool dimmed) async {}

  @override
  Future<void> chime(double volume) async {}

  @override
  Future<void> vibrate() async {}
}

/// The effects the device itself gives.
class DeviceSessionEffects extends SessionEffects {
  DeviceSessionEffects();

  final AudioPlayer _player = AudioPlayer();

  /// Whether the audio session has been set up. It is done at the first chime
  /// rather than at the start of the session: a meditation run in silence
  /// should not duck the music the user is already listening to.
  bool _audioReady = false;

  /// The chime, as it sits in the bundle. The same file the Swift app plays.
  static const _chimeAsset = 'sounds/ding.wav';

  @override
  Future<void> begin() => _quietly(() => WakelockPlus.enable());

  @override
  Future<void> end() => _quietly(() async {
    await WakelockPlus.disable();
    await ScreenBrightness.instance.resetApplicationScreenBrightness();
    await _player.stop();
  });

  @override
  Future<void> setDimmed(bool dimmed) => _quietly(() async {
    // Only what this app dimmed is dimmed, and only for as long as it is in
    // front — the plugin puts the user's own brightness back when the app
    // leaves, so a crash mid-session cannot leave them with a black phone.
    if (dimmed) {
      await ScreenBrightness.instance.setApplicationScreenBrightness(0);
    } else {
      await ScreenBrightness.instance.resetApplicationScreenBrightness();
    }
  });

  @override
  Future<void> chime(double volume) => _quietly(() async {
    if (!_audioReady) {
      // Heard over the silent switch, and over whatever is already playing:
      // the user's music is lowered for the moment the chime lands rather
      // than stopped.
      await AudioPlayer.global.setAudioContext(
        AudioContextConfig(focus: AudioContextConfigFocus.duckOthers).build(),
      );
      _audioReady = true;
    }
    await _player.stop();
    await _player.setVolume(volume.clamp(0, 1));
    await _player.play(AssetSource(_chimeAsset));
  });

  @override
  Future<void> vibrate() => _quietly(HapticFeedback.mediumImpact);

  /// None of this is worth interrupting a meditation over. A device without a
  /// taptic engine, an emulator with no brightness to set, a speaker another
  /// app has taken — each of them throws, and each of them means the session
  /// simply carries on without that one flourish.
  Future<void> _quietly(Future<void> Function() work) async {
    try {
      await work();
    } catch (error) {
      debugPrint('Session effect skipped: $error');
    }
  }
}
