import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vitago_app/app/theme/app_design_tokens.dart';
import 'package:vitago_app/core/formatters/app_date_format.dart';
import 'package:vitago_app/core/widgets/pagination_footer.dart';
import 'package:vitago_app/features/evidence/controllers/evidence_controller.dart';
import 'package:vitago_app/features/evidence/views/evidence_image_view.dart';

class RequestEvidenceSection extends ConsumerStatefulWidget {
  const RequestEvidenceSection({required this.requestId, super.key});

  final String requestId;

  @override
  ConsumerState<RequestEvidenceSection> createState() =>
      _RequestEvidenceSectionState();
}

class _RequestEvidenceSectionState
    extends ConsumerState<RequestEvidenceSection> {
  int _page = 1;

  @override
  Widget build(BuildContext context) {
    final query = (ownerId: widget.requestId, page: _page);
    final evidence = ref.watch(requestEvidenceControllerProvider(query));
    return evidence.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: LinearProgressIndicator(),
      ),
      error: (error, stackTrace) => Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: () =>
              ref.invalidate(requestEvidenceControllerProvider(query)),
          icon: const Icon(Icons.refresh),
          label: const Text('Reintentar evidencias'),
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
          children: [
            ...result.items.map(
              (item) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.image_outlined),
                title: Text(_typeLabel(item.type)),
                subtitle: Text(AppDateFormat.dateTime(item.capturedAt)),
                trailing: item.fileAvailable
                    ? const Icon(Icons.open_in_new)
                    : const Icon(Icons.hide_image_outlined),
                onTap: !item.fileAvailable
                    ? null
                    : () => Navigator.of(context).push<void>(
                        MaterialPageRoute<void>(
                          builder: (context) => EvidenceImageView(
                            ownerId: widget.requestId,
                            evidenceId: item.id,
                            isIncident: false,
                          ),
                        ),
                      ),
              ),
            ),
            PaginationFooter(
              page: _page,
              totalItems: result.count,
              hasPrevious: result.hasPrevious,
              hasNext: result.hasNext,
              onPrevious: () => setState(() => _page--),
              onNext: () => setState(() => _page++),
            ),
          ],
        );
      },
    );
  }
}

String _typeLabel(String? type) => switch (type) {
  'FOTO_RECOLECCION' => 'Foto de recolección',
  'FOTO_ENTREGA' => 'Foto de entrega',
  'FOTO_INCIDENCIA' => 'Foto de incidencia',
  _ => 'Evidencia fotográfica',
};
