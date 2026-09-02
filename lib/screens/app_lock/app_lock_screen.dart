import 'dart:async';

import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/design_constants.dart';
import '../../data/app_lock.dart';
import '../../data/biometrics.dart';
import '../../data/passcode.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/aura_widgets.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/passcode_pad.dart';
import '../../widgets/sf_symbols.dart';
import '../settings/passcode_setup_screen.dart';

/// What the lock screen is asking for at the moment.
enum AppLockStage {
  /// A face or a finger, either running or waiting behind the unlock button.
  biometrics,

  /// The app's own keypad, reached when biometrics cannot or would not answer.
  passcode,

  /// The owner has proved themselves and is choosing a code — the first one, or
  /// a replacement for one they have forgotten.
  creatingPasscode,
}

/// The reasoning behind the lock screen, kept apart from the screen itself so
/// it can be exercised without a face in front of a camera.
class AppLockController extends ChangeNotifier {
  AppLockController({required this.biometrics, required this.passcode});

  final Biometrics biometrics;
  final PasscodeStore passcode;

  bool _isUnlocked = false;
  bool _isAuthenticating = false;
  String? _errorMessage;
  String? _passcodeMessage;
  Biometry _biometry = Biometry.none;
  AppLockStage _stage = AppLockStage.biometrics;

  /// Set when the user dismisses the system prompt themselves, so returning to
  /// the app shows the unlock button instead of putting the prompt straight
  /// back up.
  bool _didCancel = false;

  /// Wrong codes are counted across lockings, so backgrounding the app is no
  /// way out of a wait.
  final _attempts = PasscodeAttempts();

  bool get isUnlocked => _isUnlocked;
  bool get isAuthenticating => _isAuthenticating;
  String? get errorMessage => _errorMessage;
  String? get passcodeMessage => _passcodeMessage;
  Biometry get biometry => _biometry;
  AppLockStage get stage => _stage;

  /// The keypad offers a way back to biometrics only when there is one to go
  /// back to.
  bool get canOfferBiometrics => _biometry != Biometry.none;

  /// Called when the app leaves the screen for good — the next return asks
  /// again.
  void lock() {
    _isUnlocked = false;
    _errorMessage = null;
    _passcodeMessage = null;
    _didCancel = false;
    _stage = AppLockStage.biometrics;
    notifyListeners();
  }

  /// Grants the current session without a prompt, for when the user turns the
  /// lock on from inside the app and has therefore just proved they are the
  /// owner.
  void unlockWithoutPrompt() {
    _isUnlocked = true;
    _errorMessage = null;
    _passcodeMessage = null;
    _didCancel = false;
    _stage = AppLockStage.biometrics;
    _attempts.recordSuccess();
    notifyListeners();
  }

  /// The automatic attempt made on launch and on returning from the background.
  Future<void> authenticateIfNeeded(AppLockStrings strings) async {
    if (_isUnlocked ||
        _isAuthenticating ||
        _didCancel ||
        _stage != AppLockStage.biometrics) {
      return;
    }
    await authenticate(strings);
  }

  Future<void> authenticate(AppLockStrings strings) async {
    if (_isAuthenticating) return;

    _biometry = await biometrics.biometry();
    final hasPasscode = await passcode.isSet();
    final BiometricsPolicy policy;

    // Biometrics are asked for alone wherever they can answer: the device's own
    // passcode screen is exactly what the keypad is here to replace, and asking
    // for it would put the system's own lock in front of the user on every
    // launch. Without a code of our own it is still the only door left when the
    // device has no biometrics to offer.
    if (await biometrics.canEvaluate(BiometricsPolicy.biometricsOnly)) {
      policy = BiometricsPolicy.biometricsOnly;
    } else if (!hasPasscode &&
        await biometrics.canEvaluate(BiometricsPolicy.deviceOwner)) {
      policy = BiometricsPolicy.deviceOwner;
    } else if (hasPasscode) {
      // No usable biometrics on this device, or none left after too many
      // failures — the keypad is the way in.
      _stage = AppLockStage.passcode;
      notifyListeners();
      return;
    } else {
      _errorMessage = strings.unavailable;
      notifyListeners();
      return;
    }

    _isAuthenticating = true;
    _errorMessage = null;
    _didCancel = false;
    notifyListeners();

    final outcome = await biometrics.evaluate(policy, strings.reason);

    _isAuthenticating = false;
    _finish(outcome, hasPasscode: hasPasscode, strings: strings);
  }

