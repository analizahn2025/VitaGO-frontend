import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vitago_app/app/theme/app_design_tokens.dart';
import 'package:vitago_app/core/models/paginated_result.dart';
import 'package:vitago_app/core/permissions/app_permissions.dart';
import 'package:vitago_app/core/widgets/async_state_view.dart';
import 'package:vitago_app/core/widgets/entity_list_tile.dart';
import 'package:vitago_app/core/widgets/pagination_footer.dart';
import 'package:vitago_app/features/locations/controllers/locations_controller.dart';
import 'package:vitago_app/features/locations/models/location.dart';
import 'package:vitago_app/features/locations/views/create_location_view.dart';
import 'package:vitago_app/features/locations/views/location_detail_view.dart';
import 'package:vitago_app/features/organizations/controllers/organizations_controller.dart';
import 'package:vitago_app/features/organizations/models/company.dart';
import 'package:vitago_app/features/profile/models/user_profile.dart';

class LocationsView extends ConsumerStatefulWidget {
  const LocationsView({required this.profile, super.key});

  final UserProfile profile;

  @override
  ConsumerState<LocationsView> createState() => _LocationsViewState();
}

class _LocationsViewState extends ConsumerState<LocationsView> {
  Company? _selectedCompany;
  int _page = 1;

  @override
  Widget build(BuildContext context) {
    if (!widget.profile.can(AppPermissions.viewLocations)) {
      return const AppEmptyView(
        icon: Icons.location_off_outlined,
        title: 'Sin acceso a ubicaciones',
        message: 'Tu perfil no puede consultar lugares autorizados.',
      );
    }

    if (widget.profile.can(AppPermissions.viewCompanies)) {
      final companies = ref.watch(companySelectionControllerProvider);
      return companies.when(
        loading: () => const AppLoadingView(label: 'Cargando empresas…'),
        error: (error, stackTrace) => AppErrorView(
          error: error,
          onRetry: () => ref.invalidate(companySelectionControllerProvider),
        ),
        data: (result) {
          if (result.items.isEmpty) {
            return const AppEmptyView(
              icon: Icons.apartment_outlined,
              title: 'No hay empresas disponibles',
              message: 'Necesitas una empresa visible para consultar lugares.',
            );
          }
          _selectedCompany ??= result.items.first;
          return _buildLocations(result.items);
        },
      );
    }

    final profileCompany = widget.profile.company;
    if (profileCompany == null) {
      return const AppEmptyView(
        icon: Icons.apartment_outlined,
        title: 'Empresa no asignada',
        message: 'Tu perfil no tiene una empresa asociada.',
      );
    }
    _selectedCompany ??= Company(
      id: profileCompany.id,
      name: profileCompany.name,
      status: 'ACTIVO',
    );
    return _buildLocations(const []);
  }

  Widget _buildLocations(List<Company> selectableCompanies) {
    final company = _selectedCompany!;
    final query = (companyId: company.id, page: _page, pageSize: 20);
    final locations = ref.watch(locationsControllerProvider(query));

    return locations.when(
      loading: () => const AppLoadingView(label: 'Cargando ubicaciones…'),
      error: (error, stackTrace) => AppErrorView(
        error: error,
        onRetry: () => ref.invalidate(locationsControllerProvider(query)),
      ),
      data: (result) => _buildLocationsResult(
        result: result,
        company: company,
        selectableCompanies: selectableCompanies,
        query: query,
      ),
    );
  }

  Widget _buildLocationsResult({
    required PaginatedResult<CompanyLocation> result,
    required Company company,
    required List<Company> selectableCompanies,
    required LocationPageQuery query,
  }) {
    final isEmpty = result.items.isEmpty;

    return RefreshIndicator(
      onRefresh: () => _refresh(query),
      child: ListView.separated(
        key: const PageStorageKey<String>('locations-scroll-view'),
        padding: const EdgeInsets.only(top: AppSpacing.sm),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: isEmpty ? 2 : result.items.length + 2,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _LocationsHeader(
              company: company,
              selectableCompanies: selectableCompanies,
              canCreate: widget.profile.can(AppPermissions.createLocations),
              onCreate: company.country == null
                  ? null
                  : () => _openCreateLocation(company),
              onCompanyChanged: (companyId) {
                setState(() {
                  _selectedCompany = selectableCompanies.firstWhere(
                    (item) => item.id == companyId,
                  );
                  _page = 1;
                });
              },
            );
          }

          if (isEmpty) {
            return const _EmptyLocationsContent();
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

          final item = result.items[index - 1];
          final uses = <String>[
            if (item.allowsOrigin) 'Origen',
            if (item.allowsDestination) 'Destino',
          ];
          return EntityListTile(
            icon: Icons.place_outlined,
            title: item.location.name,
            subtitle: uses.isEmpty
                ? item.location.address
                : '${uses.join(' y ')} · ${item.location.address}',
            status: item.status,
            onTap: () => _openLocation(item),
          );
        },
      ),
    );
  }

  Future<void> _refresh(LocationPageQuery query) async {
    ref.invalidate(locationsControllerProvider(query));
    await ref.read(locationsControllerProvider(query).future);
  }

  Future<void> _openCreateLocation(Company company) async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (context) => CreateLocationView(company: company),
      ),
    );
    if (created == true) {
      final query = (companyId: company.id, page: _page, pageSize: 20);
      ref.invalidate(locationsControllerProvider(query));
    }
  }

  Future<void> _openLocation(CompanyLocation item) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (context) => LocationDetailView(
          companyLocation: item,
          canApprove: widget.profile.can(AppPermissions.approveLocations),
        ),
      ),
    );
    if (changed == true) {
      final company = _selectedCompany!;
      final query = (companyId: company.id, page: _page, pageSize: 20);
      ref.invalidate(locationsControllerProvider(query));
    }
  }
}

class _LocationsHeader extends StatelessWidget {
  const _LocationsHeader({
    required this.company,
    required this.selectableCompanies,
    required this.canCreate,
    required this.onCreate,
    required this.onCompanyChanged,
  });

  final Company company;
  final List<Company> selectableCompanies;
  final bool canCreate;
  final VoidCallback? onCreate;
  final ValueChanged<String> onCompanyChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Lugares', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Puntos autorizados para origen y destino.',
            style: TextStyle(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.md),
          if (selectableCompanies.isNotEmpty)
            DropdownButtonFormField<String>(
              initialValue: company.id,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Empresa'),
              items: selectableCompanies
                  .map(
                    (item) => DropdownMenuItem(
                      value: item.id,
                      child: Text(
                        item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(growable: false),
              onChanged: (value) {
                if (value != null) onCompanyChanged(value);
              },
            )
          else
            Text(company.name, style: Theme.of(context).textTheme.titleMedium),
          if (company.country == null && canCreate) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              'La empresa debe ser consultable para obtener su país antes '
              'de registrar una ubicación.',
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: colors.onSurfaceVariant),
            ),
          ],
          if (canCreate) ...[
            const SizedBox(height: AppSpacing.md),
            FilledButton.tonalIcon(
              onPressed: onCreate,
              icon: const Icon(Icons.add_location_alt_outlined),
              label: const Text('Registrar lugar'),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyLocationsContent extends StatelessWidget {
  const _EmptyLocationsContent();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.xxl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.location_city_outlined,
              color: colors.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'No hay lugares registrados',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.xs),
          const Text(
            'Las ubicaciones autorizadas de esta empresa aparecerán aquí.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
