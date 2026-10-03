import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vitago_app/app/theme/app_design_tokens.dart';
import 'package:vitago_app/core/device/device_location_service.dart';
import 'package:vitago_app/core/errors/app_failure.dart';
import 'package:vitago_app/features/evidence/controllers/evidence_controller.dart';
import 'package:vitago_app/features/evidence/models/operational_evidence.dart';
import 'package:vitago_app/features/evidence/providers/evidence_providers.dart';
import 'package:vitago_app/features/evidence/widgets/evidence_photo_chooser.dart';
import 'package:vitago_app/features/tracking/providers/tracking_providers.dart';
import 'package:vitago_app/features/tracking/widgets/required_gps_body.dart';

class AddRequestEvidenceView extends ConsumerStatefulWidget {
  const AddRequestEvidenceView({
    required this.requestId,
    required this.allowedTypes,
    this.gpsRequired = false,
    super.key,
  });

  final String requestId;
  final List<String> allowedTypes;
  final bool gpsRequired;

  @override
  ConsumerState<AddRequestEvidenceView> createState() =>
      _AddRequestEvidenceViewState();
}

class _AddRequestEvidenceViewState
    extends ConsumerState<AddRequestEvidenceView> {
  final _notes = TextEditingController();
  XFile? _photo;
  DateTime? _capturedAt;
  DeviceLocation? _location;
  String? _type;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.allowedTypes.length == 1) _type = widget.allowedTypes.single;
    Future<void>.microtask(_recoverLostPhoto);
    if (widget.gpsRequired) Future<void>.microtask(_captureLocation);
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
        child: RequiredGpsBody(
          enabled: widget.gpsRequired,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Text(
                'Evidencia de solicitud',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: AppSpacing.xs),
              const Text(
                'La imagen será privada y conservará la ubicación de captura.',
              ),
              if (_error case final error?) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  error,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              DropdownButtonFormField<String>(
                initialValue: _type,
                decoration: const InputDecoration(
                  labelText: 'Tipo de evidencia',
                ),
                items: widget.allowedTypes
                    .map(
                      (type) => DropdownMenuItem(
                        value: type,
                        child: Text(_evidenceTypeLabel(type)),
                      ),
                    )
                    .toList(growable: false),
                onChanged: _busy
                    ? null
                    : (value) => setState(() => _type = value),
              ),
              const SizedBox(height: AppSpacing.md),
              EvidencePhotoChooser(
                photo: _photo,
                enabled: !_busy,
                onCamera: () => _selectPhoto(camera: true),
                onGallery: () => _selectPhoto(camera: false),
              ),
              const SizedBox(height: AppSpacing.md),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.my_location),
                title: Text(
                  _location == null
                      ? 'Ubicación requerida'
                      : '${_location!.latitudeText}, ${_location!.longitudeText}',
                ),
                subtitle: const Text('Se adjunta para trazabilidad operativa.'),
                trailing: IconButton(
                  onPressed: _busy ? null : _captureLocation,
                  tooltip: 'Obtener ubicación',
                  icon: const Icon(Icons.refresh),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _notes,
                enabled: !_busy,
                minLines: 2,
                maxLines: 4,
                maxLength: 500,
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
      ),
    );
  }

  Future<void> _recoverLostPhoto() async {
    try {
      final photo = await ref
          .read(evidenceCaptureServiceProvider)
          .recoverLostPhoto();
      if (photo != null && mounted) {
        setState(() {
          _photo = photo;
          _capturedAt = DateTime.now();
        });
      }
    } on Object {
      if (mounted) {
        setState(() => _error = 'No fue posible recuperar la imagen anterior.');
      }
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
      if (await photo.length() > 10 * 1024 * 1024) {
        setState(() => _error = 'La imagen no puede superar 10 MB.');
        return;
      }
      setState(() {
        _photo = photo;
        _capturedAt = DateTime.now();
      });
    } on Object {
      if (mounted) setState(() => _error = 'No fue posible obtener la imagen.');
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
    if (_type == null) {
      setState(() => _error = 'Selecciona el tipo de evidencia.');
      return;
    }
    if (_photo == null) {
      setState(() => _error = 'Toma o selecciona una imagen.');
      return;
    }
    if (_location == null) {
      await _captureLocation();
    }
    if (_location == null) {
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
          .uploadRequest(
            widget.requestId,
            EvidenceUploadInput(
              filePath: _photo!.path,
              fileName: _photo!.name,
              latitude: _location!.latitudeText,
              longitude: _location!.longitudeText,
              capturedAt: _capturedAt ?? DateTime.now(),
              type: _type,
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

String _evidenceTypeLabel(String type) => switch (type) {
  'FOTO_RECOLECCION' => 'Foto de recolección',
  'FOTO_ENTREGA' => 'Foto de entrega',
  'FOTO_INCIDENCIA' => 'Foto de incidencia',
  _ => type.replaceAll('_', ' ').toLowerCase(),
};
