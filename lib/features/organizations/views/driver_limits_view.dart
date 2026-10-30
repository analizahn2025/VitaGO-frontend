import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vitago_app/app/config/app_config.dart';
import 'package:vitago_app/app/theme/app_design_tokens.dart';
import 'package:vitago_app/core/errors/app_failure.dart';
import 'package:vitago_app/core/permissions/administrative_scope.dart';
import 'package:vitago_app/core/permissions/app_permissions.dart';
import 'package:vitago_app/core/validation/operational_values.dart';
import 'package:vitago_app/core/widgets/adaptive_form_row.dart';
import 'package:vitago_app/core/widgets/async_state_view.dart';
import 'package:vitago_app/features/fleet/controllers/fleet_controller.dart';
import 'package:vitago_app/features/organizations/controllers/organizations_controller.dart';
import 'package:vitago_app/features/organizations/models/driver_limits.dart';
import 'package:vitago_app/features/profile/models/user_profile.dart';
import 'package:vitago_app/features/requests/controllers/requests_controller.dart';
import 'package:vitago_app/features/routes/providers/routes_providers.dart';

class DriverLimitsView extends ConsumerWidget {
  const DriverLimitsView({required this.profile, this.companyId, super.key});
  final UserProfile profile;
  final String? companyId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final corporate = ref.watch(appConfigProvider).isCorporate;
    final allowed = corporate
        ? companyId != null && profile.can(AppPermissions.viewCompanies)
        : true;
    return Scaffold(
      appBar: AppBar(
        title: Text(corporate ? 'Cupos de la empresa' : 'Cupos de Network'),
      ),
      body: SafeArea(
        child: !allowed
            ? const AppEmptyView(
                icon: Icons.lock_outline,
                title: 'Sin acceso a cupos',
                message: 'Tu perfil no puede consultar esta configuración.',
              )
            : ref
                  .watch(driverLimitsControllerProvider(companyId))
                  .when(
                    loading: () =>
                        const AppLoadingView(label: 'Cargando cupos…'),
                    error: (error, stack) => AppErrorView(
                      error: error,
                      onRetry: () => ref.invalidate(
                        driverLimitsControllerProvider(companyId),
                      ),
                    ),
                    data: (limits) => _LimitsForm(
                      limits: limits,
                      profile: profile,
                      companyId: companyId,
                      corporate: corporate,
                    ),
                  ),
      ),
    );
  }
}

class _LimitsForm extends ConsumerStatefulWidget {
  const _LimitsForm({
    required this.limits,
    required this.profile,
    required this.corporate,
    this.companyId,
  });
  final DriverLimits limits;
  final UserProfile profile;
  final bool corporate;
  final String? companyId;
  @override
  ConsumerState<_LimitsForm> createState() => _LimitsFormState();
}

class _LimitsFormState extends ConsumerState<_LimitsForm> {
  final _form = GlobalKey<FormState>();
  late final _tubes = TextEditingController(
    text: widget.limits.tubeLimit.toString(),
  );
  late final _requests = TextEditingController(
    text: widget.limits.requestLimit.toString(),
  );
  late final _flasks = TextEditingController(
    text: widget.limits.flaskLimit?.toString() ?? '',
  );
  final _reason = TextEditingController();
  AppFailure? _failure;
  bool _saving = false;
  @override
  void dispose() {
    _tubes.dispose();
    _requests.dispose();
    _flasks.dispose();
    _reason.dispose();
    super.dispose();
  }

