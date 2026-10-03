import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vitago_app/app/theme/app_design_tokens.dart';
import 'package:vitago_app/core/formatters/app_date_format.dart';
import 'package:vitago_app/core/models/paginated_result.dart';
import 'package:vitago_app/core/permissions/app_permissions.dart';
import 'package:vitago_app/core/widgets/async_state_view.dart';
import 'package:vitago_app/core/widgets/pagination_footer.dart';
import 'package:vitago_app/core/widgets/status_badge.dart';
import 'package:vitago_app/features/incidents/controllers/incidents_controller.dart';
import 'package:vitago_app/features/incidents/models/incident.dart';
import 'package:vitago_app/features/incidents/views/create_incident_view.dart';
import 'package:vitago_app/features/incidents/views/incident_detail_view.dart';
import 'package:vitago_app/features/profile/models/user_profile.dart';

class IncidentsView extends ConsumerStatefulWidget {
  const IncidentsView({required this.profile, this.shiftId, super.key});

  final UserProfile profile;
  final String? shiftId;

  @override
  ConsumerState<IncidentsView> createState() => _IncidentsViewState();
}

class _IncidentsViewState extends ConsumerState<IncidentsView> {
  int _page = 1;
  String? _status;

  @override
  Widget build(BuildContext context) {
    final canCreate =
        widget.profile.isDriver &&
        widget.profile.can(AppPermissions.createIncidents);
    final canReview = widget.profile.can(AppPermissions.reviewIncidents);
    if (!canCreate && !canReview) {
      return const AppEmptyView(
        icon: Icons.report_outlined,
        title: 'Sin acceso a incidencias',
        message: 'Tu perfil no puede consultar ni reportar incidencias.',
      );
    }

    final query = IncidentQuery(
      status: _status,
      shiftId: widget.shiftId,
      page: _page,
    );
    final incidents = ref.watch(incidentsControllerProvider(query));
    return incidents.when(
      loading: () => const AppLoadingView(label: 'Cargando incidencias…'),
      error: (error, stackTrace) => AppErrorView(
        error: error,
        onRetry: () => ref.invalidate(incidentsControllerProvider(query)),
      ),
      data: (result) => _buildResult(
        result: result,
        query: query,
        canCreate: canCreate,
        canReview: canReview,
      ),
    );
  }

  Widget _buildResult({
    required PaginatedResult<Incident> result,
    required IncidentQuery query,
    required bool canCreate,
    required bool canReview,
  }) {
    final empty = result.items.isEmpty;
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(incidentsControllerProvider(query));
        await ref.read(incidentsControllerProvider(query).future);
      },
      child: ListView.separated(
        key: const PageStorageKey<String>('incidents-scroll-view'),
        padding: const EdgeInsets.only(top: AppSpacing.sm),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: empty ? 2 : result.items.length + 2,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _IncidentsHeader(
              selectedStatus: _status,
              canCreate: canCreate,
              onStatusChanged: (value) => setState(() {
                _status = value;
                _page = 1;
              }),
              onCreate: _openCreate,
            );
          }
          if (empty) {
            return const _EmptyIncidents();
          }
          if (index == result.items.length + 1) {
            return PaginationFooter(
              page: _page,
              totalItems: result.count,
              hasPrevious: result.hasPrevious,
              hasNext: result.hasNext,
              onPrevious: () => setState(() => _page--),
              onNext: () => setState(() => _page++),
            );
          }

          final incident = result.items[index - 1];
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.xs,
            ),
            leading: const Icon(Icons.report_problem_outlined),
            title: Text(
              incident.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(AppDateFormat.dateTime(incident.reportedAt)),
            trailing: StatusBadge(status: incident.status),
            onTap: () => _openDetail(incident.id, canReview),
          );
        },
      ),
    );
  }

  Future<void> _openCreate() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (context) => const CreateIncidentView()),
    );
    if (created == true) {
      ref.invalidate(
        incidentsControllerProvider(
          IncidentQuery(status: _status, shiftId: widget.shiftId, page: _page),
        ),
      );
    }
  }

  Future<void> _openDetail(String incidentId, bool canReview) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (context) => IncidentDetailView(
          incidentId: incidentId,
          canReview: canReview,
          canAddEvidence:
              widget.profile.isDriver &&
              widget.profile.can(AppPermissions.createEvidence),
        ),
      ),
    );
    if (changed == true) {
      ref.invalidate(
        incidentsControllerProvider(
          IncidentQuery(status: _status, shiftId: widget.shiftId, page: _page),
        ),
      );
    }
  }
}

class _IncidentsHeader extends StatelessWidget {
  const _IncidentsHeader({
    required this.selectedStatus,
    required this.canCreate,
    required this.onStatusChanged,
    required this.onCreate,
  });

  final String? selectedStatus;
  final bool canCreate;
  final ValueChanged<String?> onStatusChanged;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Incidencias',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Situaciones reportadas durante la operación.',
            style: TextStyle(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<String?>(
            initialValue: selectedStatus,
            decoration: const InputDecoration(labelText: 'Estado'),
            items: const [
              DropdownMenuItem(value: null, child: Text('Todos')),
              DropdownMenuItem(value: 'ABIERTA', child: Text('Abiertas')),
              DropdownMenuItem(
                value: 'EN_REVISION',
                child: Text('En revisión'),
              ),
              DropdownMenuItem(value: 'CERRADA', child: Text('Cerradas')),
            ],
            onChanged: onStatusChanged,
          ),
          if (canCreate) ...[
            const SizedBox(height: AppSpacing.md),
            FilledButton.tonalIcon(
              onPressed: onCreate,
              icon: const Icon(Icons.add_alert_outlined),
              label: const Text('Reportar incidencia'),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyIncidents extends StatelessWidget {
  const _EmptyIncidents();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        children: [
          Icon(Icons.task_alt, size: 52),
          SizedBox(height: AppSpacing.md),
          Text('No hay incidencias para este filtro.'),
        ],
      ),
    );
  }
}
