import 'package:local_auth/local_auth.dart';

/// Which of the device's own proofs is on offer.
enum Biometry { none, fingerprint, face, iris }

/// What the app is willing to accept as proof of the owner.
enum BiometricsPolicy {
  /// A face or a finger and nothing besides.
  biometricsOnly,

  /// Whatever the device itself accepts, its own passcode screen included.
  deviceOwner,
}

/// How the asking ended.
enum BiometricsOutcome {
  success,

  /// The prompt was waved away rather than answered — a choice, not a failure.
  cancelled,
  failed,
}

/// The device asking, on the app's behalf, whether the person holding it is its
/// owner.
///
/// The platform answers only from a real device with a real face in front of
/// it, which is no answer at all to a test. Behind this the lock screen's
/// reasoning — which proof to ask for, and what each answer means — can be run
/// without any of that.
abstract class Biometrics {
  const Biometrics();

  /// What the device offers, if anything.
  Future<Biometry> biometry();

  /// Whether this proof could be asked for at all, at this moment.
  Future<bool> canEvaluate(BiometricsPolicy policy);

  /// Puts the system prompt up and waits for it to be answered.
  Future<BiometricsOutcome> evaluate(BiometricsPolicy policy, String reason);
}

/// A device with nothing to offer — what a test or a QA run gets.
class UnavailableBiometrics extends Biometrics {
  const UnavailableBiometrics();

  @override
  Future<Biometry> biometry() async => Biometry.none;

  @override
  Future<bool> canEvaluate(BiometricsPolicy policy) async => false;

  @override
  Future<BiometricsOutcome> evaluate(
    BiometricsPolicy policy,
    String reason,
  ) async => BiometricsOutcome.failed;
}

/// The real thing, through the platform's own authentication.
class LocalAuthBiometrics extends Biometrics {
  LocalAuthBiometrics([LocalAuthentication? auth])
    : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;

  /// The strongest of what is enrolled, since that is what the prompt will
  /// offer first and therefore what the screen should name.
  @override
  Future<Biometry> biometry() async {
    final enrolled = await _enrolled();
    if (enrolled.contains(BiometricType.face)) return Biometry.face;
    if (enrolled.contains(BiometricType.iris)) return Biometry.iris;
    if (enrolled.contains(BiometricType.fingerprint)) {
      return Biometry.fingerprint;
    }
    // Android reports a strong or weak sensor without saying which kind it is;
    // a finger is the overwhelmingly likely one, and the prompt itself will say
    // otherwise on screen.
    if (enrolled.isNotEmpty) return Biometry.fingerprint;
    return Biometry.none;
  }

  Future<List<BiometricType>> _enrolled() async {
    try {
      return await _auth.getAvailableBiometrics();
    } on LocalAuthException {
      return const [];
    }
  }

  @override
  Future<bool> canEvaluate(BiometricsPolicy policy) async {
    try {
      // `isDeviceSupported` is the wider question — biometrics or the device's
      // own passcode — and so answers for the wider policy.
      if (!await _auth.isDeviceSupported()) return false;
      if (policy == BiometricsPolicy.deviceOwner) return true;
      return await _auth.canCheckBiometrics && (await _enrolled()).isNotEmpty;
    } on LocalAuthException {
      return false;
    }
  }

  @override
  Future<BiometricsOutcome> evaluate(
    BiometricsPolicy policy,
    String reason,
  ) async {
    try {
      final passed = await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: policy == BiometricsPolicy.biometricsOnly,
        // The lock screen puts the prompt back up itself when the app returns,
        // so it need not survive the trip to the background.
        persistAcrossBackgrounding: false,
      );
      return passed ? BiometricsOutcome.success : BiometricsOutcome.failed;
    } on LocalAuthException catch (error) {
      return outcomeOf(error.code);
    }
  }

  /// Reads what the platform refused with. Only the ways of saying "not now"
  /// count as cancellation: everything else, a face simply not recognised
  /// included, is a failure the screen should say something about.
  static BiometricsOutcome outcomeOf(LocalAuthExceptionCode code) =>
      switch (code) {
        LocalAuthExceptionCode.userCanceled ||
        LocalAuthExceptionCode.systemCanceled ||
        LocalAuthExceptionCode.timeout ||
        // The user asked for the other door, which is the keypad this app
        // keeps — so the screen shows it rather than an error.
        LocalAuthExceptionCode.userRequestedFallback =>
          BiometricsOutcome.cancelled,
        _ => BiometricsOutcome.failed,
      };
}
