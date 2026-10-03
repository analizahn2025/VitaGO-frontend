import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vitago_app/app/theme/app_design_tokens.dart';
import 'package:vitago_app/core/errors/app_failure.dart';
import 'package:vitago_app/core/permissions/app_permissions.dart';
import 'package:vitago_app/core/permissions/scope_type.dart';
import 'package:vitago_app/features/organizations/controllers/organizations_controller.dart';
import 'package:vitago_app/features/organizations/models/company.dart';
import 'package:vitago_app/features/profile/models/user_profile.dart';
import 'package:vitago_app/features/user_administration/controllers/users_controller.dart';
import 'package:vitago_app/features/user_administration/models/assignable_role.dart';
import 'package:vitago_app/features/user_administration/models/create_user_input.dart';
import 'package:vitago_app/features/user_administration/models/managed_user.dart';
import 'package:vitago_app/features/user_administration/models/user_role_assignment.dart';

class AssignUserRoleView extends ConsumerStatefulWidget {
  const AssignUserRoleView({
    required this.user,
    required this.profile,
    super.key,
  });

  final ManagedUser user;
  final UserProfile profile;

  @override
  ConsumerState<AssignUserRoleView> createState() => _AssignUserRoleViewState();
}

class _AssignUserRoleViewState extends ConsumerState<AssignUserRoleView> {
  final _formKey = GlobalKey<FormState>();
  late ScopeType _scopeType;
  String? _companyId;
  String? _branchId;
  String? _roleCode;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final scopes = _availableScopes(widget.profile);
    _scopeType = scopes.contains(ScopeType.company)
        ? ScopeType.company
        : scopes.first;
    _companyId = widget.user.companyId ?? widget.profile.company?.id;
    _branchId = widget.user.branchId ?? widget.profile.branch?.id;
  }

  @override
  Widget build(BuildContext context) {
    final scopes = _availableScopes(widget.profile);
    final canSelectCompanies = widget.profile.can(AppPermissions.viewCompanies);
    final companiesAsync = canSelectCompanies
        ? ref.watch(companySelectionControllerProvider)
        : null;
    final companies =
        companiesAsync?.value?.items ??
        [
          if (widget.profile.company case final company?)
            Company(id: company.id, name: company.name, status: 'ACTIVO'),
        ];
    final selectedCompanyId = _companyId;
    final branchesAsync =
        _scopeType == ScopeType.branch && selectedCompanyId != null
        ? ref.watch(branchSelectionControllerProvider(selectedCompanyId))
        : null;
    final roleQuery = _buildRoleQuery();
    final rolesAsync = roleQuery == null
        ? null
        : ref.watch(assignableRolesControllerProvider(roleQuery));

    return Scaffold(
      appBar: AppBar(title: const Text('Asignar rol')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Nuevo acceso',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text('Define qué puede hacer ${widget.user.fullName} y dónde.'),
                if (_error case final error?) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    error,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
                DropdownButtonFormField<ScopeType>(
                  initialValue: _scopeType,
                  decoration: const InputDecoration(labelText: 'Alcance'),
                  items: scopes
                      .map(
                        (scope) => DropdownMenuItem(
                          value: scope,
                          child: Text(scope.label),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: _saving
                      ? null
                      : (value) {
                          if (value == null) return;
                          setState(() {
                            _scopeType = value;
                            _roleCode = null;
                            if (value == ScopeType.global) {
                              _companyId = null;
                              _branchId = null;
                            } else {
                              _companyId ??=
                                  widget.user.companyId ??
                                  widget.profile.company?.id;
                            }
                            if (value != ScopeType.branch) _branchId = null;
                          });
                        },
                ),
                if (_scopeType != ScopeType.global) ...[
                  const SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<String>(
                    initialValue: companies.any((item) => item.id == _companyId)
                        ? _companyId
                        : null,
                    decoration: const InputDecoration(labelText: 'Empresa'),
                    items: companies
                        .map(
                          (company) => DropdownMenuItem(
                            value: company.id,
                            child: Text(company.name),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: _saving || companiesAsync?.isLoading == true
                        ? null
                        : (value) => setState(() {
                            _companyId = value;
                            _branchId = null;
                            _roleCode = null;
                          }),
                    validator: (value) =>
                        value == null ? 'Selecciona una empresa.' : null,
                  ),
                ],
                if (_scopeType == ScopeType.branch) ...[
                  const SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<String>(
                    initialValue:
                        branchesAsync?.value?.items.any(
                              (item) => item.id == _branchId,
                            ) ==
                            true
                        ? _branchId
                        : null,
                    decoration: const InputDecoration(labelText: 'Sucursal'),
                    items: (branchesAsync?.value?.items ?? const [])
                        .map(
                          (branch) => DropdownMenuItem(
                            value: branch.id,
                            child: Text(branch.name),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: _saving || branchesAsync?.isLoading == true
                        ? null
                        : (value) => setState(() {
                            _branchId = value;
                            _roleCode = null;
                          }),
                    validator: (value) =>
                        value == null ? 'Selecciona una sucursal.' : null,
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                _AssignableRoleField(
                  rolesAsync: rolesAsync,
                  selectedCode: _roleCode,
                  enabled: !_saving,
                  onChanged: (value) => setState(() => _roleCode = value),
                ),
                const SizedBox(height: AppSpacing.xl),
                FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.badge_outlined),
                  label: const Text('Asignar rol'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<ScopeType> _availableScopes(UserProfile profile) {
    if (profile.roles.any((role) => role.scopeType == ScopeType.global)) {
      return ScopeType.values;
    }
    final scopes = <ScopeType>[];
    if (profile.company != null) scopes.add(ScopeType.company);
    if (profile.branch != null || profile.can(AppPermissions.viewBranches)) {
      scopes.add(ScopeType.branch);
    }
    return scopes.isEmpty ? [ScopeType.company] : scopes;
  }

  AssignableRolesQuery? _buildRoleQuery() {
    if (_scopeType != ScopeType.global && _companyId == null) return null;
    if (_scopeType == ScopeType.branch && _branchId == null) return null;
    return AssignableRolesQuery(
      scopeType: _scopeType,
      companyId: _companyId,
      branchId: _branchId,
    );
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final roleCode = _roleCode;
    if (roleCode == null) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(userActionsControllerProvider)
          .assignRole(
            widget.user.id,
            AssignUserRoleInput(
              roleCode: roleCode,
              scopeType: _scopeType,
              companyId: _companyId,
              branchId: _branchId,
            ),
          );
      if (mounted) Navigator.of(context).pop(true);
    } on AppFailure catch (failure) {
      if (mounted) setState(() => _error = failure.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _AssignableRoleField extends StatelessWidget {
  const _AssignableRoleField({
    required this.rolesAsync,
    required this.selectedCode,
    required this.enabled,
    required this.onChanged,
  });

  final AsyncValue<List<AssignableRole>>? rolesAsync;
  final String? selectedCode;
  final bool enabled;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    if (rolesAsync == null || rolesAsync!.isLoading) {
      return const InputDecorator(
        decoration: InputDecoration(labelText: 'Rol'),
        child: Text('Selecciona primero el alcance'),
      );
    }
    if (rolesAsync!.hasError) {
      return Text(
        'No fue posible cargar los roles asignables.',
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      );
    }
    final roles = rolesAsync!.requireValue;
    return DropdownButtonFormField<String>(
      initialValue: roles.any((role) => role.code == selectedCode)
          ? selectedCode
          : null,
      decoration: const InputDecoration(labelText: 'Rol'),
      items: roles
          .map(
            (role) =>
                DropdownMenuItem(value: role.code, child: Text(role.name)),
          )
          .toList(growable: false),
      onChanged: enabled ? onChanged : null,
      validator: (value) => value == null ? 'Selecciona un rol.' : null,
    );
  }
}
