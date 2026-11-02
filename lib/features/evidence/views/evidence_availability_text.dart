import 'package:vitago_app/core/formatters/app_date_format.dart';
import 'package:vitago_app/features/evidence/models/operational_evidence.dart';

String evidenceAvailabilityText(OperationalEvidence evidence, DateTime now) {
  if (!evidence.fileAvailable) {
    if (evidence.removedByRetentionAt(now)) {
      final removedAt = evidence.imageDeletedAt;
      return removedAt == null
          ? 'Imagen eliminada por retención'
          : 'Imagen eliminada por retención · ${AppDateFormat.dateTime(removedAt)}';
    }
    return 'Imagen no disponible';
  }
  final expiresAt = evidence.imageExpiresAt;
  return expiresAt == null
      ? 'Imagen disponible'
      : 'Disponible hasta ${AppDateFormat.dateTime(expiresAt)}';
}
