import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vitago_app/app/theme/app_design_tokens.dart';
import 'package:vitago_app/core/formatters/app_date_format.dart';
import 'package:vitago_app/core/permissions/app_permissions.dart';
import 'package:vitago_app/core/widgets/async_state_view.dart';
import 'package:vitago_app/core/widgets/status_badge.dart';
import 'package:vitago_app/features/fleet/controllers/fleet_controller.dart';
import 'package:vitago_app/features/fleet/models/fleet_models.dart';
import 'package:vitago_app/features/fleet/views/update_driver_operation_view.dart';
import 'package:vitago_app/features/profile/models/user_profile.dart';

class DriverDetailView extends ConsumerWidget {
  const DriverDetailView({
    required this.profile,
    required this.driverId,
    super.key,
  });

  final UserProfile profile;
  final String driverId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final driver = ref.watch(driverControllerProvider(driverId));
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle del motorista')),
      body: SafeArea(
        child: driver.when(
          loading: () => const AppLoadingView(label: 'Cargando motorista…'),
          error: (error, stackTrace) => AppErrorView(
            error: error,
            onRetry: () => ref.invalidate(driverControllerProvider(driverId)),
          ),
          data: (value) => _DriverContent(
            driver: value,
            canManage: profile.can(AppPermissions.manageDrivers),
            onUpdate: () => _openUpdate(context, ref, value),
          ),
        ),
      ),
    );
  }

  Future<void> _openUpdate(
    BuildContext context,
    WidgetRef ref,
    DriverProfile driver,
  ) async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (context) => UpdateDriverOperationView(driver: driver),
      ),
    );
    if (updated == true) {
      ref.invalidate(driverControllerProvider(driverId));
    }
  }
}

class _DriverContent extends StatelessWidget {
  const _DriverContent({
    required this.driver,
    required this.canManage,
    required this.onUpdate,
  });

  final DriverProfile driver;
  final bool canManage;
  final VoidCallback onUpdate;

  @override
  Widget build(BuildContext context) {
    final vehicle = driver.vehicle;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 26,
              child: Text(
                driver.user.firstNames.isEmpty
                    ? '?'
                    : driver.user.firstNames.characters.first.toUpperCase(),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    driver.user.fullName.isEmpty
                        ? driver.user.email
                        : driver.user.fullName,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(driver.user.email),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            StatusBadge(status: driver.operationalStatus),
            StatusBadge(status: driver.active ? 'ACTIVO' : 'INACTIVO'),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        _DetailLine(
          label: 'Teléfono',
          value: driver.user.phone ?? 'No registrado',
        ),
        _DetailLine(
          label: 'Vehículo',
          value: vehicle == null
              ? 'Sin vehículo asignado'
              : vehicle.displayName,
        ),
        if (vehicle != null)
          _DetailLine(
            label: 'Estado del vehículo',
            value: vehicle.status.replaceAll('_', ' ').toLowerCase(),
          ),
        const Divider(height: AppSpacing.xl),
        _DetailLine(
          label: 'Registrado',
          value: AppDateFormat.dateTime(driver.createdAt),
        ),
        _DetailLine(
          label: 'Actualizado',
          value: AppDateFormat.dateTime(driver.updatedAt),
        ),
        if (canManage) ...[
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            onPressed: onUpdate,
            icon: const Icon(Icons.tune),
            label: const Text('Actualizar disponibilidad'),
          ),
        ],
      ],
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
