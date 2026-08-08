import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../constants/app_colors.dart';
import '../../data/models.dart';
import '../../data/repository_scope.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/aura_widgets.dart';
import '../../widgets/color_picker_row.dart';
import '../../widgets/karmic_form.dart';
import '../../widgets/sf_symbols.dart';

/// The form behind a subrequest: what it says, and what is worth remembering
/// about it.
///
/// No date and no priority here — a subrequest borrows both from the request it
/// serves, and borrowing is not editing.
class SubrequestFormScreen extends StatefulWidget {
  const SubrequestFormScreen({
    super.key,
    required this.subrequest,
    this.screenTitle,
  });

  final Subrequest subrequest;
  final String? screenTitle;

  @override
  State<SubrequestFormScreen> createState() => _SubrequestFormScreenState();
}

class _SubrequestFormScreenState extends State<SubrequestFormScreen> {
  late final _title = TextEditingController(text: widget.subrequest.title);
  late final _notes = TextEditingController(text: widget.subrequest.notes);

  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => KarmicFormShell(
    title: widget.screenTitle ?? AppLocalizations.of(context).newSubRequest,
    tone: AppColors.of(context).friendly,
    onSave: _save,
    child: ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      children: [
        KarmicFormField(
          controller: _title,
          hint: AppLocalizations.of(context).title,
          level: AuraLevel.sacral,
          serif: true,
        ),
        const SizedBox(height: 20),
        KarmicFormField(
          controller: _notes,
          hint: AppLocalizations.of(context).notes,
          level: AuraLevel.sacral,
          minLines: 4,
        ),
      ],
    ),
  );

  Future<void> _save() async {
    final title = _title.text.trim();
    if (title.isEmpty) return;

    final navigator = Navigator.of(context);
    await RepositoryScope.requestsOf(context).saveSubrequest(
      widget.subrequest.copyWith(title: title, notes: _notes.text),
    );
    navigator.maybePop();
  }
}

/// The form behind a request: what is being asked for, in what colour, and by
/// when.
class RequestFormScreen extends StatefulWidget {
  const RequestFormScreen({super.key, this.request, this.screenTitle});

  /// The request being edited, or `null` for one that does not exist yet.
  final RequestsList? request;
  final String? screenTitle;

  @override
  State<RequestFormScreen> createState() => _RequestFormScreenState();
}

class _RequestFormScreenState extends State<RequestFormScreen> {
  late final _title = TextEditingController(text: widget.request?.title ?? '');
  late final _notes = TextEditingController(text: widget.request?.notes ?? '');

  late Color _color = widget.request?.color ?? const Color(0xFF4A99EF);
  late DateTime? _dueDate = widget.request?.dueDate;

  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => KarmicFormShell(
    title:
        widget.screenTitle ??
        (widget.request == null
            ? AppLocalizations.of(context).request
            : AppLocalizations.of(context).editList),
    tone: AppColors.of(context).friendly,
    onSave: _save,
    child: ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      children: [
        KarmicFormField(
          controller: _title,
          hint: AppLocalizations.of(context).request,
          level: AuraLevel.sacral,
          serif: true,
          centered: true,
          color: _color,
        ),
        const SizedBox(height: 20),
        KarmicFormField(
          controller: _notes,
          hint: AppLocalizations.of(context).notes,
          level: AuraLevel.sacral,
          minLines: 4,
        ),
        const SizedBox(height: 20),
        ColorPickerRow(
          level: AuraLevel.sacral,
          color: _color,
          onChanged: (color) => setState(() => _color = color),
        ),
        const SizedBox(height: 20),
        KarmicFormToggle(
          icon: SFSymbols.calendar,
          title: AppLocalizations.of(context).date,
          level: AuraLevel.sacral,
          value: _dueDate != null,
          onChanged: _setDateEnabled,
        ),
        if (_dueDate != null) ...[
          const SizedBox(height: 12),
          KarmicFormCard(
            level: AuraLevel.sacral,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _pickDate,
                  child: Text(
                    DateFormat.yMMMd().add_jm().format(_dueDate!),
                    style: TextStyle(
                      color: AppColors.of(context).friendly,
                      fontSize: 17,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    ),
  );

  void _setDateEnabled(bool isEnabled) => setState(
    () => _dueDate = isEnabled ? (_dueDate ?? DateTime.now()) : null,
  );

  Future<void> _pickDate() async {
    final current = _dueDate ?? DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(current.year - 5),
      lastDate: DateTime(current.year + 5),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
    );
    if (!mounted) return;

    setState(
      () => _dueDate = DateTime(
        date.year,
        date.month,
        date.day,
        time?.hour ?? current.hour,
        time?.minute ?? current.minute,
      ),
    );
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    if (title.isEmpty) return;

    final navigator = Navigator.of(context);
    final repository = RepositoryScope.requestsOf(context);
    final request = widget.request ?? repository.draftRequest(_color);

    await repository.saveRequest(
      request.copyWith(
        title: title,
        notes: _notes.text,
        color: _color,
        dueDate: _dueDate,
        clearDueDate: _dueDate == null,
      ),
    );
    navigator.maybePop();
  }
}
