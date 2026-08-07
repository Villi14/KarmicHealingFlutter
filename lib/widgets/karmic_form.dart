import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_colors.dart';
import '../constants/design_constants.dart';
import 'aura_widgets.dart';
import 'gradient_background.dart';
import 'scroll_blur.dart';
import 'sf_symbols.dart';

/// The chrome every form wears: Cancel and Save on either side of the bar, and
/// the screen title below it taking the whole width so a long one wraps instead
/// of being cut short between the two buttons.
class KarmicFormShell extends StatelessWidget {
  const KarmicFormShell({
    super.key,
    required this.title,
    required this.tone,
    required this.child,
    this.onSave,
  });

  final String title;
  final Color tone;
  final Widget child;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemUiOverlayStyle.dark,
    child: ScrollBlur(
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          flexibleSpace: const ScrollBlurBackdrop(),
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          shadowColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle.dark,
          automaticallyImplyLeading: false,
          leadingWidth: 90,
          leading: TextButton(
            onPressed: () => Navigator.of(context).maybePop(),
            child: Text('Cancel', style: TextStyle(color: tone, fontSize: 17)),
          ),
          actions: [
            TextButton(
              onPressed: onSave ?? () => Navigator.of(context).maybePop(),
              child: Text('Save', style: TextStyle(color: tone, fontSize: 17)),
            ),
          ],
        ),
        body: GradientBackground(
          tone: tone,
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                SizedBox(height: DesignConstants.navigationBarInset(context)),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Source Serif 4',
                      fontSize: 20,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 700),
                      child: child,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

/// One field of a form on its own piece of paper.
class KarmicFormCard extends StatelessWidget {
  const KarmicFormCard({super.key, required this.level, required this.child});

  final AuraLevel level;
  final Widget child;

  @override
  Widget build(BuildContext context) => AuraCard(
    level: level,
    watermark: false,
    elevated: false,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: child,
  );
}

class KarmicFormField extends StatelessWidget {
  const KarmicFormField({
    super.key,
    required this.hint,
    required this.level,
    this.minLines = 1,
    this.serif = false,
    this.centered = false,
    this.color,
  });

  final String hint;
  final AuraLevel level;
  final int minLines;
  final bool serif;
  final bool centered;
  final Color? color;

  @override
  Widget build(BuildContext context) => KarmicFormCard(
    level: level,
    child: TextField(
      minLines: minLines,
      maxLines: null,
      textAlign: centered ? TextAlign.center : TextAlign.start,
      cursorColor: level.color,
      style: TextStyle(
        fontFamily: serif ? 'Source Serif 4' : 'Inter',
        fontSize: serif ? 20 : 17,
        color: color ?? AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          fontFamily: serif ? 'Source Serif 4' : 'Inter',
          color: AppColors.textSecondary,
        ),
        border: InputBorder.none,
      ),
    ),
  );
}

/// A row of a form that turns something on or off.
class KarmicFormToggle extends StatelessWidget {
  const KarmicFormToggle({
    super.key,
    required this.icon,
    required this.title,
    required this.level,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final AuraLevel level;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => KarmicFormCard(
    level: level,
    child: Row(
      children: [
        AuraIcon(icon, level: level, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 17),
          ),
        ),
        CupertinoSwitch(
          value: value,
          activeTrackColor: AppColors.health,
          onChanged: onChanged,
        ),
      ],
    ),
  );
}

/// A row of a form that picks one of a handful of values.
class KarmicFormPicker<T> extends StatelessWidget {
  const KarmicFormPicker({
    super.key,
    required this.icon,
    required this.title,
    required this.level,
    required this.value,
    required this.options,
    required this.label,
    required this.onSelected,
    this.iconTone,
  });

  final IconData icon;
  final String title;
  final AuraLevel level;
  final T value;
  final List<T> options;
  final String Function(T) label;
  final ValueChanged<T> onSelected;
  final Color? iconTone;

  @override
  Widget build(BuildContext context) => KarmicFormCard(
    level: level,
    child: Row(
      children: [
        ToneIcon(icon, tone: iconTone ?? level.color),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 17),
          ),
        ),
        PopupMenuButton<T>(
          onSelected: onSelected,
          color: AppColors.backgroundSecondary,
          itemBuilder: (context) => [
            for (final option in options)
              PopupMenuItem(value: option, child: Text(label(option))),
          ],
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label(value),
                style: TextStyle(color: level.color, fontSize: 17),
              ),
              const SizedBox(width: 4),
              AuraIcon(SFSymbols.chevronUpChevronDown, level: level, size: 16),
            ],
          ),
        ),
      ],
    ),
  );
}
