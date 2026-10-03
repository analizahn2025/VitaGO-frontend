import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vitago_app/app/config/app_config.dart';
import 'package:vitago_app/app/theme/app_design_tokens.dart';
import 'package:vitago_app/core/errors/app_failure.dart';
import 'package:vitago_app/core/widgets/async_state_view.dart';
import 'package:vitago_app/features/fleet/controllers/fleet_controller.dart';
import 'package:vitago_app/features/fleet/models/fleet_models.dart';
import 'package:vitago_app/features/requests/controllers/requests_controller.dart';
import 'package:vitago_app/features/requests/models/request_inputs.dart';
import 'package:vitago_app/features/requests/models/request_models.dart';

class AssignRequestView extends ConsumerStatefulWidget {
  const AssignRequestView({required this.request, super.key});

  final ServiceRequestDetail request;

  @override
  ConsumerState<AssignRequestView> createState() => _AssignRequestViewState();
}

class _AssignRequestViewState extends ConsumerState<AssignRequestView> {
  final _reason = TextEditingController();
  String? _driverId;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final drivers = ref.watch(availableDriversControllerProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.request.assignedDriverId == null
              ? 'Asignar motorista'
              : 'Reasignar motorista',
        ),
      ),
      body: SafeArea(
        child: drivers.when(
          loading: () =>
              const AppLoadingView(label: 'Buscando motoristas disponibles…'),
          error: (error, stackTrace) => AppErrorView(
            error: error,
            onRetry: () => ref.invalidate(availableDriversControllerProvider),
          ),
          data: (result) {
            final config = ref.watch(appConfigProvider);
            final available = result.items
                .where((driver) {
                  return !config.isCorporate ||
                      driver.companyId == widget.request.summary.companyId;
                })
                .toList(growable: false);
            return _buildForm(available);
          },
        ),
      ),
    );
  }

  Widget _buildForm(List<DriverProfile> drivers) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Text(
          widget.request.number,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '${widget.request.summary.origin.name} → ${widget.request.summary.destinationName}',
        ),
        if (_error case final error?) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            error,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        if (drivers.isEmpty)
          const AppEmptyView(
            icon: Icons.no_accounts_outlined,
            title: 'No hay motoristas disponibles',
            message: 'Se necesita un motorista activo, disponible, con motocicleta activa y menos de cinco servicios.',
          )
        else ...[
          DropdownButtonFormField<String>(
            initialValue: _driverId,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Motorista'),
            items: drivers
                .map(
                  (driver) => DropdownMenuItem(
                    value: driver.id,
                    child: Text(
                      '${driver.user.fullName} · ${driver.vehicle?.plate ?? 'Sin vehículo'}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(growable: false),
            onChanged: _saving
                ? null
                : (value) => setState(() => _driverId = value),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _reason,
            enabled: !_saving,
            maxLength: 500,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Motivo u observación (opcional)',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          FilledButton.icon(
            onPressed: _saving || _driverId == null ? null : _save,
            icon: _saving
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.assignment_ind_outlined),
            label: Text(
              widget.request.assignedDriverId == null
                  ? 'Asignar motorista'
                  : 'Confirmar reasignación',
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(requestActionsControllerProvider)
          .assign(
            widget.request.id,
            RequestAssignmentInput(driverId: _driverId!, reason: _reason.text),
          );
      if (mounted) Navigator.of(context).pop(true);
    } on AppFailure catch (failure) {
      if (mounted) setState(() => _error = failure.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
