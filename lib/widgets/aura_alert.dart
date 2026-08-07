import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import 'aura_widgets.dart';

/// One action an alert offers.
class AuraAlertButton {
  const AuraAlertButton(
    this.label, {
    this.onPressed,
    this.prominence = AuraProminence.filled,
    this.level,
  });

  final String label;
  final VoidCallback? onPressed;
  final AuraProminence prominence;
  final AuraLevel? level;
}

/// An alert is a dialog, not a page: it keeps a phone-like width everywhere and
/// takes the level its meaning sits on — a warning at the root, a confirmation
/// at the heart, an explanation at the crown.
Future<void> showAuraAlert(
  BuildContext context, {
  required String title,
  String? message,
  IconData? icon,
  AuraLevel level = AuraLevel.throat,
  List<AuraAlertButton> buttons = const [AuraAlertButton('OK')],
}) => showDialog<void>(
  context: context,
  barrierColor: Colors.black.withValues(alpha: .3),
  builder: (context) => Dialog(
    backgroundColor: Colors.transparent,
    elevation: 0,
    insetPadding: const EdgeInsets.all(16),
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 480),
      child: AuraCard(
        level: level,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              AuraIcon(icon, level: level, size: 36),
              const SizedBox(height: 16),
            ],
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Source Serif 4',
                fontSize: 20,
                color: AppColors.of(context).textPrimary,
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.of(context).textSecondary,
                  fontSize: 15,
                  height: 1.35,
                ),
              ),
            ],
            const SizedBox(height: 32),
            for (final button in buttons) ...[
              SizedBox(
                width: double.infinity,
                child: AuraButton(
                  label: button.label,
                  level: button.level ?? level,
                  prominence: button.prominence,
                  onPressed: () {
                    Navigator.of(context).pop();
                    button.onPressed?.call();
                  },
                ),
              ),
              if (button != buttons.last) const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    ),
  ),
);
