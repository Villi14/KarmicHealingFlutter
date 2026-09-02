import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/design_constants.dart';
import '../../data/passcode.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/aura_widgets.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/passcode_pad.dart';

/// Choosing the code, typed once and then again to be sure of it.
///
/// The same screen serves the first code and every later change: there is
/// nothing to prove before setting one, because it is only ever reached from
/// inside an app already unlocked, or from behind a lock that has just been
/// answered.
///
/// It never dismisses itself — the settings screen pushes it as a route and
/// pops it, while the lock screen shows it in place of its own card and has
/// nothing to pop. Both are told through [onFinished] and [onCancelled].
class PasscodeSetupScreen extends StatefulWidget {
  const PasscodeSetupScreen({
    super.key,
    required this.passcode,
    required this.onFinished,
    this.onCancelled,
  });

  final PasscodeStore passcode;

  /// Called once the code is chosen and stored.
  final VoidCallback onFinished;

  /// Called when the user backs out. Left off where there is nowhere to back
  /// out to, and the Cancel button goes with it.
  final VoidCallback? onCancelled;

  @override
  State<PasscodeSetupScreen> createState() => _PasscodeSetupScreenState();
}

class _PasscodeSetupScreenState extends State<PasscodeSetupScreen> {
  /// The code typed first, held while it is typed again.
  String? _first;
  String? _message;

  Future<bool> _accept(String code) async {
    if (_first == null) {
      setState(() {
        _first = code;
        _message = null;
      });
      return true;
    }

    if (code != _first) {
      // Back to the start rather than to another try at the second entry:
      // whichever of the two was mistyped, the code is no longer one the user
      // can be said to have chosen.
      setState(() {
        _first = null;
        _message = AppLocalizations.of(context).passcodeMismatch;
      });
      return false;
    }

    await widget.passcode.save(code);
    widget.onFinished();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = AppColors.of(context);
    final isRepeat = _first != null;

    return Scaffold(
      body: GradientBackground(
        tone: colors.peace,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: DesignConstants.paddingXLarge,
                vertical: DesignConstants.paddingLarge,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: DesignConstants.maxAlertWidth,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.appLock,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: DesignConstants.sectionSpacing(context)),
                    PasscodePad(
                      // A fresh pad for each of the two entries, so the dots
                      // start empty rather than carrying the first code over.
                      key: ValueKey(isRepeat),
                      title: isRepeat
                          ? l10n.passcodeRepeatTitle
                          : l10n.passcodeCreateTitle,
                      message:
                          _message ??
                          (isRepeat ? null : l10n.passcodeCreateSubtitle),
                      onComplete: _accept,
                    ),
                    if (widget.onCancelled != null) ...[
                      const SizedBox(height: DesignConstants.spacingMedium),
                      AuraButton(
                        label: l10n.cancel,
                        level: AuraLevel.brow,
                        prominence: AuraProminence.quiet,
                        onPressed: widget.onCancelled!,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
