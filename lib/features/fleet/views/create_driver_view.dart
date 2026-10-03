import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vitago_app/app/config/app_config.dart';
import 'package:vitago_app/app/theme/app_design_tokens.dart';
import 'package:vitago_app/core/errors/app_failure.dart';
import 'package:vitago_app/core/permissions/app_permissions.dart';
import 'package:vitago_app/core/widgets/async_state_view.dart';
import 'package:vitago_app/features/fleet/controllers/fleet_controller.dart';
import 'package:vitago_app/features/fleet/models/fleet_inputs.dart';
import 'package:vitago_app/features/fleet/models/fleet_models.dart';
import 'package:vitago_app/features/organizations/controllers/organizations_controller.dart';
import 'package:vitago_app/features/organizations/models/company.dart';
import 'package:vitago_app/features/profile/models/user_profile.dart';
import 'package:vitago_app/features/user_administration/controllers/users_controller.dart';
import 'package:vitago_app/features/user_administration/models/managed_user.dart';

class CreateDriverView extends ConsumerStatefulWidget {
  const CreateDriverView({required this.profile, super.key});

  final UserProfile profile;

  @override
  ConsumerState<CreateDriverView> createState() => _CreateDriverViewState();
}

class _CreateDriverViewState extends ConsumerState<CreateDriverView> {
  final _formKey = GlobalKey<FormState>();
  String? _companyId;
  String? _userId;
  String? _vehicleId;
  bool _saving = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    if (!widget.profile.can(AppPermissions.viewUsers)) {
      return Scaffold(
        appBar: AppBar(title: const Text('Registrar motorista')),
        body: const SafeArea(
          child: AppEmptyView(
            icon: Icons.people_outline,
            title: 'Usuarios no disponibles',
            message: 'Tu perfil necesita acceso a usuarios para elegir al motorista.',
          ),
        ),
      );
    }

    final config = ref.watch(appConfigProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Registrar motorista')),
      body: SafeArea(
        child: config.isCorporate ? _buildCorporate() : _buildData(const []),
      ),
    );
  }

  Widget _buildCorporate() {
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
              message: 'Se necesita una empresa para registrar al motorista.',
            );
          }
          _companyId ??= result.items.first.id;
          return _buildData(result.items);
        },
      );
    }

    final company = widget.profile.company;
    if (company == null) {
      return const AppEmptyView(
        icon: Icons.apartment_outlined,
        title: 'Empresa no asignada',
        message: 'Tu perfil no tiene una empresa asociada.',
      );
    }
    _companyId ??= company.id;
    return _buildData([
      Company(id: company.id, name: company.name, status: 'ACTIVO'),
    ]);
  }

  Widget _buildData(List<Company> companies) {
    final users = ref.watch(userSelectionControllerProvider);
    final vehicles = ref.watch(vehicleSelectionControllerProvider(_companyId));
    if (users.isLoading || vehicles.isLoading) {
      return const AppLoadingView(label: 'Preparando opciones…');
    }
    if (users.hasError) {
      return AppErrorView(
        error: users.error!,
        onRetry: () => ref.invalidate(userSelectionControllerProvider),
      );
    }
    if (vehicles.hasError) {
      return AppErrorView(
        error: vehicles.error!,
        onRetry: () =>
            ref.invalidate(vehicleSelectionControllerProvider(_companyId)),
      );
    }

    final isCorporate = ref.watch(appConfigProvider).isCorporate;
    final eligibleUsers = _eligibleUsers(
      users.requireValue.items,
      isCorporate: isCorporate,
    );
    return _buildForm(
      companies: companies,
      users: eligibleUsers,
      vehicles: vehicles.requireValue.items,
      isCorporate: isCorporate,
    );
  }

  List<ManagedUser> _eligibleUsers(
    List<ManagedUser> users, {
    required bool isCorporate,
  }) {
    final requiredRole = isCorporate
        ? 'REPARTIDOR_CORPORATIVO'
        : 'REPARTIDOR_RED';
    return users
        .where((user) {
          if (user.status.toUpperCase() != 'ACTIVO') return false;
          return user.roles.any((role) {
            if (role.code.toUpperCase() != requiredRole) return false;
            if (!isCorporate) return true;
            return role.companyId == _companyId || user.companyId == _companyId;
          });
        })
        .toList(growable: false);
  }

  Widget _buildForm({
    required List<Company> companies,
    required List<ManagedUser> users,
    required List<Vehicle> vehicles,
    required bool isCorporate,
  }) {
    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text(
            'Vincular motorista',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          const Text(
            'Selecciona un usuario con rol de repartidor y su vehículo.',
          ),
          if (_error case final error?) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              error,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          if (isCorporate && companies.length > 1)
            DropdownButtonFormField<String>(
              initialValue: _companyId,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Empresa'),
              items: companies
                  .map(
                    (company) => DropdownMenuItem(
                      value: company.id,
                      child: Text(
                        company.name,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(growable: false),
              onChanged: _saving
                  ? null
                  : (value) => setState(() {
                      _companyId = value;
                      _userId = null;
                      _vehicleId = null;
                    }),
            )
          else if (isCorporate)
            InputDecorator(
              decoration: const InputDecoration(labelText: 'Empresa'),
              child: Text(companies.first.name),
            ),
          if (isCorporate) const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<String>(
            initialValue: _userId,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Usuario motorista',
              prefixIcon: Icon(Icons.person_outline),
            ),
            items: users
                .map(
                  (user) => DropdownMenuItem(
                    value: user.id,
                    child: Text(
                      user.fullName.isEmpty
                          ? user.email
                          : '${user.fullName} · ${user.email}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(growable: false),
            validator: (value) =>
                value == null ? 'Selecciona un usuario motorista.' : null,
            onChanged: _saving
                ? null
                : (value) => setState(() => _userId = value),
          ),
          if (users.isEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              isCorporate
                  ? 'No hay usuarios activos con rol Repartidor corporativo en esta empresa.'
                  : 'No hay usuarios activos con rol Repartidor de red.',
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<String>(
            initialValue: _vehicleId,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Vehículo',
              prefixIcon: Icon(Icons.two_wheeler),
            ),
            items: vehicles
                .map(
                  (vehicle) => DropdownMenuItem(
                    value: vehicle.id,
                    child: Text(
                      vehicle.displayName,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(growable: false),
            validator: (value) =>
                value == null ? 'Selecciona un vehículo.' : null,
            onChanged: _saving
                ? null
                : (value) => setState(() => _vehicleId = value),
          ),
          if (vehicles.isEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'No hay vehículos activos disponibles para esta empresa.',
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          FilledButton.icon(
            onPressed: _saving || users.isEmpty || vehicles.isEmpty
                ? null
                : _save,
            icon: _saving
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.badge_outlined),
            label: const Text('Registrar motorista'),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final config = ref.read(appConfigProvider);
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(fleetActionsControllerProvider)
          .createDriver(
            CreateDriverInput(
              userId: _userId!,
              companyId: _companyId,
              vehicleId: _vehicleId!,
            ),
            isCorporate: config.isCorporate,
          );
      if (mounted) Navigator.of(context).pop(true);
    } on AppFailure catch (failure) {
      if (mounted) setState(() => _error = failure.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
