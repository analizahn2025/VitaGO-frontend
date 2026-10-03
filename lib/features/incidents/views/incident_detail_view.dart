import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vitago_app/app/theme/app_design_tokens.dart';
import 'package:vitago_app/core/formatters/app_date_format.dart';
import 'package:vitago_app/core/widgets/async_state_view.dart';
import 'package:vitago_app/core/widgets/status_badge.dart';
import 'package:vitago_app/features/evidence/controllers/evidence_controller.dart';
import 'package:vitago_app/features/evidence/views/add_incident_evidence_view.dart';
import 'package:vitago_app/features/evidence/views/incident_evidence_section.dart';
import 'package:vitago_app/features/incidents/controllers/incidents_controller.dart';
import 'package:vitago_app/features/incidents/models/incident.dart';
import 'package:vitago_app/features/incidents/views/review_incident_view.dart';

class IncidentDetailView extends ConsumerWidget {
  const IncidentDetailView({
    required this.incidentId,
    required this.canReview,
    required this.canAddEvidence,
    super.key,
  });

  final String incidentId;
  final bool canReview;
  final bool canAddEvidence;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incident = ref.watch(incidentControllerProvider(incidentId));
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle de incidencia')),
      body: SafeArea(
        child: incident.when(
          loading: () => const AppLoadingView(label: 'Cargando incidencia…'),
          error: (error, stackTrace) => AppErrorView(
            error: error,
            onRetry: () =>
                ref.invalidate(incidentControllerProvider(incidentId)),
          ),
          data: (value) => _IncidentContent(
            incident: value,
            canReview: canReview,
            canAddEvidence: canAddEvidence,
            onReviewed: () {
              ref.invalidate(incidentControllerProvider(incidentId));
              Navigator.of(context).pop(true);
            },
          ),
        ),
      ),
    );
  }
}

class _IncidentContent extends StatelessWidget {
  const _IncidentContent({
    required this.incident,
    required this.canReview,
    required this.canAddEvidence,
    required this.onReviewed,
  });

  final Incident incident;
  final bool canReview;
  final bool canAddEvidence;
  final VoidCallback onReviewed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                'Incidencia operativa',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            StatusBadge(status: incident.status),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppRadii.control),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Text(
              incident.description,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _DetailLine(
          label: 'Reportada',
          value: AppDateFormat.dateTime(incident.reportedAt),
        ),
        if (incident.requestId case final requestId?)
          _DetailLine(label: 'Solicitud', value: requestId),
        if (incident.latitude case final latitude?)
          _DetailLine(
            label: 'Ubicación',
            value: '$latitude, ${incident.longitude ?? '—'}',
          ),
        if (incident.reviewedAt case final reviewedAt?)
          _DetailLine(
            label: 'Revisada',
            value: AppDateFormat.dateTime(reviewedAt),
          ),
        if (incident.closedAt case final closedAt?)
          _DetailLine(
            label: 'Cerrada',
            value: AppDateFormat.dateTime(closedAt),
          ),
        if (canReview && !incident.isClosed) ...[
          const SizedBox(height: AppSpacing.lg),
          FilledButton.tonalIcon(
            onPressed: () => _openReview(context),
            icon: const Icon(Icons.fact_check_outlined),
            label: const Text('Revisar incidencia'),
          ),
        ],
        if (canAddEvidence && !incident.isClosed) ...[
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            onPressed: () => _openEvidence(context),
            icon: const Icon(Icons.add_a_photo_outlined),
            label: const Text('Agregar evidencia'),
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
        Text('Evidencias', style: Theme.of(context).textTheme.titleLarge),
        IncidentEvidenceSection(incidentId: incident.id),
        const SizedBox(height: AppSpacing.xl),
        Text('Historial', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSpacing.md),
        if (incident.events.isEmpty)
          const Text('Aún no hay eventos adicionales.')
        else
          ...incident.events.map((event) => _EventTile(event: event)),
      ],
    );
  }

  Future<void> _openReview(BuildContext context) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (context) => ReviewIncidentView(incident: incident),
      ),
    );
    if (changed == true) onReviewed();
  }

  Future<void> _openEvidence(BuildContext context) async {
    final added = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (context) => AddIncidentEvidenceView(incidentId: incident.id),
      ),
    );
    if (added == true && context.mounted) {
      final container = ProviderScope.containerOf(context);
      container.invalidate(
        incidentEvidenceControllerProvider((ownerId: incident.id, page: 1)),
      );
    }
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: AppSpacing.xxs),
          SelectableText(value),
        ],
      ),
    );
  }
}

class _EventTile extends StatelessWidget {
  const _EventTile({required this.event});

  final IncidentEvent event;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.only(left: AppSpacing.md),
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: colors.primary, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            event.type.replaceAll('_', ' '),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (event.newStatus case final status?) Text(status),
          if (event.notes case final notes?) Text(notes),
          if (event.createdAt case final createdAt?)
            Text(
              AppDateFormat.dateTime(createdAt),
              style: Theme.of(context).textTheme.bodySmall,
            ),
        ],
      ),
    );
  }
}
