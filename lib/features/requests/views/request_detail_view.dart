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
import 'package:vitago_app/features/requests/controllers/requests_controller.dart';
import 'package:vitago_app/features/requests/models/request_models.dart';
import 'package:vitago_app/features/requests/views/assign_request_view.dart';
import 'package:vitago_app/features/requests/views/update_request_load_view.dart';
import 'package:vitago_app/features/requests/views/cancel_request_dialog.dart';
import 'package:vitago_app/features/requests/views/widgets/driver_request_actions.dart';
import 'package:vitago_app/features/shifts/controllers/shifts_controller.dart';
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
    final activeShift = profile.isDriver
        ? ref.watch(activeShiftControllerProvider)
        : null;
    final hasActiveShift = !profile.isDriver || activeShift?.value != null;
    final canViewEvidence = profile.can(AppPermissions.viewEvidence);
    final canCancel =
        profile.can(AppPermissions.cancelRequests) &&
        requestIsCancellable(request.status);
    final canAssign =
        request.status == 'PENDING' &&
        profile.can(AppPermissions.assignRequests);
    final canReassign =
        (request.status == 'ASSIGNED' || summary.pendingReassignment) &&
        profile.can(AppPermissions.reassignRequests);
    // Operational photos belong only to the server-selected automatic screen.
    final evidenceTypes = _availableEvidenceTypes(request.status)
        .where((type) => type == 'FOTO_INCIDENCIA')
        .toList(growable: false);
    final canAddEvidence =
        profile.isDriver &&
        profile.can(AppPermissions.createEvidence) &&
        evidenceTypes.isNotEmpty;

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
                    StatusBadge(
                      status: request.status,
                      label: summary.displayStatusLabel,
                    ),
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
                const SizedBox(height: AppSpacing.md),
                Text('Tubos: ${summary.tubeCount ?? 'No registrado'}'),
                Text('Frascos: ${summary.flaskCount ?? 'No registrado'}'),
                if (canUpdateRequestLoad(request, profile))
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Corregir carga'),
                      onPressed: () async {
                        final updated = await Navigator.of(context).push<bool>(
                          MaterialPageRoute(
                            builder: (_) => UpdateRequestLoadView(
                              request: request,
                              profile: profile,
                            ),
                          ),
                        );
                        if (updated == true) onChanged();
                      },
                    ),
                  ),
                if (summary.pendingReassignment) ...[
                  const SizedBox(height: AppSpacing.lg),
                  const _PendingReassignmentNotice(),
                ],
                if (summary.closedAt != null ||
                    summary.closureReason != null) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _ClosureNotice(summary: summary),
                ],
                if (profile.isDriver &&
                    !hasActiveShift &&
                    !request.isTerminal) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _StartShiftNotice(onStart: () => Navigator.of(context).pop()),
                ],
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
                    (profile.isDriver && !request.isTerminal) ||
                    canCancel) ...[
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    profile.isDriver ? 'Siguiente paso' : 'Acciones',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  if (canAssign ||
                      canReassign ||
                      (!profile.isDriver && canCancel))
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        if (canAssign || canReassign)
                          FilledButton.tonalIcon(
                            onPressed: () => _openAssignment(context),
                            icon: const Icon(Icons.assignment_ind_outlined),
                            label: Text(
                              summary.pendingReassignment
                                  ? 'Asignar reemplazo'
                                  : canAssign
                                  ? 'Asignar motorista'
                                  : 'Reasignar',
                            ),
                          ),
                        if (!profile.isDriver && canCancel)
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: colors.error,
                              side: BorderSide(color: colors.error),
                            ),
                            onPressed: () => _openCancellation(context, ref),
                            icon: const Icon(Icons.cancel_outlined),
                            label: const Text('Cancelar envío'),
                          ),
                      ],
                    ),
                  if (profile.isDriver) ...[
                    if (canAssign || canReassign)
                      const SizedBox(height: AppSpacing.sm),
                    DriverRequestActions(
                      request: request,
                      profile: profile,
                      onCompleted: (updated) async =>
                          _handleCompletedTransition(context, ref, updated),
                    ),
                  ],
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
                if (request.historicalArticles.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    'Artículos históricos',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ...request.historicalArticles.map(
                    (item) => _ArticleTile(item: item),
                  ),
                ],
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

  Future<void> _openAssignment(BuildContext context) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (context) => AssignRequestView(request: request),
      ),
    );
    if (changed == true) onChanged();
  }

  Future<void> _openCancellation(BuildContext context, WidgetRef ref) async {
    final updated = await showDialog<ServiceRequestDetail>(
      context: context,
      barrierDismissible: false,
      builder: (context) => CancelRequestDialog(request: request),
    );
    if (updated == null || !context.mounted) return;
    _handleCompletedTransition(context, ref, updated);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Envío cancelado correctamente.')),
      );
    }
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