  void _finish(
    BiometricsOutcome outcome, {
    required bool hasPasscode,
    required AppLockStrings strings,
  }) {
    if (outcome == BiometricsOutcome.success) {
      // A lock turned on before codes existed unlocks once more the old way,
      // and then asks for a code — from here on the keypad is what stands
      // behind biometrics.
      if (hasPasscode) {
        _isUnlocked = true;
      } else {
        _stage = AppLockStage.creatingPasscode;
      }
      notifyListeners();
      return;
    }

    if (!hasPasscode) {
      if (outcome == BiometricsOutcome.cancelled) {
        // Dismissing the prompt is a choice, not a failure — leave the unlock
        // button in place.
        _didCancel = true;
        _errorMessage = null;
      } else {
        _errorMessage = strings.failed;
      }
      notifyListeners();
      return;
    }

    // Whether the face was not recognised or the prompt was waved away, what is
    // left to try is the code.
    _stage = AppLockStage.passcode;
    _passcodeMessage = null;
    notifyListeners();
  }

  int remainingWait(DateTime now) => _attempts.remainingWait(now);

  /// Answers the keypad: `true` when the code was right and the app is now
  /// open.
  Future<bool> submit(
    String code,
    AppLockStrings strings, {
    DateTime? now,
  }) async {
    final moment = now ?? DateTime.now();
    if (_attempts.isWaiting(moment)) return false;

    if (!await passcode.verify(code)) {
      _attempts.recordFailure(moment);
      _passcodeMessage = _attempts.isWaiting(moment) ? null : strings.wrongCode;
      notifyListeners();
      return false;
    }

    _attempts.recordSuccess();
    _passcodeMessage = null;
    _isUnlocked = true;
    notifyListeners();
    return true;
  }

  /// A forgotten code is answered by the device itself: whoever can pass the
  /// phone's own face check or passcode is already entitled to everything the
  /// app is protecting.
  Future<void> resetPasscode(AppLockStrings strings) async {
    if (_isAuthenticating) return;

    if (!await biometrics.canEvaluate(BiometricsPolicy.deviceOwner)) {
      _passcodeMessage = strings.unavailable;
      notifyListeners();
      return;
    }

    _isAuthenticating = true;
    notifyListeners();

    final outcome = await biometrics.evaluate(
      BiometricsPolicy.deviceOwner,
      strings.resetReason,
    );

    _isAuthenticating = false;
    if (outcome != BiometricsOutcome.success) {
      _passcodeMessage = outcome == BiometricsOutcome.cancelled
          ? null
          : strings.failed;
      notifyListeners();
      return;
    }

    _stage = AppLockStage.creatingPasscode;
    notifyListeners();
  }
}

/// What the controller has to say, in the language the app is speaking.
///
/// The controller runs above the screen and outlives any one build, so it is
/// handed the words rather than reaching for a [BuildContext] to look them up.
class AppLockStrings {
  const AppLockStrings({
    required this.reason,
    required this.resetReason,
    required this.failed,
    required this.unavailable,
    required this.wrongCode,
  });

  AppLockStrings.of(AppLocalizations l10n)
    : reason = l10n.appLockReason,
      resetReason = l10n.passcodeResetReason,
      failed = l10n.appLockFailed,
      unavailable = l10n.appLockUnavailable,
      wrongCode = l10n.passcodeWrong;

  final String reason;
  final String resetReason;
  final String failed;
  final String unavailable;
  final String wrongCode;
}

/// Stands between the app and whoever picked up the phone.
///
/// Wraps the whole app rather than sitting in the navigation stack: anything
/// but an active, unlocked app shows the lock instead of the content, which
/// also keeps the content out of the task switcher's snapshot.
class AppLockGate extends StatefulWidget {
  const AppLockGate({super.key, required this.child});

  final Widget child;

  @override
  State<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends State<AppLockGate> with WidgetsBindingObserver {
  AppLockController? _controller;
  AppLockSettings? _settings;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final settings = AppLockScope.of(context);
    if (settings != _settings) {
      _settings = settings;
      _controller?.dispose();
      _controller = AppLockController(
        biometrics: settings.biometrics,
        passcode: settings.passcode,
      );
      if (settings.isEnabled) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _authenticate());
      } else {
        // Turning the lock on happens inside an unlocked app, so it takes
        // effect from the next launch rather than throwing the user out of the
        // screen they are on.
        _controller!.unlockWithoutPrompt();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_settings?.isEnabled != true) return;

