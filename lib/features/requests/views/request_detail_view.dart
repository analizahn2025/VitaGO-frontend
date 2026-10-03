import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vitago_app/app/theme/app_design_tokens.dart';
import 'package:vitago_app/core/formatters/app_date_format.dart';
import 'package:vitago_app/core/permissions/app_permissions.dart';
import 'package:vitago_app/core/widgets/async_state_view.dart';
import 'package:vitago_app/core/widgets/status_badge.dart';
import 'package:vitago_app/features/evidence/controllers/evidence_controller.dart';
import 'package:vitago_app/features/evidence/views/add_request_evidence_view.dart';
import 'package:vitago_app/features/evidence/views/request_evidence_section.dart';
import 'package:vitago_app/features/profile/models/user_profile.dart';
import 'package:vitago_app/features/requests/controllers/request_stage_controller.dart';
import 'package:vitago_app/features/requests/controllers/requests_controller.dart';
import 'package:vitago_app/features/requests/models/request_models.dart';
import 'package:vitago_app/features/requests/views/assign_request_view.dart';
import 'package:vitago_app/features/requests/views/confirm_request_stage_view.dart';
import 'package:vitago_app/features/requests/views/transition_request_view.dart';
import 'package:vitago_app/features/tracking/views/request_tracking_section.dart';
import 'package:vitago_app/features/tracking/widgets/required_gps_body.dart';

class RequestDetailView extends ConsumerWidget {
  const RequestDetailView({
    required this.requestId,
    required this.profile,
    super.key,
  });

  final String requestId;
  final UserProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final request = ref.watch(requestControllerProvider(requestId));
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle de solicitud')),
      body: SafeArea(
        child: RequiredGpsBody(
          enabled: profile.isDriver,
          child: request.when(
            loading: () => const AppLoadingView(label: 'Cargando solicitud…'),
            error: (error, stackTrace) => AppErrorView(
              error: error,
              onRetry: () =>
                  ref.invalidate(requestControllerProvider(requestId)),
            ),
            data: (value) => _RequestDetailContent(
              request: value,
              profile: profile,
              onChanged: () =>
                  ref.invalidate(requestControllerProvider(requestId)),
            ),
          ),
        ),
      ),
    );
  }
}

class _RequestDetailContent extends ConsumerWidget {
  const _RequestDetailContent({
    required this.request,
    required this.profile,
    required this.onChanged,
  });

  final ServiceRequestDetail request;
  final UserProfile profile;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = request.summary;
    final colors = Theme.of(context).colorScheme;
    final canViewEvidence = profile.can(AppPermissions.viewEvidence);
    final evidenceAsync = canViewEvidence
        ? ref.watch(
            requestEvidenceControllerProvider((ownerId: request.id, page: 1)),
          )
        : null;
    final evidenceTypesRecorded =
        evidenceAsync?.value?.items
            .map((item) => item.type)
            .whereType<String>()
            .map((type) => type.toUpperCase())
            .toSet() ??
        const <String>{};
    final evidenceReady = evidenceAsync == null || evidenceAsync.hasValue;
    final allowedTransitions = _allowedTransitions(
      evidenceReady: evidenceReady,
    );
    final canAssign =
        request.status == 'PENDING' &&
        profile.can(AppPermissions.assignRequests);
    final canReassign =
        request.status == 'ASSIGNED' &&
        profile.can(AppPermissions.reassignRequests);
    final evidenceTypes = _availableEvidenceTypes(request.status);
    final canAddEvidence =
        profile.isDriver &&
        profile.can(AppPermissions.createEvidence) &&
        evidenceTypes.isNotEmpty;
    final primaryStatus = profile.isDriver
        ? requestNextOperationalStatus(request.status)
        : null;
    final primaryTransition =
        primaryStatus != null && allowedTransitions.contains(primaryStatus)
        ? primaryStatus
        : null;
    final exceptionTransitions = profile.isDriver
        ? allowedTransitions
              .where((status) => status != primaryTransition)
              .toList(growable: false)
        : const <String>[];

