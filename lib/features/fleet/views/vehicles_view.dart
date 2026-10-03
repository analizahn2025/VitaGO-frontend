import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vitago_app/app/theme/app_design_tokens.dart';
import 'package:vitago_app/core/models/paginated_result.dart';
import 'package:vitago_app/core/permissions/app_permissions.dart';
import 'package:vitago_app/core/widgets/async_state_view.dart';
import 'package:vitago_app/core/widgets/entity_list_tile.dart';
import 'package:vitago_app/core/widgets/pagination_footer.dart';
import 'package:vitago_app/features/fleet/controllers/fleet_controller.dart';
import 'package:vitago_app/features/fleet/models/fleet_models.dart';
import 'package:vitago_app/features/fleet/views/create_vehicle_view.dart';
import 'package:vitago_app/features/fleet/views/vehicle_detail_view.dart';
import 'package:vitago_app/features/profile/models/user_profile.dart';

class VehiclesView extends ConsumerStatefulWidget {
  const VehiclesView({required this.profile, super.key});

  final UserProfile profile;

  @override
  ConsumerState<VehiclesView> createState() => _VehiclesViewState();
}

class _VehiclesViewState extends ConsumerState<VehiclesView> {
  int _page = 1;
  String? _status;

  @override
  Widget build(BuildContext context) {
    final query = VehicleQuery(status: _status, page: _page);
    final vehicles = ref.watch(vehiclesControllerProvider(query));
    return vehicles.when(
      loading: () => const AppLoadingView(label: 'Cargando vehículos…'),
      error: (error, stackTrace) => AppErrorView(
        error: error,
        onRetry: () => ref.invalidate(vehiclesControllerProvider(query)),
      ),
      data: (result) => _buildResult(result, query),
    );
  }

  Widget _buildResult(PaginatedResult<Vehicle> result, VehicleQuery query) {
    final empty = result.items.isEmpty;
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(vehiclesControllerProvider(query));
        await ref.read(vehiclesControllerProvider(query).future);
      },
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: empty ? 2 : result.items.length + 2,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _VehiclesHeader(
              status: _status,
              canCreate: widget.profile.can(AppPermissions.manageVehicles),
              onStatusChanged: (value) => setState(() {
                _status = value;
                _page = 1;
              }),
              onCreate: _openCreate,
            );
          }
          if (empty) {
            return const Padding(
              padding: EdgeInsets.all(AppSpacing.xxl),
              child: Center(
                child: Text('No hay vehículos para estos filtros.'),
              ),
            );
          }
          if (index == result.items.length + 1) {
            return PaginationFooter(
              page: _page,
              totalItems: result.count,
              hasPrevious: result.hasPrevious,
              hasNext: result.hasNext,
              onPrevious: () => setState(() => _page--),
              onNext: () => setState(() => _page++),
            );
          }
          final vehicle = result.items[index - 1];
          return EntityListTile(
            icon: Icons.two_wheeler,
            title: vehicle.displayName,
            subtitle: 'Motocicleta',
            status: vehicle.status,
            onTap: () => Navigator.of(context).push<void>(
              MaterialPageRoute<void>(
                builder: (context) => VehicleDetailView(vehicleId: vehicle.id),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _openCreate() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (context) => CreateVehicleView(profile: widget.profile),
      ),
    );
    if (created == true) {
      ref.invalidate(
        vehiclesControllerProvider(VehicleQuery(status: _status, page: _page)),
      );
    }
  }
}

class _VehiclesHeader extends StatelessWidget {
  const _VehiclesHeader({
    required this.status,
    required this.canCreate,
    required this.onStatusChanged,
    required this.onCreate,
  });

  final String? status;
  final bool canCreate;
  final ValueChanged<String?> onStatusChanged;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Motocicletas',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          const Text('Unidades disponibles para la operación sanitaria.'),
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<String?>(
            initialValue: status,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Estado'),
            items: const [
              DropdownMenuItem(value: null, child: Text('Todos')),
              DropdownMenuItem(value: 'ACTIVO', child: Text('Activo')),
              DropdownMenuItem(
                value: 'MANTENIMIENTO',
                child: Text('Mantenimiento'),
              ),
              DropdownMenuItem(
                value: 'FUERA_SERVICIO',
                child: Text('Fuera de servicio'),
              ),
              DropdownMenuItem(value: 'INACTIVO', child: Text('Inactivo')),
            ],
            onChanged: onStatusChanged,
          ),
          if (canCreate) ...[
            const SizedBox(height: AppSpacing.md),
            FilledButton.tonalIcon(
              onPressed: onCreate,
              icon: const Icon(Icons.add),
              label: const Text('Registrar motocicleta'),
            ),
          ],
        ],
      ),
    );
  }
}
