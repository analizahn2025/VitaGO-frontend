import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vitago_app/app/theme/app_design_tokens.dart';
import 'package:vitago_app/core/errors/app_failure.dart';
import 'package:vitago_app/core/permissions/app_permissions.dart';
import 'package:vitago_app/core/validation/operational_values.dart';
import 'package:vitago_app/core/widgets/adaptive_form_row.dart';
import 'package:vitago_app/features/fleet/controllers/fleet_controller.dart';
import 'package:vitago_app/features/profile/models/user_profile.dart';
import 'package:vitago_app/features/requests/controllers/requests_controller.dart';
import 'package:vitago_app/features/requests/models/request_inputs.dart';
import 'package:vitago_app/features/requests/models/request_models.dart';
import 'package:vitago_app/features/routes/providers/routes_providers.dart';

bool canUpdateRequestLoad(ServiceRequestDetail request, UserProfile profile) =>
    profile.can(AppPermissions.assignRequests) &&
    !request.isTerminal &&
    (_beforePickup(request.status) ||
        request.summary.tubeCount == null ||
        request.summary.flaskCount == null);

bool _beforePickup(String status) => const {
  'PENDING',
  'ASSIGNED',
  'GOING_TO_PICKUP',
  'AT_PICKUP',
}.contains(status);

class UpdateRequestLoadView extends ConsumerStatefulWidget {
  const UpdateRequestLoadView({
    required this.request,
    required this.profile,
    super.key,
  });

  final ServiceRequestDetail request;
  final UserProfile profile;

  @override
  ConsumerState<UpdateRequestLoadView> createState() =>
      _UpdateRequestLoadViewState();
}

class _UpdateRequestLoadViewState extends ConsumerState<UpdateRequestLoadView> {
  final _form = GlobalKey<FormState>();
  late final _tubes = TextEditingController(
    text: widget.request.summary.tubeCount?.toString() ?? '',
  );
  late final _flasks = TextEditingController(
    text: widget.request.summary.flaskCount?.toString() ?? '',
  );
  final _reason = TextEditingController();
  AppFailure? _failure;
  bool _saving = false;

  bool get _canEditTubes =>
      _beforePickup(widget.request.status) ||
      widget.request.summary.tubeCount == null;
  bool get _canEditFlasks =>
      _beforePickup(widget.request.status) ||
      widget.request.summary.flaskCount == null;
  bool get _changed =>
      int.tryParse(_tubes.text.trim()) != widget.request.summary.tubeCount ||
      int.tryParse(_flasks.text.trim()) != widget.request.summary.flaskCount;

  @override
  void dispose() {
    _tubes.dispose();
    _flasks.dispose();
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!canUpdateRequestLoad(widget.request, widget.profile)) {
      return const Scaffold(
        body: SafeArea(
          child: Center(
            child: Text('No puedes cambiar la carga de este envío.'),
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Corregir carga')),
      body: SafeArea(
        child: Form(
          key: _form,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Text(
                widget.request.number,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.xs),
              const Text(
                'Confirma el conteo real. El servidor comprobará los cupos del motorista.',
              ),
              if (!_beforePickup(widget.request.status)) ...[
                const SizedBox(height: AppSpacing.sm),
                const Text(
                  'Después de la recolección solo puedes completar cantidades históricas sin registrar.',
                ),
              ],
              if (_failure case final failure?) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  failure.message,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              AdaptiveFormRow(
                children: [
                  TextFormField(
                    controller: _tubes,
                    enabled: _canEditTubes && !_saving,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Tubos',
                      errorText: _failure?.fieldMessage('cantidad_tubos'),
                    ),
                    validator: (value) =>
                        nonNegativeContainerCountError(value, 'los tubos'),
                    onChanged: (_) => setState(() => _failure = null),
                  ),
                  TextFormField(
                    controller: _flasks,
                    enabled: _canEditFlasks && !_saving,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Frascos',
                      errorText: _failure?.fieldMessage('cantidad_frascos'),
                    ),
                    validator: (value) =>
                        nonNegativeContainerCountError(value, 'los frascos') ??
                        containerLoadError(_tubes.text, value),
                    onChanged: (_) => setState(() => _failure = null),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _reason,
                enabled: !_saving,
                maxLength: 500,
                minLines: 2,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Motivo de la corrección',
                  errorText: _failure?.fieldMessage('motivo'),
                ),
                validator: (value) => value?.trim().isNotEmpty == true
                    ? null
                    : 'Indica el motivo del cambio.',
                onChanged: (_) => setState(() => _failure = null),
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton.icon(
                onPressed: _saving || !_changed ? null : _save,
                icon: _saving
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: const Text('Guardar carga'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_changed || !(_form.currentState?.validate() ?? false)) return;
    final tubes = int.parse(_tubes.text.trim());
    final flasks = int.parse(_flasks.text.trim());
    setState(() {
      _saving = true;
      _failure = null;
    });
    try {
      await ref
          .read(requestActionsControllerProvider)
          .updateLoad(
            widget.request.id,
            UpdateRequestLoadInput(
              tubeCount: tubes == widget.request.summary.tubeCount
                  ? null
                  : tubes,
              flaskCount: flasks == widget.request.summary.flaskCount
                  ? null
                  : flasks,
              reason: _reason.text,
            ),
          );
      ref.invalidate(requestControllerProvider(widget.request.id));
      ref.invalidate(requestsControllerProvider);
      ref.invalidate(requesterSummaryControllerProvider);
      ref.invalidate(ownDriverProfileControllerProvider);
      ref.invalidate(driversControllerProvider);
      ref.invalidate(availableDriversForRequestControllerProvider);
      ref.invalidate(myRouteProvider);
      if (mounted) Navigator.of(context).pop(true);
    } on AppFailure catch (failure) {
      if (mounted) setState(() => _failure = failure);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
