import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vitago_app/core/widgets/async_state_view.dart';
import 'package:vitago_app/core/errors/app_failure.dart';
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
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: file.when(
          loading: () => const AppLoadingView(label: 'Cargando imagen…'),
          error: (error, stackTrace) {
            if (error is AppFailure && error.statusCode == 410) {
              return const AppEmptyView(
                icon: Icons.hide_image_outlined,
                title: 'Imagen eliminada por retención',
                message: 'El registro de evidencia y sus datos se conservan.',
              );
            }
            if (error is AppFailure && error.statusCode == 404) {
              return const AppEmptyView(
                icon: Icons.hide_image_outlined,
                title: 'Imagen no disponible',
                message: 'El registro de evidencia se conserva.',
              );
            }
            return AppErrorView(
              error: error,
              onRetry: () => ref.invalidate(
                isIncident
                    ? incidentEvidenceFileProvider(query)
                    : requestEvidenceFileProvider(query),
              ),
            );
          },
          data: (value) => ColoredBox(
            color: Colors.black,
            child: InteractiveViewer(
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
      ),
    );
  }
}
