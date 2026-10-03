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
import 'package:vitago_app/features/fleet/controllers/fleet_controller.dart';
import 'package:vitago_app/features/fleet/models/fleet_inputs.dart';
import 'package:vitago_app/features/organizations/controllers/organizations_controller.dart';
import 'package:vitago_app/features/organizations/models/company.dart';
import 'package:vitago_app/features/profile/models/user_profile.dart';

class CreateVehicleView extends ConsumerStatefulWidget {
  const CreateVehicleView({required this.profile, super.key});

  final UserProfile profile;

  @override
  ConsumerState<CreateVehicleView> createState() => _CreateVehicleViewState();
}

class _CreateVehicleViewState extends ConsumerState<CreateVehicleView> {
  final _formKey = GlobalKey<FormState>();
  final _plate = TextEditingController();
  final _brand = TextEditingController();
  final _model = TextEditingController();
  final _year = TextEditingController();
  final _notes = TextEditingController();
  String? _companyId;
  String _status = 'ACTIVO';
  bool _saving = false;
  String? _error;
  Map<String, List<String>> _fieldErrors = const {};

  @override
  void dispose() {
    _plate.dispose();
    _brand.dispose();
    _model.dispose();
    _year.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(appConfigProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Registrar motocicleta')),
      body: SafeArea(
        child: config.isCorporate ? _buildCorporate() : _buildForm(const []),
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
              message: 'Se necesita una empresa para registrar el vehículo.',
            );
          }
          _companyId ??= result.items.first.id;
          return _buildForm(result.items);
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
    return _buildForm([
      Company(id: company.id, name: company.name, status: 'ACTIVO'),
    ]);
  }

  Widget _buildForm(List<Company> companies) {
    final isCorporate = ref.watch(appConfigProvider).isCorporate;
    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text(
            'Datos de la motocicleta',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          const Text('Registra la información usada por la operación.'),
          if (_error case final error?) ...[
            const SizedBox(height: AppSpacing.md),
            FormErrorSummary(message: error),
          ],
          const SizedBox(height: AppSpacing.lg),
          if (isCorporate && companies.length > 1)
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
                      _fieldErrors = Map.of(_fieldErrors)..remove('empresa_id');
                    }),
            )
          else if (isCorporate)
            InputDecorator(
              decoration: const InputDecoration(labelText: 'Empresa'),
              child: Text(companies.first.name),
            ),
          if (isCorporate) const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: _plate,
            enabled: !_saving,
            textCapitalization: TextCapitalization.characters,
            maxLength: 20,
            decoration: InputDecoration(
              labelText: 'Placa',
              errorText: _fieldError('placa'),
            ),
            onChanged: (_) => _clearFieldError('placa'),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Ingresa la placa.'
                : null,
          ),
          const SizedBox(height: AppSpacing.sm),
          DropdownButtonFormField<String>(
            initialValue: _status,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: 'Estado',
              errorText: _fieldError('estado'),
            ),
            items: const [
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
            onChanged: _saving
                ? null
                : (value) => setState(() {
                    _status = value ?? _status;
                    _fieldErrors = Map.of(_fieldErrors)..remove('estado');
                  }),
          ),
          const SizedBox(height: AppSpacing.md),
          AdaptiveFormRow(
            children: [
              TextFormField(
                controller: _brand,
                enabled: !_saving,
                decoration: InputDecoration(
                  labelText: 'Marca (opcional)',
                  errorText: _fieldError('marca'),
                ),
                onChanged: (_) => _clearFieldError('marca'),
              ),
              TextFormField(
                controller: _model,
                enabled: !_saving,
                decoration: InputDecoration(
                  labelText: 'Modelo (opcional)',
                  errorText: _fieldError('modelo'),
                ),
                onChanged: (_) => _clearFieldError('modelo'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: _year,
            enabled: !_saving,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: 'Año (opcional)',
              errorText: _fieldError('anio'),
            ),
            onChanged: (_) => _clearFieldError('anio'),
            validator: (value) {
              if (value == null || value.trim().isEmpty) return null;
              final year = int.tryParse(value);
              final maximum = DateTime.now().year + 1;
              return year == null || year < 1900 || year > maximum
                  ? 'Año entre 1900 y $maximum.'
                  : null;
            },
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: _notes,
            enabled: !_saving,
            minLines: 2,
            maxLines: 5,
            maxLength: 500,
            decoration: InputDecoration(
              labelText: 'Notas (opcional)',
              alignLabelWithHint: true,
              errorText: _fieldError('notas'),
            ),
            onChanged: (_) => _clearFieldError('notas'),
          ),
          const SizedBox(height: AppSpacing.xl),
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.two_wheeler),
            label: const Text('Registrar motocicleta'),
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
      _fieldErrors = const {};
    });
    try {
      await ref
          .read(fleetActionsControllerProvider)
          .createVehicle(
            CreateVehicleInput(
              companyId: _companyId,
              plate: _plate.text,
              type: 'MOTOCICLETA',
              brand: _brand.text,
              model: _model.text,
              year: _year.text.trim().isEmpty ? null : int.parse(_year.text),
              status: _status,
              notes: _notes.text,
            ),
            isCorporate: config.isCorporate,
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
