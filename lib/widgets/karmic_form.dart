import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_theme.dart';
import '../constants/design_constants.dart';
import '../l10n/app_localizations.dart';
import 'aura_widgets.dart';
import 'gradient_background.dart';
import 'scroll_blur.dart';
import 'sf_symbols.dart';

/// The chrome every form wears: Cancel and Save on either side of the bar, and
/// the screen title below it taking the whole width so a long one wraps instead
/// of being cut short between the two buttons.
///
/// The two buttons carry the level's gradient rather than a flat tint, as the
/// Swift app gives them — each word the whole ramp across its own width — and
/// the page sits on the same level's aura.
class KarmicFormShell extends StatelessWidget {
  const KarmicFormShell({
    super.key,
    required this.title,
    required this.level,
    required this.child,
    this.onSave,
  });

  final String title;
  final AuraLevel level;
  final Widget child;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: statusBarStyle(Theme.of(context).brightness),
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
          automaticallyImplyLeading: false,
          // Both buttons sit in the title, which is the only slot that spans
          // the bar: a leading slot has to be given a width in advance, and no
          // width is right for every language — "Скасувати" is twice the word
          // "Cancel" is, and broke onto a second line inside a fitted 90.
          titleSpacing: 0,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).maybePop(),
                child: AuraText(
                  AppLocalizations.of(context).cancel,
                  level: level,
                  fontSize: 17,
                ),
              ),
              TextButton(
                onPressed: onSave ?? () => Navigator.of(context).maybePop(),
                child: AuraText(
                  AppLocalizations.of(context).save,
                  level: level,
                  fontSize: 17,
                ),
              ),
            ],
          ),
        ),
        body: GradientBackground(
          tone: level.color(context),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                SizedBox(height: DesignConstants.contentTopInset(context)),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Source Serif 4',
                      fontSize: 20,
                      color: AppColors.of(context).textPrimary,
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
    this.controller,
    this.minLines = 1,
    this.serif = false,
    this.centered = false,
    this.color,
  });

  final String hint;
  final AuraLevel level;
  final TextEditingController? controller;
  final int minLines;
  final bool serif;
  final bool centered;

  /// The tone a field's own text carries — a request wears the colour it was
  /// given. Laid on as the gradient the Swift app lays on it, not as a flat
  /// fill, and only over words: an empty field keeps the plain hint.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final field = TextField(
      controller: controller,
      minLines: minLines,
      maxLines: null,
      textAlign: centered ? TextAlign.center : TextAlign.start,
      cursorColor: level.color(context),
      style: TextStyle(
        fontFamily: serif ? 'Source Serif 4' : 'Inter',
        fontSize: serif ? 20 : 17,
        color: color ?? AppColors.of(context).textPrimary,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          fontFamily: serif ? 'Source Serif 4' : 'Inter',
          color: AppColors.of(context).textSecondary,
        ),
        border: InputBorder.none,
      ),
    );

    final tone = color;
    return KarmicFormCard(
      level: level,
      child: tone == null || controller == null
          ? field
          : ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller!,
              // The mask paints over whatever is under it, hint included, so it
              // only goes on once there are words of the field's own to tint.
              builder: (context, value, child) => value.text.isEmpty
                  ? child!
                  : ShaderMask(
                      shaderCallback: toneGradient(tone).createShader,
                      child: child,
                    ),
              child: field,
            ),
    );
  }
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
            style: TextStyle(
              color: AppColors.of(context).textPrimary,
              fontSize: 17,
            ),
          ),
        ),
        // Green, as the Swift app tints it and as the settings screens wear
        // it — but with the heart level's own gradient across the track rather
        // than the platform's single fill.
        AuraSwitch(
          value: value,
          level: AuraLevel.heart,
          label: title,
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
        ToneIcon(icon, tone: iconTone ?? level.color(context)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: AppColors.of(context).textPrimary,
              fontSize: 17,
            ),
          ),
        ),
        PopupMenuButton<T>(
          onSelected: onSelected,
          itemBuilder: (context) => [
            for (final option in options)
              PopupMenuItem(value: option, child: Text(label(option))),
          ],
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label(value),
                style: TextStyle(color: level.color(context), fontSize: 17),
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