    return RefreshIndicator(
      onRefresh: () async => onChanged(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
        children: [
          Container(
            color: colors.primary,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.xl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        request.number,
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(color: colors.onPrimary),
                      ),
                    ),
                    StatusBadge(status: request.status),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  summary.serviceType.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colors.onPrimary.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  requestModalityLabel(summary.modality),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.onPrimary.withValues(alpha: 0.82),
                  ),
                ),
                if (summary.isPriority) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xxs,
                    ),
                    decoration: BoxDecoration(
                      color: colors.errorContainer,
                      borderRadius: BorderRadius.circular(AppRadii.small),
                    ),
                    child: Text(
                      'Servicio prioritario',
                      style: TextStyle(
                        color: colors.onErrorContainer,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _RouteOverview(
                  origin: summary.origin,
                  destination: summary.destination,
                  specialDestination: summary.specialDestination,
                ),
                if (summary.isPriority &&
                    const {
                      'PICKED_UP',
                      'IN_TRANSIT',
                      'AT_DESTINATION',
                    }.contains(request.status)) ...[
                  const SizedBox(height: AppSpacing.lg),
                  const _PriorityDirectNotice(),
                ],
                if (request.isSpecial) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _SpecialMovementSection(request: request),
                ],
                if (request.notes case final notes?) ...[
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Indicaciones',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(notes),
                ],
                if (canAssign ||
                    canReassign ||
                    primaryTransition != null ||
                    exceptionTransitions.isNotEmpty ||
                    (!profile.isDriver && allowedTransitions.isNotEmpty)) ...[
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    profile.isDriver ? 'Siguiente paso' : 'Acciones',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      if (canAssign || canReassign)
                        FilledButton.tonalIcon(
                          onPressed: () => _openAssignment(context),
                          icon: const Icon(Icons.assignment_ind_outlined),
                          label: Text(
                            canAssign ? 'Asignar motorista' : 'Reasignar',
                          ),
                        ),
                      if (primaryTransition case final targetStatus?)
                        FilledButton.icon(
                          onPressed: () => _openPrimaryTransition(
                            context,
                            ref,
                            targetStatus,
                            evidenceTypesRecorded,
                          ),
                          icon: const Icon(Icons.arrow_forward),
                          label: Text(
                            requestTransitionActionLabel(targetStatus),
                          ),
                        ),
                      if (exceptionTransitions.isNotEmpty)
                        OutlinedButton.icon(
                          onPressed: () => _openTransition(
                            context,
                            ref,
                            exceptionTransitions,
                          ),
                          icon: const Icon(Icons.report_problem_outlined),
                          label: Text(
                            exceptionTransitions.length == 1
                                ? requestTransitionActionLabel(
                                    exceptionTransitions.single,
                                  )
                                : 'Reportar problema',
                          ),
                        ),
                      if (!profile.isDriver && allowedTransitions.isNotEmpty)
                        FilledButton.icon(
                          onPressed: () =>
                              _openTransition(context, ref, allowedTransitions),
                          icon: const Icon(Icons.update),
                          label: const Text('Actualizar estado'),
                        ),
                    ],
                  ),
                ],
                if (profile.can(AppPermissions.viewRequestTracking)) ...[
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    'Seguimiento',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  RequestTrackingSection(requestId: request.id),
                ],
                const SizedBox(height: AppSpacing.xl),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Evidencias',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    if (canAddEvidence)
                      TextButton.icon(
                        onPressed: () =>
                            _openEvidence(context, ref, evidenceTypes),
                        icon: const Icon(Icons.add_a_photo_outlined),
                        label: const Text('Agregar'),
                      ),
                  ],
                ),
                if (canViewEvidence)
                  RequestEvidenceSection(requestId: request.id)
                else
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                    child: Text('Tu perfil no puede consultar evidencias.'),
                  ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'Artículos',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.sm),
                ...request.items.map((item) => _ArticleTile(item: item)),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'Historial',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.md),
                ...request.events.map((event) => _EventEntry(event: event)),
                if (request.assignments.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xl),
                  ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    title: const Text('Historial de asignaciones'),
                    children: request.assignments
                        .map(
                          (assignment) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.badge_outlined),
                            title: Text(
                              assignment.status == 'ACTIVA'
                                  ? 'Asignación activa'
                                  : assignment.status.toLowerCase(),
                            ),
                            subtitle: Text(
                              '${AppDateFormat.dateTime(assignment.assignedAt)}${assignment.reason == null ? '' : '\n${assignment.reason}'}',
                            ),
                          ),
                        )
                        .toList(growable: false),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<String> _allowedTransitions({required bool evidenceReady}) {
    final raw = requestTransitionMatrix[request.status] ?? const <String>[];
    return raw
        .where((target) {
          if (target == 'CANCELLED') {
            return profile.can(AppPermissions.cancelRequests);
          }
          if (!profile.isDriver ||
              !profile.can(AppPermissions.updateRequestStatus)) {
            return false;
          }
          if (!evidenceReady &&
              (target == 'PICKED_UP' || target == 'DELIVERED')) {
            return false;
          }
          return true;
        })
        .toList(growable: false);
  }

  Future<void> _openAssignment(BuildContext context) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (context) => AssignRequestView(request: request),
      ),
    );
    if (changed == true) onChanged();
  }

  Future<void> _openTransition(
    BuildContext context,
    WidgetRef ref,
    List<String> allowed,
  ) async {
    final updated = await Navigator.of(context).push<ServiceRequestDetail>(
      MaterialPageRoute<ServiceRequestDetail>(
        builder: (context) => TransitionRequestView(
          request: request,
          allowedStatuses: allowed,
          gpsRequired: profile.isDriver,
        ),
      ),
    );
    if (updated == null || !context.mounted) return;
    _handleCompletedTransition(context, ref, updated);
  }

  Future<void> _openPrimaryTransition(
    BuildContext context,
    WidgetRef ref,
    String targetStatus,
    Set<String> evidenceTypesRecorded,
  ) async {
    final requiredType = requestRequiredEvidenceType(targetStatus);
    final ServiceRequestDetail? updated;
    if (requiredType != null && !evidenceTypesRecorded.contains(requiredType)) {
      updated = await Navigator.of(context).push<ServiceRequestDetail>(
        MaterialPageRoute<ServiceRequestDetail>(
          builder: (context) => ConfirmRequestStageView(
            request: request,
            targetStatus: targetStatus,
          ),
        ),
      );
    } else {
      updated = await Navigator.of(context).push<ServiceRequestDetail>(
        MaterialPageRoute<ServiceRequestDetail>(
          builder: (context) => TransitionRequestView(
            request: request,
            allowedStatuses: [targetStatus],
            gpsRequired: profile.isDriver,
          ),
        ),
      );
    }
    if (updated == null || !context.mounted) return;
    _handleCompletedTransition(context, ref, updated);
  }

  void _handleCompletedTransition(
    BuildContext context,
    WidgetRef ref,
    ServiceRequestDetail updated,
  ) {
    ref.invalidate(
      requestEvidenceControllerProvider((ownerId: request.id, page: 1)),
    );
    ref.invalidate(requestControllerProvider(request.id));
    if (updated.status.toUpperCase() == 'DELIVERED') {
      if (context.mounted) Navigator.of(context).pop(true);
      return;
    }
    onChanged();
  }

  Future<void> _openEvidence(
    BuildContext context,
    WidgetRef ref,
    List<String> types,
  ) async {
    final added = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (context) => AddRequestEvidenceView(
          requestId: request.id,
          allowedTypes: types,
          gpsRequired: profile.isDriver,
        ),
      ),
    );
    if (added == true) {
      ref.invalidate(
        requestEvidenceControllerProvider((ownerId: request.id, page: 1)),
      );
    }
  }
}

