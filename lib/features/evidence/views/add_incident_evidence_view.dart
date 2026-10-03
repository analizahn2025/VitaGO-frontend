import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vitago_app/app/theme/app_design_tokens.dart';
import 'package:vitago_app/core/device/device_location_service.dart';
import 'package:vitago_app/core/errors/app_failure.dart';
import 'package:vitago_app/features/evidence/controllers/evidence_controller.dart';
import 'package:vitago_app/features/evidence/models/operational_evidence.dart';
import 'package:vitago_app/features/evidence/providers/evidence_providers.dart';
import 'package:vitago_app/features/tracking/providers/tracking_providers.dart';

class AddIncidentEvidenceView extends ConsumerStatefulWidget {
  const AddIncidentEvidenceView({required this.incidentId, super.key});

  final String incidentId;

  @override
  ConsumerState<AddIncidentEvidenceView> createState() =>
      _AddIncidentEvidenceViewState();
}

class _AddIncidentEvidenceViewState
    extends ConsumerState<AddIncidentEvidenceView> {
  final _notes = TextEditingController();
  XFile? _photo;
  DateTime? _capturedAt;
  DeviceLocation? _location;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(_recoverLostPhoto);
  }

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Agregar evidencia')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Text(
              'Evidencia de incidencia',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            const Text(
              'La imagen será privada y solo podrá consultarse con una sesión autorizada.',
            ),
            if (_error case final error?) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                error,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            _PhotoSelection(
              photo: _photo,
              enabled: !_busy,
              onCamera: () => _selectPhoto(camera: true),
              onGallery: () => _selectPhoto(camera: false),
            ),
            const SizedBox(height: AppSpacing.md),
            _EvidenceLocation(
              location: _location,
              loading: _busy,
              onCapture: _captureLocation,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _notes,
              enabled: !_busy,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Notas (opcional)',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton.icon(
              onPressed: _busy ? null : _upload,
              icon: _busy
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.cloud_upload_outlined),
              label: const Text('Guardar evidencia'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _recoverLostPhoto() async {
    final photo = await ref
        .read(evidenceCaptureServiceProvider)
        .recoverLostPhoto();
    if (photo != null && mounted) {
      setState(() {
        _photo = photo;
        _capturedAt = DateTime.now();
      });
    }
  }

  Future<void> _selectPhoto({required bool camera}) async {
    setState(() => _error = null);
    try {
      final service = ref.read(evidenceCaptureServiceProvider);
      final photo = camera
          ? await service.takePhoto()
          : await service.selectPhoto();
      if (photo == null || !mounted) return;
      final size = await photo.length();
      if (size > 10 * 1024 * 1024) {
        setState(() => _error = 'La imagen no puede superar 10 MB.');
        return;
      }
      setState(() {
        _photo = photo;
        _capturedAt = DateTime.now();
      });
    } on Object {
      if (mounted) {
        setState(() => _error = 'No fue posible obtener la imagen.');
      }
    }
  }

  Future<void> _captureLocation() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final value = await ref
          .read(deviceLocationServiceProvider)
          .getCurrentLocation();
      if (mounted) setState(() => _location = value);
    } on AppFailure catch (failure) {
      if (mounted) setState(() => _error = failure.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _upload() async {
    final photo = _photo;
    final location = _location;
    if (photo == null) {
      setState(() => _error = 'Toma o selecciona una imagen.');
      return;
    }
    if (location == null) {
      setState(() => _error = 'Obtén la ubicación de la evidencia.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(evidenceActionsControllerProvider)
          .uploadIncident(
            widget.incidentId,
            EvidenceUploadInput(
              filePath: photo.path,
              fileName: photo.name,
              latitude: location.latitudeText,
              longitude: location.longitudeText,
              capturedAt: _capturedAt ?? DateTime.now(),
              notes: _notes.text,
            ),
          );
      if (mounted) Navigator.of(context).pop(true);
    } on AppFailure catch (failure) {
      if (mounted) setState(() => _error = failure.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class _PhotoSelection extends StatelessWidget {
  const _PhotoSelection({
    required this.photo,
    required this.enabled,
    required this.onCamera,
    required this.onGallery,
  });

  final XFile? photo;
  final bool enabled;
  final VoidCallback onCamera;
  final VoidCallback onGallery;

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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              photo?.name ?? 'Ninguna imagen seleccionada',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                FilledButton.tonalIcon(
                  onPressed: enabled ? onCamera : null,
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: const Text('Tomar foto'),
                ),
                OutlinedButton.icon(
                  onPressed: enabled ? onGallery : null,
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Galería'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EvidenceLocation extends StatelessWidget {
  const _EvidenceLocation({
    required this.location,
    required this.loading,
    required this.onCapture,
  });

  final DeviceLocation? location;
  final bool loading;
  final VoidCallback onCapture;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.my_location),
      title: Text(
        location == null
            ? 'Ubicación requerida'
            : '${location!.latitudeText}, ${location!.longitudeText}',
      ),
      subtitle: const Text('Se adjunta al archivo para trazabilidad.'),
      trailing: IconButton(
        onPressed: loading ? null : onCapture,
        tooltip: 'Obtener ubicación',
        icon: const Icon(Icons.refresh),
      ),
    );
  }
}
