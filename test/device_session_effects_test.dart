import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karmic_healing_flutter/data/session_effects.dart';

/// Where audioplayers takes its calls: one channel for a single player, one for
/// everything at once.
const _playerChannel = MethodChannel('xyz.luan/audioplayers');
const _globalChannel = MethodChannel('xyz.luan/audioplayers.global');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<MethodCall> playerCalls;
  late List<MethodCall> globalCalls;

  void record(MethodChannel channel, List<MethodCall> into) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          into.add(call);
          return 1;
        });
  }

  setUp(() {
    playerCalls = [];
    globalCalls = [];
    record(_playerChannel, playerCalls);
    record(_globalChannel, globalCalls);
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(_playerChannel, null);
    messenger.setMockMethodCallHandler(_globalChannel, null);
  });

  test('the chime asks to duck the music on the player that rings it, not on '
      'the next one to be made', () async {
    await DeviceSessionEffects().chime(0.5);

    // Android hands a player its copy of the audio context when the player is
    // made and never looks at the global one again, so a chime set up globally
    // would keep the focus Android gives by default — the one that stops the
    // user's music outright instead of lowering it for a moment.
    final context = playerCalls.firstWhere(
      (call) => call.method == 'setAudioContext',
      orElse: () =>
          fail('The audio context never reached the player: $playerCalls'),
    );
    expect(
      (context.arguments as Map)['audioFocus'],
      AndroidAudioFocus.gainTransientMayDuck.value,
    );
    expect(
      globalCalls.map((call) => call.method),
      isNot(contains('setAudioContext')),
    );
  });

  test('the chime is a plain 16-bit PCM wav, which is all Android will '
      'play', () {
    // The sound came from the Swift app as a 24-bit broadcast wav carrying a
    // `bext` chunk and a hundred markers. iOS plays that; Android's wav
    // extractor does not, and it fails without a word — the player reports
    // the error on a log stream nobody is listening to, so the session simply
    // goes silent. Whatever is put here has to stay something Android reads.
    final bytes = ByteData.sublistView(
      File('assets/sounds/ding.wav').readAsBytesSync(),
    );
    String tag(int at) => String.fromCharCodes(
      Uint8List.sublistView(bytes, at, at + 4),
    );

    expect(tag(0), 'RIFF');
    expect(tag(8), 'WAVE');
    expect(tag(12), 'fmt ');
    // A 16-byte `fmt ` holding format 1 — uncompressed PCM — and nothing
    // between it and the samples for an extractor to trip over.
    expect(bytes.getUint32(16, Endian.little), 16);
    expect(bytes.getUint16(20, Endian.little), 1);
    expect(bytes.getUint16(34, Endian.little), 16, reason: 'bits per sample');
    expect(tag(36), 'data');
  });
}