List<String> _availableEvidenceTypes(String status) {
  if (requestTerminalStates.contains(status.toUpperCase())) return const [];
  return switch (status) {
    'ASSIGNED' ||
    'GOING_TO_PICKUP' ||
    'AT_PICKUP' ||
    'PICKED_UP' ||
    'IN_TRANSIT' ||
    'AT_DESTINATION' => const ['FOTO_INCIDENCIA'],
    _ => const [],
  };
}

class _RouteOverview extends StatelessWidget {
  const _RouteOverview({
    required this.origin,
    required this.destination,
    required this.specialDestination,
  });

  final RequestPoint origin;
  final RequestPoint? destination;
  final String? specialDestination;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 24,
          height: 126,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 2,
                color: colors.primary.withValues(alpha: 0.35),
              ),
              Align(
                alignment: Alignment.topCenter,
                child: Icon(Icons.trip_origin, color: colors.primary, size: 18),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Icon(Icons.location_on, color: colors.primary, size: 24),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PlaceText(label: 'Origen', point: origin),
              const SizedBox(height: AppSpacing.lg),
              if (destination case final destination?)
                _PlaceText(label: 'Destino', point: destination)
              else
                _SpecialDestinationText(value: specialDestination),
            ],
          ),
        ),
      ],
    );
  }
}

