import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vitago_app/app/theme/app_design_tokens.dart';
import 'package:vitago_app/core/device/device_location_service.dart';
import 'package:vitago_app/core/errors/app_failure.dart';
import 'package:vitago_app/features/incidents/controllers/incidents_controller.dart';
import 'package:vitago_app/features/incidents/models/incident.dart';
import 'package:vitago_app/features/tracking/providers/tracking_providers.dart';

class CreateIncidentView extends ConsumerStatefulWidget {
  const CreateIncidentView({super.key});

  @override
  ConsumerState<CreateIncidentView> createState() => _CreateIncidentViewState();
}

class _CreateIncidentViewState extends ConsumerState<CreateIncidentView> {
  final _formKey = GlobalKey<FormState>();
  final _description = TextEditingController();
  DeviceLocation? _location;
  bool _locating = false;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reportar incidencia')),
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
                  'Describe lo ocurrido',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                const Text(
                  'El reporte quedará asociado a tu jornada activa y conservará su historial de revisión.',
                ),
                if (_error case final error?) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    error,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                TextFormField(
                  controller: _description,
                  enabled: !_saving,
                  minLines: 4,
                  maxLines: 7,
                  maxLength: 1000,
                  decoration: const InputDecoration(
                    labelText: 'Descripción',
                    hintText: 'Explica qué ocurrió y cómo afecta la operación.',
                    alignLabelWithHint: true,
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Describe la incidencia.'
                      : null,
                ),
                const SizedBox(height: AppSpacing.lg),
                _LocationPanel(
                  location: _location,
                  loading: _locating,
                  onCapture: _captureLocation,
                  onClear: _location == null
                      ? null
                      : () => setState(() => _location = null),
                ),
                const SizedBox(height: AppSpacing.xl),
                FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.report_problem_outlined),
                  label: const Text('Enviar incidencia'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _captureLocation() async {
    setState(() {
      _locating = true;
      _error = null;
    });
    try {
      final location = await ref
          .read(deviceLocationServiceProvider)
          .getCurrentLocation();
      if (mounted) setState(() => _location = location);
    } on AppFailure catch (failure) {
      if (mounted) setState(() => _error = failure.message);
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(incidentActionsControllerProvider)
          .create(
            CreateIncidentInput(
              description: _description.text,
              latitude: _location?.latitudeText,
              longitude: _location?.longitudeText,
              reportedAt: DateTime.now(),
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

class _LocationPanel extends StatelessWidget {
  const _LocationPanel({
    required this.location,
    required this.loading,
    required this.onCapture,
    required this.onClear,
  });

  final DeviceLocation? location;
  final bool loading;
  final VoidCallback onCapture;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.primaryContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(AppRadii.control),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              location == null
                  ? 'Ubicación opcional'
                  : '${location!.latitudeText}, ${location!.longitudeText}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              location == null
                  ? 'Puedes adjuntar el punto donde ocurrió la incidencia.'
                  : 'Punto capturado desde este dispositivo.',
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                FilledButton.tonalIcon(
                  onPressed: loading ? null : onCapture,
                  icon: loading
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location),
                  label: Text(
                    location == null ? 'Obtener ubicación' : 'Actualizar',
                  ),
                ),
                if (onClear != null)
                  TextButton(onPressed: onClear, child: const Text('Quitar')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
