import 'package:flutter/material.dart';
import 'package:vitago_app/app/theme/app_design_tokens.dart';
import 'package:vitago_app/core/errors/app_failure.dart';
import 'package:vitago_app/core/validation/operational_values.dart';

class EditOperationalCountView extends StatefulWidget {
  const EditOperationalCountView({
    required this.title,
    required this.label,
    required this.fieldName,
    required this.onSave,
    this.initialValue,
    this.description,
    super.key,
  });
  final String title;
  final String label;
  final String fieldName;
  final int? initialValue;
  final String? description;
  final Future<void> Function(int count, String reason) onSave;

  @override
  State<EditOperationalCountView> createState() =>
      _EditOperationalCountViewState();
}

class _EditOperationalCountViewState extends State<EditOperationalCountView> {
  final _form = GlobalKey<FormState>();
  late final _count = TextEditingController(
    text: widget.initialValue?.toString() ?? '',
  );
  final _reason = TextEditingController();
  bool _saving = false;
  AppFailure? _failure;
  @override
  void dispose() {
    _count.dispose();
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.title)),
    body: SafeArea(
      child: Form(
        key: _form,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            if (widget.description != null) ...[
              Text(widget.description!),
              const SizedBox(height: AppSpacing.lg),
            ],
            if (_failure != null) ...[
              Text(
                _failure!.fieldMessage(widget.fieldName) ?? _failure!.message,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            TextFormField(
              controller: _count,
              enabled: !_saving,
              decoration: InputDecoration(
                labelText: widget.label,
                errorText: _failure?.fieldMessage(widget.fieldName),
              ),
              keyboardType: TextInputType.number,
              validator: tubeCountError,
              onChanged: (_) => setState(() => _failure = null),
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _reason,
              enabled: !_saving,
              maxLength: 500,
              minLines: 2,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Motivo',
                errorText: _failure?.fieldMessage('motivo'),
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Indica el motivo del cambio.'
                  : null,
              onChanged: (_) => setState(() => _failure = null),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'Guardando…' : 'Guardar cambios'),
            ),
          ],
        ),
      ),
    ),
  );
  Future<void> _save() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    setState(() {
      _saving = true;
      _failure = null;
    });
    try {
      await widget.onSave(int.parse(_count.text.trim()), _reason.text.trim());
      if (mounted) Navigator.of(context).pop(true);
    } on AppFailure catch (failure) {
      if (mounted) setState(() => _failure = failure);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
