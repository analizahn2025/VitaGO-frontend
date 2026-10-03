import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vitago_app/app/theme/app_design_tokens.dart';
import 'package:vitago_app/core/formatters/app_date_format.dart';
import 'package:vitago_app/core/widgets/async_state_view.dart';
import 'package:vitago_app/core/widgets/status_badge.dart';
import 'package:vitago_app/features/fleet/controllers/fleet_controller.dart';

class VehicleDetailView extends ConsumerWidget {
  const VehicleDetailView({required this.vehicleId, super.key});

  final String vehicleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehicle = ref.watch(vehicleControllerProvider(vehicleId));
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle de la motocicleta')),
      body: SafeArea(
        child: vehicle.when(
          loading: () => const AppLoadingView(label: 'Cargando vehículo…'),
          error: (error, stackTrace) => AppErrorView(
            error: error,
            onRetry: () => ref.invalidate(vehicleControllerProvider(vehicleId)),
          ),
          data: (value) => ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      value.plate,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                  StatusBadge(status: value.status),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              const Text('Motocicleta'),
              const SizedBox(height: AppSpacing.xl),
              _DetailLine(
                label: 'Marca',
                value: value.brand ?? 'No registrada',
              ),
              _DetailLine(
                label: 'Modelo',
                value: value.model ?? 'No registrado',
              ),
              _DetailLine(
                label: 'Año',
                value: value.year?.toString() ?? 'No registrado',
              ),
              if (value.notes case final notes?)
                _DetailLine(label: 'Notas', value: notes),
              const Divider(height: AppSpacing.xl),
              _DetailLine(
                label: 'Registrado',
                value: AppDateFormat.dateTime(value.createdAt),
              ),
              _DetailLine(
                label: 'Actualizado',
                value: AppDateFormat.dateTime(value.updatedAt),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: AppSpacing.xxs),
          Text(value),
        ],
      ),
    );
  }
}
