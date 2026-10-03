import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vitago_app/core/widgets/async_state_view.dart';
import 'package:vitago_app/features/evidence/controllers/evidence_controller.dart';

class EvidenceImageView extends ConsumerWidget {
  const EvidenceImageView({
    required this.ownerId,
    required this.evidenceId,
    required this.isIncident,
    super.key,
  });

  final String ownerId;
  final String evidenceId;
  final bool isIncident;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = (ownerId: ownerId, evidenceId: evidenceId);
    final file = ref.watch(
      isIncident
          ? incidentEvidenceFileProvider(query)
          : requestEvidenceFileProvider(query),
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Evidencia')),
      backgroundColor: Colors.black,
      body: SafeArea(
        child: file.when(
          loading: () => const AppLoadingView(label: 'Cargando imagen…'),
          error: (error, stackTrace) => AppErrorView(
            error: error,
            onRetry: () => ref.invalidate(
              isIncident
                  ? incidentEvidenceFileProvider(query)
                  : requestEvidenceFileProvider(query),
            ),
          ),
          data: (value) => InteractiveViewer(
            minScale: 0.8,
            maxScale: 5,
            child: Center(
              child: Image.memory(
                Uint8List.fromList(value.bytes),
                fit: BoxFit.contain,
                semanticLabel: isIncident
                    ? 'Fotografía de la incidencia'
                    : 'Fotografía de la solicitud',
              ),
            ),
          ),
        ),
      ),
    );
  }
}
