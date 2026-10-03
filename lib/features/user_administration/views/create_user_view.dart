import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vitago_app/app/theme/app_design_tokens.dart';
import 'package:vitago_app/core/errors/app_failure.dart';
import 'package:vitago_app/core/models/paginated_result.dart';
import 'package:vitago_app/core/permissions/app_permissions.dart';
import 'package:vitago_app/core/permissions/scope_type.dart';
import 'package:vitago_app/core/widgets/form_error_summary.dart';
import 'package:vitago_app/features/organizations/controllers/organizations_controller.dart';
import 'package:vitago_app/features/organizations/models/branch.dart';
import 'package:vitago_app/features/organizations/models/company.dart';
import 'package:vitago_app/features/profile/models/user_profile.dart';
import 'package:vitago_app/features/user_administration/controllers/users_controller.dart';
import 'package:vitago_app/features/user_administration/models/assignable_role.dart';
import 'package:vitago_app/features/user_administration/models/create_user_input.dart';

class CreateUserView extends ConsumerStatefulWidget {
  const CreateUserView({
    required this.profile,
    required this.usesLocalAuthentication,
    super.key,
  });

  final UserProfile profile;
  final bool usesLocalAuthentication;

  @override
  ConsumerState<CreateUserView> createState() => _CreateUserViewState();
}

