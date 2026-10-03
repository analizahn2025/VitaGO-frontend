import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vitago_app/app/config/app_config.dart';
import 'package:vitago_app/app/theme/app_design_tokens.dart';
import 'package:vitago_app/core/errors/app_failure.dart';
import 'package:vitago_app/core/widgets/adaptive_form_row.dart';
import 'package:vitago_app/core/widgets/async_state_view.dart';
import 'package:vitago_app/core/widgets/form_error_summary.dart';
import 'package:vitago_app/features/locations/controllers/locations_controller.dart';
import 'package:vitago_app/features/locations/models/location_inputs.dart';
import 'package:vitago_app/features/locations/models/location_type.dart';
import 'package:vitago_app/features/organizations/models/company.dart';

const _corporateLocationTypeCodes = {'SUCURSAL', 'EMPRESA_TRANSPORTE'};

class CreateLocationView extends ConsumerStatefulWidget {
  const CreateLocationView({required this.company, super.key});

  final Company company;

  @override
  ConsumerState<CreateLocationView> createState() => _CreateLocationViewState();
}

class _CreateLocationViewState extends ConsumerState<CreateLocationView> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _department = TextEditingController();
  final _municipality = TextEditingController();
  final _city = TextEditingController();
  final _neighborhood = TextEditingController();
  final _address = TextEditingController();
  final _latitude = TextEditingController();
  final _longitude = TextEditingController();
  final _phone = TextEditingController();
  final _contact = TextEditingController();
  final _instructions = TextEditingController();
  String? _typeId;
  bool _allowsOrigin = true;
  bool _allowsDestination = true;
  bool _saving = false;
  String? _error;
  Map<String, List<String>> _fieldErrors = const {};

  @override
  void dispose() {
    for (final controller in [
      _name,
      _department,
      _municipality,
      _city,
      _neighborhood,
      _address,
      _latitude,
      _longitude,
      _phone,
      _contact,
      _instructions,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(appConfigProvider);
    final country = widget.company.country;
    if (country == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Registrar ubicación')),
        body: const AppEmptyView(
          icon: Icons.public_off_outlined,
          title: 'País no disponible',
          message:
              'No es posible registrar la ubicación hasta conocer el país de '
              'la empresa.',
        ),
      );
    }

    final types = ref.watch(locationTypesControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Registrar ubicación')),
      body: SafeArea(
        child: types.when(
          loading: () =>
              const AppLoadingView(label: 'Cargando tipos de ubicación…'),
          error: (error, stackTrace) => AppErrorView(
            error: error,
            onRetry: () => ref.invalidate(locationTypesControllerProvider),
          ),
          data: (items) => SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    widget.company.name,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text('${country.name} · Registro manual'),
                  if (_error case final error?) ...[
                    const SizedBox(height: AppSpacing.md),
                    FormErrorSummary(message: error),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  TextFormField(
                    controller: _name,
                    enabled: !_saving,
                    decoration: InputDecoration(
                      labelText: 'Nombre del lugar',
                      errorText: _fieldError('nombre'),
                    ),
                    onChanged: (_) => _clearFieldError('nombre'),
                    validator: _required,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (_visibleTypes(items, config.isCorporate).isEmpty)
                    const _MissingLocationTypesNotice()
                  else
                    DropdownButtonFormField<String>(
                      initialValue: _typeId,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'Tipo',
                        errorText: _fieldError('tipo_ubicacion_id'),
                      ),
                      items: _visibleTypes(items, config.isCorporate)
                          .map(
                            (item) => DropdownMenuItem(
                              value: item.id,
                              child: Text(
                                item.name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: _saving
                          ? null
                          : (value) => setState(() {
                              _typeId = value;
                              _fieldErrors = Map.of(_fieldErrors)
                                ..remove('tipo_ubicacion_id');
                            }),
                      validator: (value) => value == null
                          ? 'Selecciona un tipo de ubicación.'
                          : null,
                    ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _address,
                    enabled: !_saving,
                    decoration: InputDecoration(
                      labelText: 'Dirección',
                      errorText: _fieldError('direccion'),
                    ),
                    onChanged: (_) => _clearFieldError('direccion'),
                    validator: _required,
                    minLines: 2,
                    maxLines: 3,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AdaptiveFormRow(
                    children: [
                      TextFormField(
                        controller: _latitude,
                        enabled: !_saving,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[-0-9.]')),
                        ],
                        decoration: InputDecoration(
                          labelText: 'Latitud',
                          hintText: '14.072300',
                          errorText: _fieldError('latitud'),
                        ),
                        onChanged: (_) => _clearFieldError('latitud'),
                        validator: (value) => _coordinate(value, -90, 90),
                      ),
                      TextFormField(
                        controller: _longitude,
                        enabled: !_saving,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[-0-9.]')),
                        ],
                        decoration: InputDecoration(
                          labelText: 'Longitud',
                          hintText: '-87.192100',
                          errorText: _fieldError('longitud'),
                        ),
                        onChanged: (_) => _clearFieldError('longitud'),
                        validator: (value) => _coordinate(value, -180, 180),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'División territorial',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextFormField(
                    controller: _department,
                    enabled: !_saving,
                    decoration: InputDecoration(
                      labelText: 'Departamento',
                      errorText: _fieldError('departamento'),
                    ),
                    onChanged: (_) => _clearFieldError('departamento'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _municipality,
                    enabled: !_saving,
                    decoration: InputDecoration(
                      labelText: 'Municipio',
                      errorText: _fieldError('municipio'),
                    ),
                    onChanged: (_) => _clearFieldError('municipio'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _city,
                    enabled: !_saving,
                    decoration: InputDecoration(
                      labelText: 'Ciudad',
                      errorText: _fieldError('ciudad'),
                    ),
                    onChanged: (_) => _clearFieldError('ciudad'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _neighborhood,
                    enabled: !_saving,
                    decoration: InputDecoration(
                      labelText: 'Colonia',
                      errorText: _fieldError('colonia'),
                    ),
                    onChanged: (_) => _clearFieldError('colonia'),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Contacto e instrucciones',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextFormField(
                    controller: _phone,
                    enabled: !_saving,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Teléfono',
                      errorText: _fieldError('telefono'),
                    ),
                    onChanged: (_) => _clearFieldError('telefono'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _contact,
                    enabled: !_saving,
                    decoration: InputDecoration(
                      labelText: 'Nombre de contacto',
                      errorText: _fieldError('nombre_contacto'),
                    ),
                    onChanged: (_) => _clearFieldError('nombre_contacto'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _instructions,
                    enabled: !_saving,
                    decoration: InputDecoration(
                      labelText: 'Instrucciones para el delivery',
                      errorText: _fieldError('instrucciones'),
                    ),
                    onChanged: (_) => _clearFieldError('instrucciones'),
                    minLines: 2,
                    maxLines: 4,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Permitir como origen'),
                    value: _allowsOrigin,
                    onChanged: _saving
                        ? null
                        : (value) => setState(() => _allowsOrigin = value),
                  ),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Permitir como destino'),
                    value: _allowsDestination,
                    onChanged: _saving
                        ? null
                        : (value) => setState(() => _allowsDestination = value),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  FilledButton.icon(
                    onPressed:
                        _saving ||
                            _visibleTypes(items, config.isCorporate).isEmpty
                        ? null
                        : _save,
                    icon: _saving
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.add_location_alt_outlined),
                    label: const Text('Registrar ubicación'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<LocationType> _visibleTypes(List<LocationType> items, bool isCorporate) {
    if (!isCorporate) return items;
    return items
        .where(
          (item) => _corporateLocationTypeCodes.contains(
            item.code.trim().toUpperCase(),
          ),
        )
        .toList(growable: false);
  }

  String? _required(String? value) => value == null || value.trim().isEmpty
      ? 'Este campo es obligatorio.'
      : null;

  String? _coordinate(String? value, double min, double max) {
    final number = double.tryParse(value?.trim() ?? '');
    if (number == null || number < min || number > max) {
      return 'Valor inválido.';
    }
    return null;
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (!_allowsOrigin && !_allowsDestination) {
      setState(() {
        _error = 'Permite la ubicación como origen, destino o ambos.';
      });
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
      _fieldErrors = const {};
    });
    try {
      await ref
          .read(locationActionsControllerProvider)
          .createLocation(
            CreateLocationInput(
              companyId: widget.company.id,
              name: _name.text,
              locationTypeId: _typeId!,
              countryId: widget.company.country!.id,
              department: _department.text,
              municipality: _municipality.text,
              city: _city.text,
              neighborhood: _neighborhood.text,
              address: _address.text,
              latitude: _latitude.text,
              longitude: _longitude.text,
              phone: _phone.text,
              contactName: _contact.text,
              instructions: _instructions.text,
              allowsOrigin: _allowsOrigin,
              allowsDestination: _allowsDestination,
            ),
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

class _MissingLocationTypesNotice extends StatelessWidget {
  const _MissingLocationTypesNotice();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(AppRadii.control),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: colors.onErrorContainer),
          const SizedBox(width: AppSpacing.sm),
          const Expanded(
            child: Text(
              'No están disponibles los tipos Sucursal o Empresa de transporte.',
            ),
          ),
        ],
      ),
    );
  }
}
