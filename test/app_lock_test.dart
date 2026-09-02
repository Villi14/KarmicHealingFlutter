import 'package:flutter_test/flutter_test.dart';
import 'package:karmic_healing_flutter/data/biometrics.dart';
import 'package:karmic_healing_flutter/data/passcode.dart';
import 'package:karmic_healing_flutter/screens/app_lock/app_lock_screen.dart';

/// A device that answers however the test tells it to.
class FakeBiometrics extends Biometrics {
  FakeBiometrics({
    this.offers = Biometry.face,
    this.canDoBiometricsOnly = true,
    this.canDoDeviceOwner = true,
    this.outcome = BiometricsOutcome.success,
  });

  Biometry offers;
  bool canDoBiometricsOnly;
  bool canDoDeviceOwner;
  BiometricsOutcome outcome;

  final List<BiometricsPolicy> asked = [];

  @override
  Future<Biometry> biometry() async => offers;

  @override
  Future<bool> canEvaluate(BiometricsPolicy policy) async =>
      policy == BiometricsPolicy.biometricsOnly
      ? canDoBiometricsOnly
      : canDoDeviceOwner;

  @override
  Future<BiometricsOutcome> evaluate(
    BiometricsPolicy policy,
    String reason,
  ) async {
    asked.add(policy);
    return outcome;
  }
}

const _strings = AppLockStrings(
  reason: 'reason',
  resetReason: 'reset reason',
  failed: 'failed',
  unavailable: 'unavailable',
  wrongCode: 'wrong code',
);

