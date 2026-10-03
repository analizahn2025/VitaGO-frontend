import 'package:vitago_app/core/models/json_readers.dart';

class OperationalEvidence {
  const OperationalEvidence({
    required this.id,
    required this.contentType,
    required this.sizeBytes,
    required this.latitude,
    required this.longitude,
    required this.capturedAt,
    required this.fileAvailable,
    required this.createdAt,
    this.requestId,
    this.incidentId,
    this.driverId,
    this.type,
    this.notes,
  });

  factory OperationalEvidence.fromJson(Map<String, dynamic> json) {
    return OperationalEvidence(
      id: requireString(json, 'id'),
      requestId: optionalString(json, 'solicitud_id'),
      incidentId: optionalString(json, 'incidencia_id'),
      driverId: optionalString(json, 'repartidor_id'),
      type: optionalString(json, 'tipo'),
      contentType: requireString(json, 'tipo_contenido'),
      sizeBytes: optionalInt(json, 'tamano_bytes'),
      latitude: requireString(json, 'latitud'),
      longitude: requireString(json, 'longitud'),
      capturedAt: requireDateTime(json, 'capturada_en'),
      notes: optionalString(json, 'notas'),
      fileAvailable: optionalBool(json, 'archivo_disponible'),
      createdAt: requireDateTime(json, 'creado_en'),
    );
  }

  final String id;
  final String? requestId;
  final String? incidentId;
  final String? driverId;
  final String? type;
  final String contentType;
  final int sizeBytes;
  final String latitude;
  final String longitude;
  final DateTime capturedAt;
  final String? notes;
  final bool fileAvailable;
  final DateTime createdAt;
}

class EvidenceUploadInput {
  const EvidenceUploadInput({
    required this.filePath,
    required this.fileName,
    required this.latitude,
    required this.longitude,
    required this.capturedAt,
    this.type,
    this.notes,
  });

  final String filePath;
  final String fileName;
  final String latitude;
  final String longitude;
  final DateTime capturedAt;
  final String? type;
  final String? notes;
}

class EvidenceFile {
  const EvidenceFile({required this.bytes, required this.contentType});

  final List<int> bytes;
  final String contentType;
}