class _CreateUserViewState extends ConsumerState<CreateUserView> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _firstNames = TextEditingController();
  final _lastNames = TextEditingController();
  final _phone = TextEditingController();
  final _credential = TextEditingController();
  late ScopeType _scopeType;
  String? _companyId;
  String? _branchId;
  String? _roleCode;
  bool _saving = false;
  bool _obscurePassword = true;
  String? _error;
  Map<String, List<String>> _fieldErrors = const {};

  @override
  void initState() {
    super.initState();
    final scopes = _availableScopes(widget.profile);
    _scopeType = scopes.contains(ScopeType.company)
        ? ScopeType.company
        : scopes.first;
    _companyId = widget.profile.company?.id;
    _branchId = widget.profile.branch?.id;
  }

  @override
  void dispose() {
    _email.dispose();
    _firstNames.dispose();
    _lastNames.dispose();
    _phone.dispose();
    _credential.dispose();
    super.dispose();
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

    final needsCompany = _scopeType != ScopeType.global;
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
      appBar: AppBar(title: const Text('Crear usuario')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Identidad y acceso',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  widget.usesLocalAuthentication
                      ? 'La persona cambiará la contraseña temporal según las reglas del servicio.'
                      : 'La persona utilizará su identidad corporativa.',
                ),
                if (_error case final error?) ...[
                  const SizedBox(height: AppSpacing.md),
                  FormErrorSummary(message: error),
                ],
                const SizedBox(height: AppSpacing.lg),
                TextFormField(
                  controller: _email,
                  enabled: !_saving,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'Correo',
                    errorText: _fieldError('correo'),
                  ),
                  onChanged: (_) => _clearFieldError('correo'),
                  validator: _emailValidator,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _firstNames,
                  enabled: !_saving,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'Nombres',
                    errorText: _fieldError('nombres'),
                  ),
                  onChanged: (_) => _clearFieldError('nombres'),
                  validator: _required,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _lastNames,
                  enabled: !_saving,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'Apellidos',
                    errorText: _fieldError('apellidos'),
                  ),
                  onChanged: (_) => _clearFieldError('apellidos'),
                  validator: _required,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  key: const Key('create-user-phone'),
                  controller: _phone,
                  enabled: !_saving,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'Teléfono',
                    errorText: _fieldError('telefono'),
                  ),
                  onChanged: (_) => _clearFieldError('telefono'),
                  validator: _phoneValidator,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _credential,
                  enabled: !_saving,
                  obscureText:
                      widget.usesLocalAuthentication && _obscurePassword,
                  autocorrect: false,
                  enableSuggestions: false,
                  decoration: InputDecoration(
                    labelText: widget.usesLocalAuthentication
                        ? 'Contraseña temporal'
                        : 'Identificador corporativo',
                    errorText: _fieldError(
                      widget.usesLocalAuthentication
                          ? 'contrasena_temporal'
                          : 'identificador_autenticacion_externa',
                    ),
                    suffixIcon: widget.usesLocalAuthentication
                        ? IconButton(
                            onPressed: _saving
                                ? null
                                : () => setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  ),
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            tooltip: _obscurePassword
                                ? 'Mostrar contraseña'
                                : 'Ocultar contraseña',
                          )
                        : null,
                  ),
                  onChanged: (_) => _clearFieldError(
                    widget.usesLocalAuthentication
                        ? 'contrasena_temporal'
                        : 'identificador_autenticacion_externa',
                  ),
                  validator: _credentialValidator,
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'Rol y alcance',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.sm),
                DropdownButtonFormField<ScopeType>(
                  initialValue: _scopeType,
                  decoration: InputDecoration(
                    labelText: 'Alcance',
                    errorText: _fieldError('tipo_alcance'),
                  ),
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
                            _fieldErrors = Map.of(_fieldErrors)
                              ..remove('tipo_alcance');
                            _scopeType = value;
                            _roleCode = null;
                            if (value == ScopeType.global) {
                              _companyId = null;
                              _branchId = null;
                            } else {
                              _companyId ??= widget.profile.company?.id;
                            }
                            if (value != ScopeType.branch) _branchId = null;
                          });
                        },
                  validator: (value) => value == null
                      ? 'Selecciona el alcance del usuario.'
                      : null,
                ),
                if (needsCompany) ...[
                  const SizedBox(height: AppSpacing.md),
                  _buildCompanyField(companiesAsync, companies),
                ],
                if (_scopeType == ScopeType.branch) ...[
                  const SizedBox(height: AppSpacing.md),
                  _buildBranchField(branchesAsync),
                ],
                const SizedBox(height: AppSpacing.md),
                _RoleSelector(
                  rolesAsync: rolesAsync,
                  selectedCode: _roleCode,
                  enabled: !_saving,
                  waitingMessage: _roleWaitingMessage(),
                  errorText: _fieldError('rol_codigo'),
                  onRetry: roleQuery == null
                      ? null
                      : () => ref.invalidate(
                          assignableRolesControllerProvider(roleQuery),
                        ),
                  onChanged: (value) => setState(() {
                    _roleCode = value;
                    _fieldErrors = Map.of(_fieldErrors)..remove('rol_codigo');
                  }),
                ),
                const SizedBox(height: AppSpacing.xl),
                FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.person_add_alt_1_outlined),
                  label: const Text('Crear usuario'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompanyField(
    AsyncValue<PaginatedResult<Company>>? companiesAsync,
    List<Company> companies,
  ) {
    if (companiesAsync?.isLoading == true) {
      return const _SelectionStateField(
        label: 'Empresa',
        message: 'Cargando empresas…',
        loading: true,
      );
    }
    if (companiesAsync?.hasError == true) {
      return _SelectionStateField(
        label: 'Empresa',
        message: _failureMessage(
          companiesAsync!.error!,
          'No fue posible cargar las empresas.',
        ),
        isError: true,
        onRetry: () => ref.invalidate(companySelectionControllerProvider),
      );
    }
    if (companies.isEmpty) {
      return const _SelectionStateField(
        label: 'Empresa',
        message: 'No hay empresas disponibles para tu alcance.',
      );
    }

    return DropdownButtonFormField<String>(
      initialValue: companies.any((item) => item.id == _companyId)
          ? _companyId
          : null,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Empresa',
        errorText: _fieldError('empresa_id'),
      ),
      items: companies
          .map(
            (company) => DropdownMenuItem(
              value: company.id,
              child: Text(
                company.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(growable: false),
      onChanged: _saving
          ? null
          : (value) => setState(() {
              _companyId = value;
              _branchId = null;
              _roleCode = null;
              _fieldErrors = Map.of(_fieldErrors)..remove('empresa_id');
            }),
      validator: (value) => value == null ? 'Selecciona una empresa.' : null,
    );
  }

  Widget _buildBranchField(AsyncValue<PaginatedResult<Branch>>? branchesAsync) {
    if (_companyId == null) {
      return const _SelectionStateField(
        label: 'Sucursal',
        message: 'Selecciona una empresa primero.',
      );
    }
    if (branchesAsync?.isLoading == true) {
      return const _SelectionStateField(
        label: 'Sucursal',
        message: 'Cargando sucursales…',
        loading: true,
      );
    }
    if (branchesAsync?.hasError == true) {
      return _SelectionStateField(
        label: 'Sucursal',
        message: _failureMessage(
          branchesAsync!.error!,
          'No fue posible cargar las sucursales.',
        ),
        isError: true,
        onRetry: () =>
            ref.invalidate(branchSelectionControllerProvider(_companyId!)),
      );
    }

    final branches = branchesAsync?.value?.items ?? const <Branch>[];
    if (branches.isEmpty) {
      return const _SelectionStateField(
        label: 'Sucursal',
        message: 'Esta empresa no tiene sucursales disponibles.',
      );
    }

    return DropdownButtonFormField<String>(
      initialValue: branches.any((item) => item.id == _branchId)
          ? _branchId
          : null,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Sucursal',
        errorText: _fieldError('sucursal_id'),
      ),
      items: branches
          .map(
            (branch) => DropdownMenuItem(
              value: branch.id,
              child: Text(
                branch.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(growable: false),
      onChanged: _saving
          ? null
          : (value) => setState(() {
              _branchId = value;
              _roleCode = null;
              _fieldErrors = Map.of(_fieldErrors)..remove('sucursal_id');
            }),
      validator: (value) => value == null ? 'Selecciona una sucursal.' : null,
    );
  }

  List<ScopeType> _availableScopes(UserProfile profile) {
    final hasGlobal = profile.roles.any(
      (role) => role.scopeType == ScopeType.global,
    );
    if (hasGlobal) return ScopeType.values;

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

  String _roleWaitingMessage() {
    if (_scopeType != ScopeType.global && _companyId == null) {
      return 'Selecciona una empresa primero.';
    }
    if (_scopeType == ScopeType.branch && _branchId == null) {
      return 'Selecciona una sucursal primero.';
    }
    return 'Completa el alcance para consultar los roles.';
  }

  String? _required(String? value) => value == null || value.trim().isEmpty
      ? 'Este campo es obligatorio.'
      : null;

  String? _emailValidator(String? value) {
    final text = value?.trim() ?? '';
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(text)) {
      return 'Ingresa un correo válido.';
    }
    return null;
  }

  String? _phoneValidator(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    final normalized = text.replaceAll(RegExp(r'[\s()\-]'), '');
    if (!RegExp(r'^\+?\d{8,15}$').hasMatch(normalized)) {
      return 'Usa entre 8 y 15 dígitos; el prefijo + es opcional.';
    }
    return null;
  }

  String? _credentialValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return widget.usesLocalAuthentication
          ? 'Ingresa una contraseña temporal.'
          : 'Ingresa el identificador corporativo.';
    }
    return null;
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      setState(() => _error = 'Revisa los campos marcados antes de continuar.');
      return;
    }
    if (_scopeType != ScopeType.global && _companyId == null) {
      setState(() => _error = 'Selecciona una empresa.');
      return;
    }
    if (_scopeType == ScopeType.branch && _branchId == null) {
      setState(() => _error = 'Selecciona una sucursal.');
      return;
    }
    final roleCode = _roleCode;
    if (roleCode == null) {
      setState(() => _error = 'Selecciona un rol asignable.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
      _fieldErrors = const {};
    });
    try {
      await ref
          .read(userActionsControllerProvider)
          .createUser(
            CreateUserInput(
              email: _email.text,
              firstNames: _firstNames.text,
              lastNames: _lastNames.text,
              phone: _phone.text,
              temporaryPassword: widget.usesLocalAuthentication
                  ? _credential.text
                  : null,
              externalAuthenticationId: widget.usesLocalAuthentication
                  ? null
                  : _credential.text,
              roleCode: roleCode,
              scopeType: _scopeType,
              companyId: _companyId,
              branchId: _branchId,
            ),
            usesLocalAuthentication: widget.usesLocalAuthentication,
          );
      if (mounted) Navigator.of(context).pop(true);
    } on AppFailure catch (failure) {
      if (mounted) {
        setState(() {
          _fieldErrors = failure.fieldErrors;
          _error = failure.fieldErrors.isEmpty
              ? failure.message
              : 'Revisa los campos marcados.';
        });
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _fieldError(String key) => _fieldErrors[key]?.firstOrNull;

  void _clearFieldError(String key) {
    if (!_fieldErrors.containsKey(key)) return;
    setState(() => _fieldErrors = Map.of(_fieldErrors)..remove(key));
  }
}

class _RoleSelector extends StatelessWidget {
  const _RoleSelector({
    required this.rolesAsync,
    required this.selectedCode,
    required this.enabled,
    required this.waitingMessage,
    required this.errorText,
    required this.onRetry,
    required this.onChanged,
  });

  final AsyncValue<List<AssignableRole>>? rolesAsync;
  final String? selectedCode;
  final bool enabled;
  final String waitingMessage;
  final String? errorText;
  final VoidCallback? onRetry;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    if (rolesAsync == null) {
      return _SelectionStateField(label: 'Rol', message: waitingMessage);
    }
    if (rolesAsync!.isLoading) {
      return const _SelectionStateField(
        label: 'Rol',
        message: 'Cargando roles…',
        loading: true,
      );
    }
    if (rolesAsync!.hasError) {
      return _SelectionStateField(
        label: 'Rol',
        message: _failureMessage(
          rolesAsync!.error!,
          'No fue posible cargar los roles asignables.',
        ),
        isError: true,
        onRetry: onRetry,
      );
    }
    final roles = rolesAsync!.requireValue;
    if (roles.isEmpty) {
      return const _SelectionStateField(
        label: 'Rol',
        message: 'No hay roles disponibles para este alcance.',
      );
    }
    return DropdownButtonFormField<String>(
      initialValue: roles.any((role) => role.code == selectedCode)
          ? selectedCode
          : null,
      decoration: InputDecoration(labelText: 'Rol', errorText: errorText),
      isExpanded: true,
      items: roles
          .map(
            (role) => DropdownMenuItem(
              value: role.code,
              child: Text(
                role.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(growable: false),
      onChanged: enabled ? onChanged : null,
      validator: (value) => value == null ? 'Selecciona un rol.' : null,
    );
  }
}

class _SelectionStateField extends StatelessWidget {
  const _SelectionStateField({
    required this.label,
    required this.message,
    this.loading = false,
    this.isError = false,
    this.onRetry,
  });

  final String label;
  final String message;
  final bool loading;
  final bool isError;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        errorText: isError ? message : null,
      ),
      child: isError
          ? Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            )
          : Row(
              children: [
                if (loading) ...[
                  const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Expanded(
                  child: Text(
                    message,
                    style: TextStyle(color: colors.onSurfaceVariant),
                  ),
                ),
              ],
            ),
    );
  }
}

String _failureMessage(Object error, String fallback) {
  return error is AppFailure ? error.message : fallback;
}
