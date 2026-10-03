import 'package:flutter/material.dart';
import 'package:vitago_app/app/theme/app_design_tokens.dart';
import 'package:vitago_app/core/widgets/status_badge.dart';
import 'package:vitago_app/features/fleet/models/fleet_models.dart';

class DriverProfileCard extends StatelessWidget {
  const DriverProfileCard({
    required this.driver,
    required this.canUpdate,
    required this.onUpdate,
    super.key,
  });

  final DriverProfile driver;
  final bool canUpdate;
  final VoidCallback onUpdate;

  bool get hasActiveVehicle => driver.vehicle?.status == 'ACTIVO';

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final vehicle = driver.vehicle;
    final vehicleDescription = vehicle == null
        ? 'Necesitas un vehículo activo para iniciar la jornada.'
        : _vehicleDescription(vehicle);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadii.surface),
        border: Border.all(
          color: hasActiveVehicle ? colors.outlineVariant : colors.error,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: hasActiveVehicle
                      ? colors.primaryContainer
                      : colors.errorContainer,
                  borderRadius: BorderRadius.circular(AppRadii.small),
                ),
                child: Icon(
                  Icons.two_wheeler_outlined,
                  color: hasActiveVehicle
                      ? colors.onPrimaryContainer
                      : colors.onErrorContainer,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vehicle?.plate ?? 'Sin vehículo asignado',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      vehicleDescription,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: hasActiveVehicle
                            ? colors.onSurfaceVariant
                            : colors.onErrorContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              StatusBadge(status: driver.operationalStatus),
              if (vehicle != null) StatusBadge(status: vehicle.status),
            ],
          ),
          if (canUpdate) ...[
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onUpdate,
                icon: const Icon(Icons.tune, size: 20),
                label: const Text('Cambiar estado'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _vehicleDescription(Vehicle vehicle) {
    final details = [
      [vehicle.brand, vehicle.model].whereType<String>().join(' ').trim(),
    ].where((value) => value.isNotEmpty).toList(growable: false);
    return details.isEmpty ? 'Motocicleta asignada' : details.join('\n');
  }
}
