import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vitago_app/app/theme/app_design_tokens.dart';
import 'package:vitago_app/core/errors/app_failure.dart';
import 'package:vitago_app/features/incidents/controllers/incidents_controller.dart';
import 'package:vitago_app/features/incidents/models/incident.dart';

class ReviewIncidentView extends ConsumerStatefulWidget {
  const ReviewIncidentView({required this.incident, super.key});

  final Incident incident;

  @override
  ConsumerState<ReviewIncidentView> createState() => _ReviewIncidentViewState();
}

class _ReviewIncidentViewState extends ConsumerState<ReviewIncidentView> {
  final _notes = TextEditingController();
  String? _status;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final states = widget.incident.status == 'ABIERTA'
        ? const ['EN_REVISION', 'CERRADA']
        : const ['CERRADA'];
    return Scaffold(
      appBar: AppBar(title: const Text('Revisar incidencia')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Text(
              'Actualizar seguimiento',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            const Text(
              'Cada cambio conservará responsable, fecha y notas para auditoría.',
            ),
            if (_error case final error?) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                error,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            DropdownButtonFormField<String>(
              initialValue: _status,
              decoration: const InputDecoration(labelText: 'Nuevo estado'),
              items: states
                  .map(
                    (status) => DropdownMenuItem(
                      value: status,
                      child: Text(
                        status == 'EN_REVISION' ? 'En revisión' : 'Cerrada',
                      ),
                    ),
                  )
                  .toList(growable: false),
              onChanged: _saving
                  ? null
                  : (value) => setState(() => _status = value),
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _notes,
              enabled: !_saving,
              minLines: 3,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: 'Notas de revisión (opcional)',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton.icon(
              onPressed: _saving || _status == null ? null : _save,
              icon: _saving
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.fact_check_outlined),
              label: const Text('Guardar revisión'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(incidentActionsControllerProvider)
          .review(
            widget.incident.id,
            ReviewIncidentInput(status: _status!, notes: _notes.text),
          );
      if (mounted) Navigator.of(context).pop(true);
    } on AppFailure catch (failure) {
      if (mounted) setState(() => _error = failure.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