class _PendingReassignmentNotice extends StatelessWidget {
  const _PendingReassignmentNotice();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.tertiaryContainer,
        borderRadius: BorderRadius.circular(AppRadii.control),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.person_search_outlined, color: colors.onTertiaryContainer),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Pendiente de reasignación. El estado del servicio se conserva hasta encontrar otro motorista.',
              style: TextStyle(
                color: colors.onTertiaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClosureNotice extends StatelessWidget {
  const _ClosureNotice({required this.summary});

  final ServiceRequestSummary summary;

  @override
  Widget build(BuildContext context) {
    final endOfDay = summary.closedAtEndOfDay;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        endOfDay ? Icons.nights_stay_outlined : Icons.event_available_outlined,
      ),
      title: Text(
        endOfDay ? 'Cierre automático de fin de día' : 'Servicio cerrado',
      ),
      subtitle: Text(
        summary.closedAt == null
            ? 'Motivo: ${summary.closureReason ?? 'No informado'}'
            : '${AppDateFormat.dateTime(summary.closedAt!)}${summary.closureReason == null ? '' : '\nMotivo: ${summary.closureReason}'}',
      ),
    );
  }
}

class _StartShiftNotice extends StatelessWidget {
  const _StartShiftNotice({required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(AppRadii.control),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Inicia tu jornada para continuar',
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(color: colors.onErrorContainer),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'El servicio no cambiará de estado hasta que tengas una jornada activa.',
            style: TextStyle(color: colors.onErrorContainer),
          ),
          const SizedBox(height: AppSpacing.sm),
          FilledButton.tonalIcon(
            onPressed: onStart,
            icon: const Icon(Icons.play_circle_outline),
            label: const Text('Ir a iniciar jornada'),
          ),
        ],
      ),
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
    final movements = request.specialMovements;
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
                  if (movement.closureReason case final reason?) ...[
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      'Cierre del último tramo: ${_movementClosureLabel(reason)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
                if (movements.length > 1) ...[
                  const SizedBox(height: AppSpacing.sm),
                  ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    childrenPadding: EdgeInsets.zero,
                    title: Text('${movements.length} tramos del recorrido'),
                    children: [
                      for (var index = 0; index < movements.length; index++)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          title: Text('Tramo ${movements.length - index}'),
                          subtitle: Text(
                            _movementDescription(movements[index]),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _movementDescription(SpecialRequestMovement movement) {
    final parts = <String>[
      movement.traveledKilometers == null
          ? 'Kilometraje pendiente'
          : '${movement.traveledKilometers} km',
      if (movement.closureReason != null)
        _movementClosureLabel(movement.closureReason!),
      '${movement.recordsConsidered} puntos válidos',
    ];
    return parts.join(' · ');
  }

  String _movementClosureLabel(String reason) => switch (reason.toUpperCase()) {
    'SUSPENSION' => 'Cambio de motorista',
    'FIN_DIA' => 'Fin de día',
    _ => reason.replaceAll('_', ' ').toLowerCase(),
  };
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
  'REASIGNACION_PENDIENTE' => 'Pendiente de reasignación',
  'CIERRE_AUTOMATICO' => 'Cierre automático de fin de día',
  'HACIA_RECOLECCION' => 'Motorista hacia recolección',
  'LLEGADA_RECOLECCION' => 'Llegada a recolección',
  _ => type.replaceAll('_', ' ').toLowerCase(),
};
