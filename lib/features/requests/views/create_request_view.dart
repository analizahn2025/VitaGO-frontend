import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vitago_app/app/config/app_config.dart';
import 'package:vitago_app/app/theme/app_design_tokens.dart';
import 'package:vitago_app/core/errors/app_failure.dart';
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
  final _specialDestination = TextEditingController();
  final List<_ArticleDraft> _articles = [_ArticleDraft()];
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
    _specialDestination.dispose();
    for (final article in _articles) {
      article.dispose();
    }
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
          const Text('Define el traslado y registra al menos un artículo.'),
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
                    _fieldErrors = Map.of(_fieldErrors)..remove('origen_id');
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
                      ? 'Selecciona el origen. Luego aparecerán las sucursales permitidas de la misma ciudad.'
                      : 'No hay empresas de transporte habilitadas como destino.'),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Artículos',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              TextButton.icon(
                onPressed: _saving ? null : _addArticle,
                icon: const Icon(Icons.add),
                label: const Text('Agregar'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (_fieldError('articulos') case final articlesError?) ...[
            _FormNotice(icon: Icons.error_outline, message: articlesError),
            const SizedBox(height: AppSpacing.sm),
          ],
          for (var index = 0; index < _articles.length; index++) ...[
            _ArticleEditor(
              index: index,
              draft: _articles[index],
              enabled: !_saving,
              canRemove: _articles.length > 1,
              onRemove: () => _removeArticle(index),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
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

  void _addArticle() => setState(() => _articles.add(_ArticleDraft()));

  void _removeArticle(int index) {
    final removed = _articles.removeAt(index);
    removed.dispose();
    setState(() {});
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
        branchId: _branchId,
        priority: _priority,
        modality: modality,
        serviceTypeId: _serviceTypeId!,
        originId: _originId!,
        destinationId: isSpecial ? null : _destinationId,
        specialDestination: isSpecial ? _specialDestination.text : null,
        notes: _notes.text,
        items: _articles.map((item) => item.toInput()).toList(growable: false),
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
      RequestModalities.betweenBranches =>
        'Traslado entre dos sucursales activas ubicadas en la misma ciudad.',
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

class _ArticleDraft {
  final type = TextEditingController();
  final description = TextEditingController();
  final quantity = TextEditingController(text: '1');
  final referenceCode = TextEditingController();
  final transportCondition = TextEditingController();
  final notes = TextEditingController();

  RequestArticleInput toInput() => RequestArticleInput(
    itemType: type.text,
    description: description.text,
    quantity: quantity.text.replaceAll(',', '.'),
    referenceCode: referenceCode.text,
    transportCondition: transportCondition.text,
    notes: notes.text,
  );

  void dispose() {
    type.dispose();
    description.dispose();
    quantity.dispose();
    referenceCode.dispose();
    transportCondition.dispose();
    notes.dispose();
  }
}

class _ArticleEditor extends StatelessWidget {
  const _ArticleEditor({
    required this.index,
    required this.draft,
    required this.enabled,
    required this.canRemove,
    required this.onRemove,
  });

  final int index;
  final _ArticleDraft draft;
  final bool enabled;
  final bool canRemove;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadii.control),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Artículo ${index + 1}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (canRemove)
                  IconButton(
                    onPressed: enabled ? onRemove : null,
                    tooltip: 'Quitar artículo',
                    icon: const Icon(Icons.delete_outline),
                  ),
              ],
            ),
            TextFormField(
              controller: draft.type,
              enabled: enabled,
              maxLength: 120,
              decoration: const InputDecoration(labelText: 'Tipo de artículo'),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Indica el tipo de artículo.'
                  : null,
            ),
            const SizedBox(height: AppSpacing.sm),
            AdaptiveFormRow(
              crossAxisAlignment: CrossAxisAlignment.start,
              flex: const [2, 1],
              children: [
                TextFormField(
                  controller: draft.description,
                  enabled: enabled,
                  decoration: const InputDecoration(
                    labelText: 'Descripción (opcional)',
                  ),
                ),
                TextFormField(
                  controller: draft.quantity,
                  enabled: enabled,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  ],
                  decoration: const InputDecoration(labelText: 'Cantidad'),
                  validator: (value) {
                    final number = double.tryParse(
                      (value ?? '').replaceAll(',', '.'),
                    );
                    return number == null || number <= 0
                        ? 'Mayor que 0.'
                        : null;
                  },
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: draft.transportCondition,
              enabled: enabled,
              decoration: const InputDecoration(
                labelText: 'Condición de transporte (opcional)',
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: draft.referenceCode,
              enabled: enabled,
              decoration: const InputDecoration(
                labelText: 'Código de referencia (opcional)',
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: draft.notes,
              enabled: enabled,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Notas del artículo (opcional)',
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
