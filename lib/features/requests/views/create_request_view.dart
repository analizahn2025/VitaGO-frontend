import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vitago_app/app/config/app_config.dart';
import 'package:vitago_app/app/theme/app_design_tokens.dart';
import 'package:vitago_app/core/errors/app_failure.dart';
import 'package:vitago_app/core/validation/operational_values.dart';
import 'package:vitago_app/core/permissions/app_permissions.dart';
import 'package:vitago_app/core/widgets/adaptive_form_row.dart';
import 'package:vitago_app/core/widgets/async_state_view.dart';
import 'package:vitago_app/core/widgets/form_error_summary.dart';
import 'package:vitago_app/features/organizations/controllers/organizations_controller.dart';
import 'package:vitago_app/features/organizations/models/company.dart';
import 'package:vitago_app/features/profile/models/user_profile.dart';
import 'package:vitago_app/features/requests/controllers/requests_controller.dart';
import 'package:vitago_app/features/requests/models/request_creation_options.dart';
import 'package:vitago_app/features/requests/models/request_inputs.dart';
import 'package:vitago_app/features/requests/models/request_models.dart';

class CreateRequestView extends ConsumerStatefulWidget {
  const CreateRequestView({required this.profile, super.key});

  final UserProfile profile;

  @override
  ConsumerState<CreateRequestView> createState() => _CreateRequestViewState();
}

class _CreateRequestViewState extends ConsumerState<CreateRequestView> {
  final _formKey = GlobalKey<FormState>();
  final _notes = TextEditingController();
  final _tubeCount = TextEditingController(text: '0');
  final _flaskCount = TextEditingController(text: '0');
  final _specialDestination = TextEditingController();
  String? _companyId;
  String? _branchId;
  String? _serviceTypeId;
  String? _originId;
  String? _destinationId;
  String _priority = 'NORMAL';
  String? _modality;
  bool _saving = false;
  String? _error;
  Map<String, List<String>> _fieldErrors = const {};

  @override
  void dispose() {
    _notes.dispose();
    _tubeCount.dispose();
    _flaskCount.dispose();
    _specialDestination.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(appConfigProvider);
    if (!config.isCorporate) {
      return const Scaffold(
        body: SafeArea(
          child: AppEmptyView(
            icon: Icons.lock_clock_outlined,
            title: 'Creación no disponible',
            message: 'VitaGo Network habilitará solicitudes cuando exista cotización de ruta y tarifa.',
          ),
        ),
      );
    }

    final serviceTypes = ref.watch(requestServiceTypesControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Nueva solicitud')),
      body: SafeArea(
        child: serviceTypes.when(
          loading: () =>
              const AppLoadingView(label: 'Cargando tipos de servicio…'),
          error: (error, stackTrace) => AppErrorView(
            error: error,
            onRetry: () =>
                ref.invalidate(requestServiceTypesControllerProvider),
          ),
          data: _buildCompanySelection,
        ),
      ),
    );
  }

