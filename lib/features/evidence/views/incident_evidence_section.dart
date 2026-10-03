import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vitago_app/app/theme/app_design_tokens.dart';
import 'package:vitago_app/core/formatters/app_date_format.dart';
import 'package:vitago_app/features/evidence/controllers/evidence_controller.dart';
import 'package:vitago_app/features/evidence/views/evidence_image_view.dart';

class IncidentEvidenceSection extends ConsumerWidget {
  const IncidentEvidenceSection({required this.incidentId, super.key});

  final String incidentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = (ownerId: incidentId, page: 1);
    final evidence = ref.watch(incidentEvidenceControllerProvider(query));
    return evidence.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: LinearProgressIndicator(),
      ),
      error: (error, stackTrace) => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () =>
                ref.invalidate(incidentEvidenceControllerProvider(query)),
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar evidencias'),
          ),
        ),
      ),
      data: (result) {
        if (result.items.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Text('No hay evidencias registradas.'),
          );
        }
        return Column(
          children: result.items
              .map(
                (item) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.image_outlined),
                  title: Text(item.notes ?? 'Evidencia fotográfica'),
                  subtitle: Text(AppDateFormat.dateTime(item.capturedAt)),
                  trailing: item.fileAvailable
                      ? const Icon(Icons.open_in_new)
                      : const Icon(Icons.hide_image_outlined),
                  onTap: !item.fileAvailable
                      ? null
                      : () => Navigator.of(context).push<void>(
                          MaterialPageRoute<void>(
                            builder: (context) => EvidenceImageView(
                              ownerId: incidentId,
                              evidenceId: item.id,
                              isIncident: true,
                            ),
                          ),
                        ),
                ),
              )
              .toList(growable: false),
        );
      },
    );
  }
}
