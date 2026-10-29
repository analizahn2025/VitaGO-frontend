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

  bool get _isReplacement =>
      widget.request.summary.pendingReassignment ||
      widget.request.assignedDriverId != null;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.request.summary.tubeCount;
    if (count == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Asignar motorista')),
        body: const SafeArea(
          child: AppEmptyView(
            icon: Icons.science_outlined,
            title: 'Cantidad de tubos sin declarar',
            message: 'Regulariza la cantidad de tubos desde el detalle antes de asignar este envío.',
          ),
        ),
      );
    }
    final provider = availableDriversForRequestControllerProvider(count);
    final drivers = ref.watch(provider);
    return Scaffold(
      appBar: AppBar(
        title: Text(_isReplacement ? 'Asignar reemplazo' : 'Asignar motorista'),
      ),
      body: SafeArea(
        child: drivers.when(
          loading: () =>
              const AppLoadingView(label: 'Buscando motoristas disponibles…'),
          error: (error, stackTrace) => AppErrorView(
            error: error,
            onRetry: () => ref.invalidate(provider),
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
    if (!drivers.any((driver) => driver.id == _driverId)) _driverId = null;
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
        if (widget.request.summary.pendingReassignment) ...[
          const SizedBox(height: AppSpacing.md),
          const Text(
            'La solicitud conservará su fase actual. Si ya fue recolectada, coordina el traspaso físico fuera de la aplicación.',
          ),
        ],
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
            message: 'No hay motoristas elegibles con cupo para estos tubos y solicitudes.',
          )
        else ...[
          DropdownButtonFormField<String>(
            key: ValueKey(drivers.map((driver) => driver.id).join(',')),
            initialValue: _driverId,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Motorista'),
            items: drivers
                .map(
                  (driver) => DropdownMenuItem(
                    value: driver.id,
                    child: Text(
                      '${driver.user.fullName} · ${driver.availableTubes == null ? 'Cupo según servidor' : '${driver.availableTubes} tubos libres'}',
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
              _isReplacement ? 'Confirmar reemplazo' : 'Asignar motorista',
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
      if (mounted) {
        ref.invalidate(
          availableDriversForRequestControllerProvider(
            widget.request.summary.tubeCount!,
          ),
        );
        setState(
          () =>
              _error = failure.fieldMessage('repartidor_id') ?? failure.message,
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