  Widget _buildCompanySelection(List<RequestServiceType> serviceTypes) {
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
              message:
                  'Se necesita una empresa activa para crear la solicitud.',
            );
          }
          _companyId ??= result.items.first.id;
          return _buildCreationOptions(serviceTypes, result.items);
        },
      );
    }

    final company = widget.profile.company;
    if (company == null) {
      return const AppEmptyView(
        icon: Icons.apartment_outlined,
        title: 'Empresa no asignada',
        message: 'Tu perfil necesita una empresa para crear solicitudes.',
      );
    }
    _companyId ??= company.id;
    return _buildCreationOptions(serviceTypes, [
      Company(id: company.id, name: company.name, status: 'ACTIVO'),
    ]);
  }

  Widget _buildCreationOptions(
    List<RequestServiceType> serviceTypes,
    List<Company> companies,
  ) {
    final query = RequestCreationOptionsQuery(
      companyId: _companyId!,
      branchId: widget.profile.branch?.id,
      modality: _modality,
      originId: _modality == RequestModalities.betweenBranches
          ? _originId
          : null,
    );
    final options = ref.watch(requestCreationOptionsControllerProvider(query));
    return options.when(
      loading: () => const AppLoadingView(label: 'Preparando la ruta…'),
      error: (error, stackTrace) => AppErrorView(
        error: error,
        onRetry: () =>
            ref.invalidate(requestCreationOptionsControllerProvider(query)),
      ),
      data: (result) => _buildForm(
        serviceTypes: serviceTypes,
        companies: companies,
        options: result,
      ),
    );
  }

  Widget _buildForm({
    required List<RequestServiceType> serviceTypes,
    required List<Company> companies,
    required RequestCreationOptions options,
  }) {
    final modalities = options.modalities
        .where(
          (item) =>
              item.code != RequestModalities.special ||
              options.canCreateSpecial,
        )
        .toList(growable: false);
    final isSpecial = _modality == RequestModalities.special;
    final hasOrigins = options.origins.isNotEmpty;
    final hasDestinations = isSpecial || options.destinations.isNotEmpty;
    final canSubmitRoute =
        _modality != null &&
        _originId != null &&
        (isSpecial || _destinationId != null);

    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text('Ruta', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: AppSpacing.xs),
          const Text('Define el traslado y declara los tubos y frascos.'),
          if (_error case final error?) ...[
            const SizedBox(height: AppSpacing.md),
            FormErrorSummary(message: error),
          ],
          const SizedBox(height: AppSpacing.lg),
          if (companies.length > 1)
            DropdownButtonFormField<String>(
              initialValue: _companyId,
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
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(growable: false),
              onChanged: _saving
                  ? null
                  : (value) => setState(() {
                      _companyId = value;
                      _modality = null;
                      _branchId = null;
                      _originId = null;
                      _destinationId = null;
                      _specialDestination.clear();
                      _fieldErrors = Map.of(_fieldErrors)..remove('empresa_id');
                    }),
            )
          else
            _FixedValue(label: 'Empresa', value: companies.first.name),
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<String>(
            key: ValueKey('modality-$_companyId'),
            initialValue: _modality,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: 'Modalidad del servicio',
              prefixIcon: const Icon(Icons.route_outlined),
              errorText: _fieldError('modalidad'),
            ),
            items: modalities
                .map(
                  (modality) => DropdownMenuItem(
                    value: modality.code,
                    child: Text(modality.name, overflow: TextOverflow.ellipsis),
                  ),
                )
                .toList(growable: false),
            validator: (value) =>
                value == null ? 'Selecciona la modalidad.' : null,
            onChanged: _saving
                ? null
                : (value) => setState(() {
                    _modality = value;
                    _branchId = null;
                    _originId = null;
                    _destinationId = null;
                    _specialDestination.clear();
                    _fieldErrors = Map.of(_fieldErrors)..remove('modalidad');
                  }),
          ),
          if (_modality case final modality?) ...[
            const SizedBox(height: AppSpacing.sm),
            _ModalityHint(modality: modality),
          ],
          const SizedBox(height: AppSpacing.md),
          AdaptiveFormRow(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _priority,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'Prioridad',
                  errorText: _fieldError('prioridad'),
                ),
                items: const [
                  DropdownMenuItem(value: 'NORMAL', child: Text('Normal')),
                  DropdownMenuItem(
                    value: 'PRIORITY',
                    child: Text('Prioritaria'),
                  ),
                ],
                onChanged: _saving
                    ? null
                    : (value) => setState(() {
                        _priority = value ?? 'NORMAL';
                        _fieldErrors = Map.of(_fieldErrors)
                          ..remove('prioridad');
                      }),
              ),
              DropdownButtonFormField<String>(
                initialValue: _serviceTypeId,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'Servicio',
                  errorText: _fieldError('tipo_servicio_id'),
                ),
                items: serviceTypes
                    .map(
                      (type) => DropdownMenuItem(
                        value: type.id,
                        child: Text(type.name, overflow: TextOverflow.ellipsis),
                      ),
                    )
                    .toList(growable: false),
                validator: (value) =>
                    value == null ? 'Selecciona el tipo de servicio.' : null,
                onChanged: _saving
                    ? null
                    : (value) => setState(() {
                        _serviceTypeId = value;
                        _fieldErrors = Map.of(_fieldErrors)
                          ..remove('tipo_servicio_id');
                      }),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          DropdownButtonFormField<String>(
            key: ValueKey('origin-$_companyId-$_modality'),
            initialValue: _originId,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: 'Origen',
              prefixIcon: const Icon(Icons.trip_origin),
              errorText: _fieldError('origen_id'),
            ),
            items: options.origins
                .map(
                  (item) => DropdownMenuItem(
                    value: item.location.id,
                    child: Text(
                      item.displayName,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(growable: false),
            validator: (value) =>
                value == null ? 'Selecciona el origen.' : null,
            onChanged: _saving || _modality == null
                ? null
                : (value) => setState(() {
                    final selected = options.origins
                        .where((item) => item.location.id == value)
                        .firstOrNull;
                    _branchId = selected?.branchId;
                    _originId = value;
                    _destinationId = null;
                    _fieldErrors = Map.of(_fieldErrors)
                      ..remove('origen_id')
                      ..remove('destino_id');
                  }),
          ),
          const SizedBox(height: AppSpacing.md),
          if (!isSpecial)
            DropdownButtonFormField<String>(
              key: ValueKey('destination-$_companyId-$_modality-$_originId'),
              initialValue: _destinationId,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: _modality == RequestModalities.betweenBranches
                    ? 'Sucursal de destino'
                    : 'Empresa de transporte',
                prefixIcon: const Icon(Icons.location_on_outlined),
                errorText: _fieldError('destino_id'),
              ),
              items: options.destinations
                  .map(
                    (item) => DropdownMenuItem(
                      value: item.location.id,
                      child: Text(
                        item.displayName,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(growable: false),
              validator: (value) {
                if (value == null) return 'Selecciona el destino.';
                if (value == _originId) return 'El destino debe ser diferente.';
                return null;
              },
              onChanged: _saving || _originId == null
                  ? null
                  : (value) => setState(() {
                      _destinationId = value;
                      _fieldErrors = Map.of(_fieldErrors)..remove('destino_id');
                    }),
            )
          else
            TextFormField(
              controller: _specialDestination,
              enabled: !_saving,
              maxLength: 500,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'Destino especial',
                hintText: 'Describe el punto exacto de entrega',
                prefixIcon: const Icon(Icons.edit_location_alt_outlined),
                errorText: _fieldError('destino_especial'),
              ),
              onChanged: (_) => _clearFieldError('destino_especial'),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Describe el destino especial.'
                  : null,
            ),
          if (options.availabilityMessage != null ||
              _modality == null ||
              !hasOrigins ||
              !hasDestinations) ...[
            const SizedBox(height: AppSpacing.sm),
            _FormNotice(
              icon: Icons.info_outline,
              message:
                  options.availabilityMessage ??
                  (_modality == null
                      ? 'Selecciona una modalidad para preparar la ruta.'
                      : !hasOrigins
                      ? 'No hay un origen habilitado para esta solicitud.'
                      : _modality == RequestModalities.betweenBranches
                      ? (_originId == null
                            ? 'Selecciona el origen. Luego aparecerán las sucursales permitidas del mismo país y departamento.'
                            : 'No hay sucursales de destino disponibles en el mismo departamento.')
                      : 'No hay empresas de transporte habilitadas como destino.'),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          Text('Contenido', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          const Text('Puedes llevar solo tubos, solo frascos o ambos.'),
          const SizedBox(height: AppSpacing.md),
          AdaptiveFormRow(
            children: [
              TextFormField(
                controller: _tubeCount,
                enabled: !_saving,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Tubos',
                  errorText: _fieldError('cantidad_tubos'),
                ),
                validator: (value) =>
                    nonNegativeContainerCountError(value, 'los tubos'),
                onChanged: (_) {
                  _clearFieldError('cantidad_tubos');
                  setState(() {});
                },
              ),
              TextFormField(
                controller: _flaskCount,
                enabled: !_saving,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Frascos',
                  errorText: _fieldError('cantidad_frascos'),
                ),
                validator: (value) =>
                    nonNegativeContainerCountError(value, 'los frascos') ??
                    containerLoadError(_tubeCount.text, value),
                onChanged: (_) {
                  _clearFieldError('cantidad_frascos');
                  setState(() {});
                },
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: _notes,
            enabled: !_saving,
            minLines: 2,
            maxLines: 5,
            maxLength: 1000,
            decoration: InputDecoration(
              labelText: 'Indicaciones adicionales (opcional)',
              alignLabelWithHint: true,
              errorText: _fieldError('notas'),
            ),
            onChanged: (_) => _clearFieldError('notas'),
          ),
          const SizedBox(height: AppSpacing.xl),
          FilledButton.icon(
            onPressed: _saving || !canSubmitRoute ? null : _save,
            icon: _saving
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.local_shipping_outlined),
            label: const Text('Crear solicitud'),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final modality = _modality;
    if (modality == null) return;
    final isSpecial = modality == RequestModalities.special;
    setState(() {
      _saving = true;
      _error = null;
      _fieldErrors = const {};
    });
    try {
      final input = CreateServiceRequestInput(
        companyId: _companyId!,
        tubeCount: int.parse(_tubeCount.text.trim()),
        flaskCount: int.parse(_flaskCount.text.trim()),
        branchId: _branchId,
        priority: _priority,
        modality: modality,
        serviceTypeId: _serviceTypeId!,
        originId: _originId!,
        destinationId: isSpecial ? null : _destinationId,
        specialDestination: isSpecial ? _specialDestination.text : null,
        notes: _notes.text,
      );
      await ref.read(requestActionsControllerProvider).create(input);
      ref.invalidate(requesterSummaryControllerProvider);
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

class _ModalityHint extends StatelessWidget {
  const _ModalityHint({required this.modality});

  final String modality;

  @override
  Widget build(BuildContext context) {
    final message = switch (modality) {
      RequestModalities.betweenBranches => 'Traslado entre sucursales de la misma empresa, país y departamento. Pueden estar en distintas ciudades o municipios.',
      RequestModalities.transportCompany =>
        'Entrega desde una sucursal hacia una empresa de transporte aprobada.',
      RequestModalities.special => 'Destino libre. La distancia se calculará con el recorrido real del motorista.',
      _ => '',
    };
    return _FormNotice(icon: Icons.info_outline, message: message);
  }
}

class _FormNotice extends StatelessWidget {
  const _FormNotice({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.primaryContainer.withValues(alpha: 0.38),
        borderRadius: BorderRadius.circular(AppRadii.control),
        border: Border.all(color: colors.primary.withValues(alpha: 0.16)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: colors.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}

class _FixedValue extends StatelessWidget {
  const _FixedValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(labelText: label),
      child: Text(value),
    );
  }
}
