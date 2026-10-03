import 'package:flutter/material.dart';
import 'package:vitago_app/app/theme/app_design_tokens.dart';
import 'package:vitago_app/core/formatters/app_date_format.dart';
import 'package:vitago_app/core/widgets/status_badge.dart';
import 'package:vitago_app/features/shifts/models/driver_shift.dart';

class ShiftDetailView extends StatelessWidget {
  const ShiftDetailView({required this.shift, super.key});

  final DriverShift shift;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Resumen de jornada')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    shift.isActive ? 'Jornada activa' : 'Jornada finalizada',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                StatusBadge(status: shift.status),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            _ShiftLine(
              label: 'Inicio',
              value: AppDateFormat.dateTime(shift.startedAt),
            ),
            if (shift.finishedAt case final value?)
              _ShiftLine(
                label: 'Finalización',
                value: AppDateFormat.dateTime(value),
              ),
            _ShiftLine(
              label: 'Tiempo activo',
              value: AppDateFormat.durationMinutes(shift.activeMinutes),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Resultado operativo',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.md),
            _MetricGrid(
              metrics: [
                ('Servicios', shift.completedServices),
                ('Recolecciones', shift.completedPickups),
                ('Entregas', shift.completedDeliveries),
                ('Normales', shift.normalServices),
                ('Prioritarios', shift.priorityServices),
                if (shift.incidentsAvailable)
                  ('Incidencias', shift.reportedIncidents),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            if (shift.mileageAvailable)
              _ShiftLine(
                label: 'Kilómetros operativos',
                value: shift.operationalKilometers,
              )
            else
              const _UnavailableMileage(),
          ],
        ),
      ),
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.metrics});

  final List<(String, int)> metrics;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: metrics
          .map(
            (metric) => SizedBox(
              width: 142,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.primaryContainer.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(AppRadii.small),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        metric.$2.toString(),
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      Text(metric.$1),
                    ],
                  ),
                ),
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _ShiftLine extends StatelessWidget {
  const _ShiftLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: Theme.of(context).textTheme.labelLarge),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _UnavailableMileage extends StatelessWidget {
  const _UnavailableMileage();

  @override
  Widget build(BuildContext context) {
    return const ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(Icons.route_outlined),
      title: Text('Kilometraje no disponible'),
      subtitle: Text(
        'El backend todavía no calcula esta medición; el valor cero no se presenta como definitivo.',
      ),
    );
  }
}