class _SpecialDestinationText extends StatelessWidget {
  const _SpecialDestinationText({required this.value});

  final String? value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Destino especial', style: Theme.of(context).textTheme.labelLarge),
        Text(
          value ?? 'Destino no informado',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const Text('La distancia se calcula con el recorrido real.'),
      ],
    );
  }
}

class _SpecialMovementSection extends StatelessWidget {
  const _SpecialMovementSection({required this.request});

  final ServiceRequestDetail request;

  @override
  Widget build(BuildContext context) {
    final summary = request.summary;
    final movement = request.specialMovement;
    final kilometers =
        summary.specialKilometers ?? movement?.traveledKilometers;
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadii.control),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.speed_outlined, color: colors.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recorrido especial',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  kilometers == null
                      ? 'Kilometraje en cálculo durante la operación.'
                      : '$kilometers km recorridos',
                ),
                if (movement != null) ...[
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    '${movement.recordsConsidered} puntos considerados'
                    '${movement.recordsDiscarded == 0 ? '' : ' · ${movement.recordsDiscarded} descartados'}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PriorityDirectNotice extends StatelessWidget {
  const _PriorityDirectNotice();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(AppRadii.control),
        border: Border.all(color: colors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.priority_high, color: colors.onErrorContainer),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Servicio prioritario recolectado. Continúa directamente al destino.',
              style: TextStyle(
                color: colors.onErrorContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaceText extends StatelessWidget {
  const _PlaceText({required this.label, required this.point});

  final String label;
  final RequestPoint point;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        Text(point.name, style: Theme.of(context).textTheme.titleMedium),
        Text(point.address),
      ],
    );
  }
}

class _ArticleTile extends StatelessWidget {
  const _ArticleTile({required this.item});

  final RequestArticle item;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.medical_services_outlined),
      title: Text(item.itemType),
      subtitle: Text(
        [
          if (item.description != null) item.description!,
          if (item.transportCondition != null) item.transportCondition!,
        ].join(' · '),
      ),
      trailing: Text(
        item.quantity,
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );
  }
}

class _EventEntry extends StatelessWidget {
  const _EventEntry({required this.event});

  final RequestEvent event;

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
            _eventLabel(event.type),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Text(
            AppDateFormat.dateTime(event.createdAt),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

String _eventLabel(String type) => switch (type) {
  'CREADA' => 'Solicitud creada',
  'ASIGNADA' => 'Motorista asignado',
  'REASIGNADA' => 'Motorista reasignado',
  'HACIA_RECOLECCION' => 'Motorista hacia recolección',
  'LLEGADA_RECOLECCION' => 'Llegada a recolección',
  _ => type.replaceAll('_', ' ').toLowerCase(),
};