void main() {
  group('the code as it is stored', () {
    test('a digest recognises its own code and no other', () {
      final digest = PasscodeDigest.of('1234');

      expect(digest.matches('1234'), isTrue);
      expect(digest.matches('1235'), isFalse);
      expect(digest.matches(''), isFalse);
    });

    test('the code itself is nowhere in what is written down', () {
      final digest = PasscodeDigest.of('1234');
      final written = digest.toJson().values.join();

      expect(written.contains('1234'), isFalse);
    });

    test('the same code twice is stored differently', () {
      // The salt is what makes this true, and what makes a lookup table useless
      // against ten thousand possible codes.
      expect(
        PasscodeDigest.of('1234').hash,
        isNot(PasscodeDigest.of('1234').hash),
      );
    });

    test('a digest survives the round trip through the store', () {
      final digest = PasscodeDigest.of('4321');

      expect(PasscodeDigest.fromJson(digest.toJson()).matches('4321'), isTrue);
    });

    test('a store holds one code at a time, and forgets it on request', () async {
      final store = InMemoryPasscodeStore();
      expect(await store.isSet(), isFalse);

      await store.save('1111');
      expect(await store.isSet(), isTrue);
      expect(await store.verify('1111'), isTrue);

      await store.save('2222');
      expect(await store.verify('1111'), isFalse);
      expect(await store.verify('2222'), isTrue);

      await store.clear();
      expect(await store.isSet(), isFalse);
      expect(await store.verify('2222'), isFalse);
    });
  });

  group('how patient the keypad is', () {
    final start = DateTime(2026, 9, 2, 12);

    test('the allowance is free of waiting', () {
      final attempts = PasscodeAttempts();

      for (var i = 0; i < PasscodeAttempts.allowance; i++) {
        attempts.recordFailure(start);
        expect(attempts.isWaiting(start), isFalse);
      }
    });

    test('past the allowance the waits grow', () {
      final attempts = PasscodeAttempts();
      for (var i = 0; i < PasscodeAttempts.allowance; i++) {
        attempts.recordFailure(start);
      }

      attempts.recordFailure(start);
      expect(attempts.remainingWait(start), 30);

      attempts.recordFailure(start);
      expect(attempts.remainingWait(start), 60);

      attempts.recordFailure(start);
      expect(attempts.remainingWait(start), 300);

      // And no further: the longest wait is the one that repeats.
      attempts.recordFailure(start);
      expect(attempts.remainingWait(start), 300);
    });

    test('a wait counts down and then lets go', () {
      final attempts = PasscodeAttempts();
      for (var i = 0; i <= PasscodeAttempts.allowance; i++) {
        attempts.recordFailure(start);
      }

      expect(attempts.remainingWait(start.add(const Duration(seconds: 10))), 20);
      expect(attempts.isWaiting(start.add(const Duration(seconds: 30))), isFalse);
    });

    test('the right code wipes the slate', () {
      final attempts = PasscodeAttempts();
      for (var i = 0; i <= PasscodeAttempts.allowance; i++) {
        attempts.recordFailure(start);
      }

      attempts.recordSuccess();

      expect(attempts.isWaiting(start), isFalse);
      expect(attempts.failures, 0);
    });
  });

  group('what the lock screen asks for', () {
    late FakeBiometrics biometrics;
    late InMemoryPasscodeStore passcode;
    late AppLockController controller;

    setUp(() {
      biometrics = FakeBiometrics();
      passcode = InMemoryPasscodeStore();
      controller = AppLockController(
        biometrics: biometrics,
        passcode: passcode,
      );
    });

    test('a device that can answer is asked for biometrics alone', () async {
      await passcode.save('1234');

      await controller.authenticate(_strings);

      expect(biometrics.asked, [BiometricsPolicy.biometricsOnly]);
      expect(controller.isUnlocked, isTrue);
    });

    test('the first success without a code goes on to choose one', () async {
      await controller.authenticate(_strings);

      expect(controller.isUnlocked, isFalse);
      expect(controller.stage, AppLockStage.creatingPasscode);
    });

    test('a device with no biometrics falls to the keypad', () async {
      await passcode.save('1234');
      biometrics
        ..canDoBiometricsOnly = false
        ..offers = Biometry.none;

      await controller.authenticate(_strings);

      expect(biometrics.asked, isEmpty);
      expect(controller.stage, AppLockStage.passcode);
    });

    test('with neither biometrics nor a code, the screen says so', () async {
      biometrics
        ..canDoBiometricsOnly = false
        ..canDoDeviceOwner = false;

      await controller.authenticate(_strings);

      expect(controller.errorMessage, _strings.unavailable);
    });

    test('a refused face leaves the keypad, not an error', () async {
      await passcode.save('1234');
      biometrics.outcome = BiometricsOutcome.failed;

      await controller.authenticate(_strings);

      expect(controller.stage, AppLockStage.passcode);
      expect(controller.errorMessage, isNull);
    });

    test('a prompt waved away is a choice, not a failure', () async {
      biometrics.outcome = BiometricsOutcome.cancelled;

      await controller.authenticate(_strings);

      expect(controller.errorMessage, isNull);
      // And the automatic attempt does not put the prompt straight back up.
      await controller.authenticateIfNeeded(_strings);
      expect(biometrics.asked.length, 1);
    });

    test('the right code opens the app, a wrong one says so', () async {
      await passcode.save('1234');

      expect(await controller.submit('4321', _strings), isFalse);
      expect(controller.isUnlocked, isFalse);
      expect(controller.passcodeMessage, _strings.wrongCode);

      expect(await controller.submit('1234', _strings), isTrue);
      expect(controller.isUnlocked, isTrue);
    });

    test('a code typed during a wait is not even looked at', () async {
      await passcode.save('1234');
      final now = DateTime(2026, 9, 2, 12);

      for (var i = 0; i <= PasscodeAttempts.allowance; i++) {
        await controller.submit('0000', _strings, now: now);
      }
      expect(controller.remainingWait(now), 30);

      expect(await controller.submit('1234', _strings, now: now), isFalse);
      expect(controller.isUnlocked, isFalse);
    });

    test('locking again asks from the beginning', () async {
      await passcode.save('1234');
      await controller.authenticate(_strings);
      expect(controller.isUnlocked, isTrue);

      controller.lock();

      expect(controller.isUnlocked, isFalse);
      expect(controller.stage, AppLockStage.biometrics);
    });

    test('a forgotten code is answered by the device itself', () async {
      await passcode.save('1234');

      await controller.resetPasscode(_strings);

      expect(biometrics.asked, [BiometricsPolicy.deviceOwner]);
      expect(controller.stage, AppLockStage.creatingPasscode);
    });

    test('turning the lock on from inside does not ask again', () {
      controller.unlockWithoutPrompt();

      expect(controller.isUnlocked, isTrue);
      expect(biometrics.asked, isEmpty);
    });
  });
}
