import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vitago_app/app/theme/app_design_tokens.dart';
import 'package:vitago_app/core/errors/app_failure.dart';
import 'package:vitago_app/features/fleet/controllers/fleet_controller.dart';
import 'package:vitago_app/features/fleet/models/fleet_inputs.dart';
import 'package:vitago_app/features/fleet/models/fleet_models.dart';

class UpdateDriverOperationView extends ConsumerStatefulWidget {
  const UpdateDriverOperationView({
    required this.driver,
    this.canUpdateStatus = true,
    super.key,
  });

  final DriverProfile driver;
  final bool canUpdateStatus;

  @override
  ConsumerState<UpdateDriverOperationView> createState() =>
      _UpdateDriverOperationViewState();
}

class _UpdateDriverOperationViewState
    extends ConsumerState<UpdateDriverOperationView> {
  final _formKey = GlobalKey<FormState>();
  final _reason = TextEditingController();
  late String _operationalStatus;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _operationalStatus = widget.driver.operationalStatus;
  }

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final statusChanged =
        widget.canUpdateStatus &&
        _operationalStatus != widget.driver.operationalStatus;
    final changed = statusChanged;
    return Scaffold(
      appBar: AppBar(title: const Text('Actualizar operación')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Text(
                widget.driver.user.fullName,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.xs),
              const Text(
                'Actualiza únicamente la disponibilidad real del motorista.',
              ),
              if (_error case final error?) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  error,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              if (widget.canUpdateStatus)
                DropdownButtonFormField<String>(
                  initialValue: _operationalStatus,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Estado operativo',
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'OFFLINE',
                      child: Text('Desconectado'),
                    ),
                    DropdownMenuItem(
                      value: 'AVAILABLE',
                      child: Text('Disponible'),
                    ),
                    DropdownMenuItem(value: 'ON_ROUTE', child: Text('En ruta')),
                    DropdownMenuItem(value: 'PAUSED', child: Text('En pausa')),
                    DropdownMenuItem(
                      value: 'OUT_OF_SERVICE',
                      child: Text('Fuera de servicio'),
                    ),
                  ],
                  onChanged: _saving
                      ? null
                      : (value) => setState(
                          () =>
                              _operationalStatus = value ?? _operationalStatus,
                        ),
                ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _reason,
                enabled: !_saving,
                minLines: 2,
                maxLines: 4,
                maxLength: 500,
                decoration: const InputDecoration(
                  labelText: 'Motivo (opcional)',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              FilledButton.icon(
                onPressed: _saving || !changed ? null : _save,
                icon: _saving
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: const Text('Guardar cambios'),
              ),
              if (!changed) ...[
                const SizedBox(height: AppSpacing.sm),
                const Text(
                  'Selecciona un estado diferente para guardar.',
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(fleetActionsControllerProvider)
          .updateDriverOperation(
            widget.driver.id,
            UpdateDriverOperationInput(
              operationalStatus:
                  widget.canUpdateStatus &&
                      _operationalStatus != widget.driver.operationalStatus
                  ? _operationalStatus
                  : null,
              reason: _reason.text,
            ),
          );
      if (mounted) Navigator.of(context).pop(true);
    } on AppFailure catch (failure) {
      if (mounted) setState(() => _error = failure.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
