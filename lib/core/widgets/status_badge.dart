import 'package:flutter/material.dart';
import 'package:vitago_app/app/theme/app_design_tokens.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({required this.status, super.key});

  final String status;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final normalized = status.toUpperCase();
    final isPositive = const {
      'ACTIVO',
      'ACTIVA',
      'APROBADO',
      'AVAILABLE',
      'DELIVERED',
      'CERRADA',
      'EMPTY',
      'AVAILABLE_SPACE',
    }.contains(normalized);
    final isWarning = const {
      'PENDING',
      'PENDIENTE',
      'ASSIGNED',
      'GOING_TO_PICKUP',
      'AT_PICKUP',
      'PICKED_UP',
      'IN_TRANSIT',
      'AT_DESTINATION',
      'EN_REVISION',
      'ON_ROUTE',
      'PAUSED',
      'MANTENIMIENTO',
      'FULL',
    }.contains(normalized);
    final isNegative = const {
      'INACTIVO',
      'INACTIVA',
      'RECHAZADO',
      'CANCELLED',
      'PICKUP_FAILED',
      'DELIVERY_FAILED',
      'OUT_OF_SERVICE',
      'FUERA_SERVICIO',
    }.contains(normalized);
    final background = isPositive
        ? colors.primaryContainer
        : isWarning
        ? colors.tertiaryContainer
        : isNegative
        ? colors.errorContainer
        : colors.surfaceContainerHighest;
    final foreground = isPositive
        ? colors.onPrimaryContainer
        : isWarning
        ? colors.onTertiaryContainer
        : isNegative
        ? colors.onErrorContainer
        : colors.onSurfaceVariant;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadii.round),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xxs,
        ),
        child: Text(
          _label(normalized),
          style: Theme.of(context).textTheme.labelSmall
              ?.copyWith(color: foreground, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  String _label(String value) => switch (value) {
    'ACTIVA' => 'Activa',
    'FINALIZADA' => 'Finalizada',
    'ABIERTA' => 'Abierta',
    'EN_REVISION' => 'En revisión',
    'CERRADA' => 'Cerrada',
    'PENDING' => 'Pendiente',
    'ASSIGNED' => 'Asignada',
    'GOING_TO_PICKUP' => 'Hacia recolección',
    'AT_PICKUP' => 'En recolección',
    'PICKED_UP' => 'Recolectada',
    'IN_TRANSIT' => 'En tránsito',
    'AT_DESTINATION' => 'En destino',
    'DELIVERED' => 'Entregada',
    'CANCELLED' => 'Cancelada',
    'PICKUP_FAILED' => 'Recolección fallida',
    'DELIVERY_FAILED' => 'Entrega fallida',
    'OFFLINE' => 'Desconectado',
    'AVAILABLE' => 'Disponible',
    'ON_ROUTE' => 'En ruta',
    'PAUSED' => 'En pausa',
    'OUT_OF_SERVICE' => 'Fuera de servicio',
    'EMPTY' => 'Vacío',
    'AVAILABLE_SPACE' => 'Con espacio',
    'FULL' => 'Completo',
    'FUERA_SERVICIO' => 'Fuera de servicio',
    _ => value.replaceAll('_', ' ').toLowerCase(),
  };
}
