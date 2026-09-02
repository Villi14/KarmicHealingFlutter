import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// The code that opens the app when a face or a finger cannot.
///
/// Neither platform lets an app read the device's own passcode — it can ask the
/// system to check it, but never sees it, and so cannot check it against digits
/// typed on a keypad of our own. This code is therefore the app's own, kept
/// where the platform keeps secrets, and only ever stored as a salted digest:
/// what the app holds is enough to recognise the right code, never enough to
/// read it back.
abstract class PasscodeStore {
  const PasscodeStore();

  /// Digits in a code. Four, as on the system's own lock screen — short enough
  /// to type without looking, and it is a second door behind biometrics rather
  /// than the only one.
  static const length = 4;

  /// Whether the user has set a code at all.
  Future<bool> isSet();

  /// Replaces whatever code was there.
  Future<void> save(String code);

  /// True only when [code] is the code that was saved.
  Future<bool> verify(String code);

  /// Forgets the code, leaving the app to biometrics alone.
  Future<void> clear();
}

/// Backed by the keychain on iOS and the keystore on Android — it survives a
/// reinstall, and never leaves the device.
class SecurePasscodeStore extends PasscodeStore {
  SecurePasscodeStore([FlutterSecureStorage? storage])
    : _storage =
          storage ??
          const FlutterSecureStorage(
            // The digest is read while the app's own lock screen is up, which
            // is only ever while the device itself is unlocked; keeping it to
            // this device keeps it out of backups and off other devices.
            iOptions: IOSOptions(
              accessibility: KeychainAccessibility.unlocked_this_device,
            ),
          );

  static const _key = 'app_lock_passcode';

  final FlutterSecureStorage _storage;

  @override
  Future<bool> isSet() async => await _read() != null;

  @override
  Future<void> save(String code) =>
      _storage.write(key: _key, value: jsonEncode(PasscodeDigest.of(code)));

  @override
  Future<bool> verify(String code) async => _read().then(
    (digest) => digest?.matches(code) ?? false,
  );

  @override
  Future<void> clear() => _storage.delete(key: _key);

  Future<PasscodeDigest?> _read() async {
    final stored = await _storage.read(key: _key);
    if (stored == null) return null;
    try {
      return PasscodeDigest.fromJson(
        jsonDecode(stored) as Map<String, dynamic>,
      );
    } on FormatException {
      // Nothing readable is there, so there is no code — the setup screen will
      // write a fresh one over it.
      return null;
    }
  }
}

/// The same behaviour without the platform's store, for tests and QA runs.
class InMemoryPasscodeStore extends PasscodeStore {
  InMemoryPasscodeStore();

  PasscodeDigest? _digest;

  @override
  Future<bool> isSet() async => _digest != null;

  @override
  Future<void> save(String code) async => _digest = PasscodeDigest.of(code);

  @override
  Future<bool> verify(String code) async => _digest?.matches(code) ?? false;

  @override
  Future<void> clear() async => _digest = null;
}

/// A code as it is stored: a random salt, and the hash of that salt and the
/// code together.
///
/// The salt is what makes the digest worth storing. Four digits are ten
/// thousand possibilities, so an unsalted hash is a lookup away from the code
/// itself; a fresh salt per code means the table would have to be built again
/// for every device it is read from.
class PasscodeDigest {
  const PasscodeDigest(this.salt, this.hash);

  factory PasscodeDigest.of(String code) {
    final random = Random.secure();
    final salt = List<int>.generate(32, (_) => random.nextInt(256));
    return PasscodeDigest(salt, _hash(code, salt));
  }

  factory PasscodeDigest.fromJson(Map<String, dynamic> json) => PasscodeDigest(
    base64Decode(json['salt'] as String),
    base64Decode(json['hash'] as String),
  );

  final List<int> salt;
  final List<int> hash;

  Map<String, String> toJson() => {
    'salt': base64Encode(salt),
    'hash': base64Encode(hash),
  };

  bool matches(String code) {
    final candidate = _hash(code, salt);
    if (candidate.length != hash.length) return false;
    // Constant-time as a matter of habit rather than need: nobody is timing a
    // keypad.
    var difference = 0;
    for (var i = 0; i < hash.length; i++) {
      difference |= candidate[i] ^ hash[i];
    }
    return difference == 0;
  }

  static List<int> _hash(String code, List<int> salt) =>
      sha256.convert([...salt, ...utf8.encode(code)]).bytes;
}

/// How patient the lock screen is with wrong codes.
///
/// Four digits are ten thousand codes, which a person with the phone in hand
/// could work through given an unlimited number of tries. A few free attempts
/// cover the ordinary case of mistyping; past that each further wrong code
/// costs a wait, and the waits grow.
class PasscodeAttempts {
  /// Wrong codes allowed before the waiting starts.
  static const allowance = 5;

  /// What the first, second, and every later wrong code past the allowance
  /// costs.
  static const penalties = [
    Duration(seconds: 30),
    Duration(minutes: 1),
    Duration(minutes: 5),
  ];

  int _failures = 0;
  DateTime? _openAt;

  int get failures => _failures;

  /// The wait still to go, in whole seconds — zero whenever a code may be
  /// tried.
  int remainingWait(DateTime now) {
    final openAt = _openAt;
    if (openAt == null || !openAt.isAfter(now)) return 0;
    return (openAt.difference(now).inMilliseconds / 1000).ceil();
  }

  bool isWaiting(DateTime now) => remainingWait(now) > 0;

  void recordFailure(DateTime now) {
    _failures++;

    final beyondAllowance = _failures - allowance;
    if (beyondAllowance <= 0) return;

    final penalty = penalties[min(beyondAllowance, penalties.length) - 1];
    _openAt = now.add(penalty);
  }

  /// The right code wipes the slate: the next mistyped one starts from the full
  /// allowance again.
  void recordSuccess() {
    _failures = 0;
    _openAt = null;
  }
}
