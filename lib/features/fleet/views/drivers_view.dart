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
import 'package:vitago_app/features/fleet/views/create_driver_view.dart';
import 'package:vitago_app/features/fleet/views/driver_detail_view.dart';
import 'package:vitago_app/features/profile/models/user_profile.dart';

class DriversView extends ConsumerStatefulWidget {
  const DriversView({required this.profile, super.key});

  final UserProfile profile;

  @override
  ConsumerState<DriversView> createState() => _DriversViewState();
}

class _DriversViewState extends ConsumerState<DriversView> {
  int _page = 1;
  String? _operationalStatus;

  @override
  Widget build(BuildContext context) {
    final query = DriverQuery(
      companyId: widget.profile.isMasterAdmin
          ? null
          : widget.profile.company?.id,
      operationalStatus: _operationalStatus,
      page: _page,
    );
    final drivers = ref.watch(driversControllerProvider(query));
    return drivers.when(
      loading: () => const AppLoadingView(label: 'Cargando motoristas…'),
      error: (error, stackTrace) => AppErrorView(
        error: error,
        onRetry: () => ref.invalidate(driversControllerProvider(query)),
      ),
      data: (result) => _buildResult(result, query),
    );
  }

  Widget _buildResult(
    PaginatedResult<DriverProfile> result,
    DriverQuery query,
  ) {
    final empty = result.items.isEmpty;
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(driversControllerProvider(query));
        await ref.read(driversControllerProvider(query).future);
      },
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: empty ? 2 : result.items.length + 2,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _DriversHeader(
              operationalStatus: _operationalStatus,
              canCreate: widget.profile.can(AppPermissions.manageDrivers),
              onStatusChanged: (value) => setState(() {
                _operationalStatus = value;
                _page = 1;
              }),
              onCreate: _openCreate,
            );
          }
          if (empty) {
            return const Padding(
              padding: EdgeInsets.all(AppSpacing.xxl),
              child: Center(
                child: Text('No hay motoristas para estos filtros.'),
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
          final driver = result.items[index - 1];
          final vehicle = driver.vehicle;
          return EntityListTile(
            icon: Icons.badge_outlined,
            title: driver.user.fullName.isEmpty
                ? driver.user.email
                : driver.user.fullName,
            subtitle: vehicle == null
                ? 'Sin vehículo asignado · ${driver.user.email}'
                : '${vehicle.plate} · ${driver.user.email}',
            status: driver.operationalStatus,
            onTap: () async {
              await Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (context) => DriverDetailView(
                    profile: widget.profile,
                    driverId: driver.id,
                  ),
                ),
              );
              ref.invalidate(driversControllerProvider(query));
            },
          );
        },
      ),
    );
  }

  Future<void> _openCreate() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (context) => CreateDriverView(profile: widget.profile),
      ),
    );
    if (created == true) {
      ref.invalidate(
        driversControllerProvider(
          DriverQuery(
            companyId: widget.profile.isMasterAdmin
                ? null
                : widget.profile.company?.id,
            operationalStatus: _operationalStatus,
            page: _page,
          ),
        ),
      );
    }
  }
}

class _DriversHeader extends StatelessWidget {
  const _DriversHeader({
    required this.operationalStatus,
    required this.canCreate,
    required this.onStatusChanged,
    required this.onCreate,
  });

  final String? operationalStatus;
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
          Text('Motoristas', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: AppSpacing.xs),
          const Text('Personal habilitado y disponibilidad operativa.'),
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<String?>(
            initialValue: operationalStatus,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Estado'),
            items: const [
              DropdownMenuItem(value: null, child: Text('Todos')),
              DropdownMenuItem(value: 'OFFLINE', child: Text('Desconectado')),
              DropdownMenuItem(value: 'AVAILABLE', child: Text('Disponible')),
              DropdownMenuItem(value: 'ON_ROUTE', child: Text('En ruta')),
              DropdownMenuItem(value: 'PAUSED', child: Text('En pausa')),
              DropdownMenuItem(
                value: 'OUT_OF_SERVICE',
                child: Text('Fuera de servicio'),
              ),
            ],
            onChanged: onStatusChanged,
          ),
          if (canCreate) ...[
            const SizedBox(height: AppSpacing.md),
            FilledButton.tonalIcon(
              onPressed: onCreate,
              icon: const Icon(Icons.person_add_alt_1_outlined),
              label: const Text('Registrar motorista'),
            ),
          ],
        ],
      ),
    );
  }
}
