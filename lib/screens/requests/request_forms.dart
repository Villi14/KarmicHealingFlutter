import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../widgets/aura_widgets.dart';
import '../../widgets/karmic_form.dart';
import '../../widgets/sf_symbols.dart';

class SubrequestFormScreen extends StatelessWidget {
  const SubrequestFormScreen({super.key, this.screenTitle = 'New Subrequest'});

  final String screenTitle;

  @override
  Widget build(BuildContext context) => KarmicFormShell(
    title: screenTitle,
    tone: AppColors.of(context).friendly,
    child: ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      children: const [
        KarmicFormField(hint: 'Title', level: AuraLevel.sacral, serif: true),
        SizedBox(height: 20),
        KarmicFormField(hint: 'Notes', level: AuraLevel.sacral, minLines: 4),
      ],
    ),
  );
}

class RequestFormScreen extends StatefulWidget {
  const RequestFormScreen({super.key, this.screenTitle = 'Request'});

  final String screenTitle;

  @override
  State<RequestFormScreen> createState() => _RequestFormScreenState();
}

class _RequestFormScreenState extends State<RequestFormScreen> {
  /// The colours a topic can wear. The two in the middle come from the
  /// spectrum, so they follow the appearance.
  static List<Color> _palette(BuildContext context) {
    final colors = AppColors.of(context);
    return [
      const Color(0xFF4A99EF),
      colors.friendly,
      colors.health,
      const Color(0xFFB25DD3),
    ];
  }

  bool _hasDate = false;
  Color _color = const Color(0xFF4A99EF);

  @override
  Widget build(BuildContext context) => KarmicFormShell(
    title: widget.screenTitle,
    tone: AppColors.of(context).friendly,
    child: ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      children: [
        KarmicFormField(
          hint: 'Request',
          level: AuraLevel.sacral,
          serif: true,
          centered: true,
          color: _color,
        ),
        const SizedBox(height: 20),
        const KarmicFormField(
          hint: 'Notes',
          level: AuraLevel.sacral,
          minLines: 4,
        ),
        const SizedBox(height: 20),
        KarmicFormCard(
          level: AuraLevel.sacral,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Color',
                  style: TextStyle(
                    color: AppColors.of(context).textPrimary,
                    fontSize: 17,
                  ),
                ),
              ),
              for (final color in _palette(context))
                GestureDetector(
                  onTap: () => setState(() => _color = color),
                  child: Container(
                    width: 28,
                    height: 28,
                    margin: const EdgeInsets.only(left: 8),
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: color == _color
                            ? AppColors.of(context).textPrimary
                            : Colors.white,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: .2),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        KarmicFormToggle(
          icon: SFSymbols.calendar,
          title: 'Date',
          level: AuraLevel.sacral,
          value: _hasDate,
          onChanged: (value) => setState(() => _hasDate = value),
        ),
        if (_hasDate) ...[
          const SizedBox(height: 12),
          KarmicFormCard(
            level: AuraLevel.sacral,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Aug 7, 2026 at 8:00 PM',
                  style: TextStyle(
                    color: AppColors.of(context).friendly,
                    fontSize: 17,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    ),
  );
}
