import 'package:flutter/material.dart';
import 'package:vitago_app/app/theme/app_design_tokens.dart';
import 'package:vitago_app/features/fleet/models/fleet_models.dart';
import 'package:vitago_app/features/fleet/models/driver_load_snapshot.dart';

class DriverTubeLoad extends StatelessWidget {
  const DriverTubeLoad({required DriverProfile driver, super.key})
    : _profile = driver,
      _snapshot = null;
  const DriverTubeLoad.snapshot(DriverLoadSnapshot snapshot, {super.key})
    : _profile = null,
      _snapshot = snapshot;
  final DriverProfile? _profile;
  final DriverLoadSnapshot? _snapshot;
  @override
  Widget build(BuildContext context) {
    final load = _snapshot ?? DriverLoadSnapshot.fromProfile(_profile!);
    final unknownTubes = (load.requestsWithoutTubeCount ?? 0) > 0;
    final unknownFlasks = (load.requestsWithoutFlaskCount ?? 0) > 0;
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadii.control),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Carga del motorista',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          if (load.tubeLimit == null)
            const Text(
              'Información de carga no disponible. Actualiza el perfil.',
            )
          else ...[
            Text('Límite: ${load.tubeLimit} tubos'),
            if (unknownTubes)
              Text(
                '${load.requestsWithoutTubeCount} solicitudes sin cantidad declarada. La carga conocida es parcial; se requiere regularización administrativa.',
              ),
            Text(
              '${unknownTubes ? 'Comprometidos conocidos (parcial)' : 'Comprometidos'}: ${load.committedTubes ?? 'Sin información'}',
            ),
            Text(
              '${unknownTubes ? 'En transporte (parcial)' : 'En transporte'}: ${load.transportedTubes ?? 'Sin información'}',
            ),
            Text(
              '${unknownTubes ? 'Reservados (parcial)' : 'Reservados'}: ${load.reservedTubes ?? 'Sin información'}',
            ),
            Text(
              'Disponibles: ${unknownTubes ? 0 : load.availableTubes ?? 'Sin información'}',
            ),
          ],
          if (load.flaskLimit != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text('Frascos', style: Theme.of(context).textTheme.titleSmall),
            Text('Límite: ${load.flaskLimit}'),
            if (unknownFlasks)
              Text(
                '${load.requestsWithoutFlaskCount} solicitudes sin cantidad de frascos registrada.',
              ),
            Text(
              'Comprometidos${unknownFlasks ? ' conocidos (parcial)' : ''}: ${load.committedFlasks ?? 'Sin información'}',
            ),
            Text(
              'En transporte${unknownFlasks ? ' (parcial)' : ''}: ${load.transportedFlasks ?? 'Sin información'}',
            ),
            Text(
              'Reservados${unknownFlasks ? ' (parcial)' : ''}: ${load.reservedFlasks ?? 'Sin información'}',
            ),
            Text(
              'Disponibles: ${unknownFlasks ? 0 : load.availableFlasks ?? 'Sin información'}',
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Solicitudes: ${load.activeRequests ?? 'Sin información'} / ${load.requestLimit ?? 'Sin información'}',
          ),
          if (unknownTubes || unknownFlasks || load.capacity == 'FULL')
            const Text('Ocupado')
          else if (load.canReceiveRequests)
            const Text('Con cupo disponible'),
        ],
      ),
    );
  }
}