    switch (state) {
      case AppLifecycleState.resumed:
        _authenticate();
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _controller?.lock();
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        // Only a passing interruption — the system prompt itself lands here.
        break;
    }
  }

  void _authenticate() {
    if (!mounted) return;
    final controller = _controller;
    if (controller == null) return;
    unawaited(
      controller.authenticateIfNeeded(
        AppLockStrings.of(AppLocalizations.of(context)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = AppLockScope.of(context);
    final controller = _controller!;

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => !settings.isEnabled || controller.isUnlocked
          ? widget.child
          : _LockScreen(controller: controller),
    );
  }
}

class _LockScreen extends StatefulWidget {
  const _LockScreen({required this.controller});

  final AppLockController controller;

  @override
  State<_LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<_LockScreen> {
  /// Ticks only while a wait is being counted down.
  Timer? _tick;
  DateTime _now = DateTime.now();

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  int get _waitRemaining => widget.controller.remainingWait(_now);

  void _followTheWait() {
    final waiting = _waitRemaining > 0;
    if (waiting && _tick == null) {
      _tick = Timer.periodic(
        const Duration(seconds: 1),
        (_) => setState(() => _now = DateTime.now()),
      );
    } else if (!waiting && _tick != null) {
      _tick!.cancel();
      _tick = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    _followTheWait();

    // Choosing a code stands in for the card rather than being pushed over it:
    // the lock is above the navigator, so there is no route stack here to push
    // onto, and nowhere to back out to either.
    if (widget.controller.stage == AppLockStage.creatingPasscode) {
      return PasscodeSetupScreen(
        passcode: widget.controller.passcode,
        onFinished: widget.controller.unlockWithoutPrompt,
      );
    }

    return Scaffold(
      body: GradientBackground(
        tone: AppColors.of(context).peace,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(DesignConstants.paddingXLarge),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: DesignConstants.maxAlertWidth,
                ),
                child: widget.controller.stage == AppLockStage.passcode
                    ? _passcodeCard(l10n)
                    : _biometricsCard(l10n),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _biometricsCard(AppLocalizations l10n) {
    final colors = AppColors.of(context);
    final controller = widget.controller;

    return AuraCard(
      level: AuraLevel.brow,
      padding: const EdgeInsets.all(DesignConstants.paddingXXLarge),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _seal(controller.biometry),
          SizedBox(height: DesignConstants.sectionSpacing(context)),
          Text(
            l10n.appLocked,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: DesignConstants.spacingSmall),
          Text(
            l10n.appLockSubtitle,
            textAlign: TextAlign.center,
            style: TextStyle(color: colors.textSecondary, fontSize: 15),
          ),
          SizedBox(height: DesignConstants.sectionSpacing(context)),
          if (controller.isAuthenticating)
            const SizedBox(
              height: DesignConstants.frameHeightXLarge,
              child: Center(child: CircularProgressIndicator()),
            )
          else
            AuraButton(
              label: l10n.unlock,
              level: AuraLevel.brow,
              onPressed: () => unawaited(
                controller.authenticate(AppLockStrings.of(l10n)),
              ),
            ),
          if (controller.errorMessage != null) ...[
            const SizedBox(height: DesignConstants.spacingMedium),
            Text(
              controller.errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.textSecondary, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }

  Widget _passcodeCard(AppLocalizations l10n) {
    final controller = widget.controller;
    final wait = _waitRemaining;

    return AuraCard(
      level: AuraLevel.brow,
      padding: const EdgeInsets.all(DesignConstants.paddingLarge),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PasscodePad(
            title: l10n.passcodeEnterTitle,
            message: wait > 0
                ? l10n.passcodeLockedOut(wait)
                : controller.passcodeMessage,
            biometryIcon: controller.canOfferBiometrics
                ? _biometryIcon(controller.biometry)
                : null,
            isDisabled: wait > 0,
            onBiometry: () =>
                unawaited(controller.authenticate(AppLockStrings.of(l10n))),
            onComplete: (code) =>
                controller.submit(code, AppLockStrings.of(l10n)),
          ),
          const SizedBox(height: DesignConstants.spacingMedium),
          AuraButton(
            label: l10n.passcodeForgot,
            level: AuraLevel.brow,
            prominence: AuraProminence.quiet,
            onPressed: () =>
                unawaited(controller.resetPasscode(AppLockStrings.of(l10n))),
          ),
        ],
      ),
    );
  }

  /// The ring the lock screen opens on, with whichever proof the device offers
  /// at its centre.
  Widget _seal(Biometry biometry) => SizedBox.square(
    dimension: 128,
    child: Stack(
      alignment: Alignment.center,
      children: [
        const AuraRings(level: AuraLevel.brow, size: 128, opacity: .5),
        _biometryIcon(biometry, size: 50),
      ],
    ),
  );

  Widget _biometryIcon(Biometry biometry, {double size = 28}) =>
      switch (biometry) {
        Biometry.face || Biometry.iris => AuraIcon.drawn(
          SFGlyph.faceid,
          level: AuraLevel.brow,
          size: size,
        ),
        Biometry.fingerprint => AuraIcon.drawn(
          SFGlyph.touchid,
          level: AuraLevel.brow,
          size: size,
        ),
        Biometry.none => AuraIcon(
          SFSymbols.lockFill,
          level: AuraLevel.brow,
          size: size,
        ),
      };
}
