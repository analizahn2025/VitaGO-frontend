import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vitago_app/features/authentication/providers/auth_providers.dart';
import 'package:vitago_app/features/evidence/repositories/evidence_repository.dart';
import 'package:vitago_app/features/evidence/repositories/evidence_repository_impl.dart';
import 'package:vitago_app/features/evidence/services/evidence_api_service.dart';
import 'package:vitago_app/features/evidence/services/evidence_capture_service.dart';

final evidenceCaptureServiceProvider = Provider<EvidenceCaptureService>((ref) {
  return EvidenceCaptureService();
});

final evidenceApiServiceProvider = Provider<EvidenceApiService>((ref) {
  return EvidenceApiService(ref.watch(apiClientProvider));
});

final evidenceRepositoryProvider = Provider<EvidenceRepository>((ref) {
  return EvidenceRepositoryImpl(ref.watch(evidenceApiServiceProvider));
});