  bool get _editable =>
      canEditDriverLimits(
        widget.profile,
        corporate: widget.corporate,
        companyId: widget.companyId,
      ) &&
      (widget.corporate
          ? widget.limits.scope == 'EMPRESA' &&
                widget.limits.companyId == widget.companyId
          : widget.limits.scope == 'RED');
  bool get _changed =>
      int.tryParse(_tubes.text.trim()) != widget.limits.tubeLimit ||
      (widget.limits.flaskLimit != null &&
          int.tryParse(_flasks.text.trim()) != widget.limits.flaskLimit) ||
      int.tryParse(_requests.text.trim()) != widget.limits.requestLimit;
  void _edited(String _) => setState(() => _failure = null);
  @override
  Widget build(BuildContext context) => Form(
    key: _form,
    autovalidateMode: AutovalidateMode.onUserInteraction,
    child: ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Text(
          widget.limits.scope == 'RED'
              ? 'Una configuración para toda la red'
              : 'Una configuración para la empresa',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        const Text(
          'Estos límites se aplican al cupo individual de cada motorista. No representan una bolsa de espacio compartida.',
        ),
        const SizedBox(height: AppSpacing.lg),
        if (_failure != null) ...[
          Text(
            _failure!.message,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        AdaptiveFormRow(
          children: [
            TextFormField(
              controller: _tubes,
              enabled: _editable && !_saving,
              keyboardType: TextInputType.number,
              onChanged: _edited,
              decoration: InputDecoration(
                labelText: 'Límite de tubos',
                errorMaxLines: 3,
                errorText: _failure?.fieldMessage('limite_tubos'),
              ),
              validator: tubeCountError,
            ),
            TextFormField(
              controller: _requests,
              enabled: _editable && !_saving,
              keyboardType: TextInputType.number,
              onChanged: _edited,
              decoration: InputDecoration(
                labelText: 'Límite de solicitudes',
                errorMaxLines: 3,
                helperText: 'Entre 1 y 5',
                errorText: _failure?.fieldMessage('limite_solicitudes'),
              ),
              validator: (value) {
                final parsed = int.tryParse(value?.trim() ?? '');
                return parsed != null && parsed >= 1 && parsed <= 5
                    ? null
                    : 'Usa un entero entre 1 y 5.';
              },
            ),
          ],
        ),
        if (widget.limits.flaskLimit != null) ...[
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: _flasks,
            enabled: _editable && !_saving,
            keyboardType: TextInputType.number,
            onChanged: _edited,
            decoration: InputDecoration(
              labelText: 'Límite de frascos',
              errorText: _failure?.fieldMessage('limite_frascos'),
            ),
            validator: tubeCountError,
          ),
        ],
        if (_editable) ...[
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: _reason,
            enabled: !_saving,
            maxLength: 1000,
            minLines: 2,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: 'Motivo (opcional)',
              errorMaxLines: 3,
              errorText: _failure?.fieldMessage('motivo'),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton.icon(
            onPressed: _saving || !_changed ? null : _save,
            icon: const Icon(Icons.save_outlined),
            label: Text(_saving ? 'Guardando…' : 'Guardar cupos'),
          ),
        ] else ...[
          const SizedBox(height: AppSpacing.md),
          const Text(
            'Consulta de solo lectura. La edición requiere permisos para todo el alcance de esta configuración.',
          ),
        ],
      ],
    ),
  );
  Future<void> _save() async {
    if (!_editable || !_changed || !(_form.currentState?.validate() ?? false)) {
      return;
    }
    setState(() {
      _saving = true;
      _failure = null;
    });
    try {
      await ref
          .read(organizationActionsControllerProvider)
          .updateDriverLimits(
            widget.companyId,
            UpdateDriverLimitsInput(
              tubeLimit:
                  int.parse(_tubes.text.trim()) == widget.limits.tubeLimit
                  ? null
                  : int.parse(_tubes.text.trim()),
              flaskLimit:
                  widget.limits.flaskLimit == null ||
                      int.parse(_flasks.text.trim()) == widget.limits.flaskLimit
                  ? null
                  : int.parse(_flasks.text.trim()),
              requestLimit:
                  int.parse(_requests.text.trim()) == widget.limits.requestLimit
                  ? null
                  : int.parse(_requests.text.trim()),
              reason: _reason.text,
            ),
          );
      ref.invalidate(companyControllerProvider);
      ref.invalidate(companiesControllerProvider);
      ref.invalidate(companySelectionControllerProvider);
      ref.invalidate(driverControllerProvider);
      ref.invalidate(driversControllerProvider);
      ref.invalidate(ownDriverProfileControllerProvider);
      ref.invalidate(availableDriversControllerProvider);
      ref.invalidate(availableDriversForRequestControllerProvider);
      ref.invalidate(requestsControllerProvider);
      ref.invalidate(requesterSummaryControllerProvider);
      ref.invalidate(myRouteProvider);
      ref.invalidate(driverLimitsControllerProvider(widget.companyId));
      if (mounted) Navigator.of(context).pop(true);
    } on AppFailure catch (failure) {
      if (mounted) setState(() => _failure = failure);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
