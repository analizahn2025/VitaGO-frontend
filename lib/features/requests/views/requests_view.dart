import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vitago_app/app/config/app_config.dart';
import 'package:vitago_app/app/theme/app_design_tokens.dart';
import 'package:vitago_app/core/models/paginated_result.dart';
import 'package:vitago_app/core/permissions/app_permissions.dart';
import 'package:vitago_app/core/widgets/adaptive_form_row.dart';
import 'package:vitago_app/core/widgets/async_state_view.dart';
import 'package:vitago_app/core/widgets/pagination_footer.dart';
import 'package:vitago_app/features/profile/models/user_profile.dart';
import 'package:vitago_app/features/requests/controllers/requests_controller.dart';
import 'package:vitago_app/features/requests/models/request_inputs.dart';
import 'package:vitago_app/features/requests/models/request_models.dart';
import 'package:vitago_app/features/requests/views/create_request_view.dart';
import 'package:vitago_app/features/requests/views/widgets/request_route_tile.dart';

class RequestsView extends ConsumerStatefulWidget {
  const RequestsView({required this.profile, super.key});

  final UserProfile profile;

  @override
  ConsumerState<RequestsView> createState() => _RequestsViewState();
}

class _RequestsViewState extends ConsumerState<RequestsView> {
  int _page = 1;
  String? _status;
  String? _priority;
  String? _modality;

  bool get _canView =>
      widget.profile.can(AppPermissions.viewRequests) ||
      widget.profile.can(AppPermissions.viewOwnRequests) ||
      widget.profile.can(AppPermissions.viewAssignedRequests);

  @override
  Widget build(BuildContext context) {
    if (!_canView) {
      return const AppEmptyView(
        icon: Icons.inventory_2_outlined,
        title: 'Sin acceso a solicitudes',
        message: 'Tu perfil no puede consultar servicios de traslado.',
      );
    }

    final query = RequestQuery(
      status: _status,
      priority: _priority,
      modality: _modality,
      page: _page,
    );
    final requests = ref.watch(requestsControllerProvider(query));
    return requests.when(
      loading: () => const AppLoadingView(label: 'Cargando solicitudes…'),
      error: (error, stackTrace) => AppErrorView(
        error: error,
        onRetry: () => ref.invalidate(requestsControllerProvider(query)),
      ),
      data: (result) => _buildResult(result, query),
    );
  }

  Widget _buildResult(
    PaginatedResult<ServiceRequestSummary> result,
    RequestQuery query,
  ) {
    final empty = result.items.isEmpty;
    final config = ref.watch(appConfigProvider);
    final canCreate =
        config.isCorporate && widget.profile.can(AppPermissions.createRequests);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(requestsControllerProvider(query));
        await ref.read(requestsControllerProvider(query).future);
      },
      child: ListView.separated(
        key: const PageStorageKey<String>('requests-scroll-view'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: AppSpacing.sm),
        itemCount: empty ? 2 : result.items.length + 2,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _RequestsHeader(
              status: _status,
              priority: _priority,
              modality: _modality,
              isCorporate: config.isCorporate,
              canCreate: canCreate,
              onStatusChanged: (value) => setState(() {
                _status = value;
                _page = 1;
              }),
              onPriorityChanged: (value) => setState(() {
                _priority = value;
                _page = 1;
              }),
              onModalityChanged: (value) => setState(() {
                _modality = value;
                _page = 1;
              }),
              onCreate: _openCreate,
            );
          }
          if (empty) return const _EmptyRequests();
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
          final request = result.items[index - 1];
          return RequestRouteTile(
            request: request,
            onTap: () => _openDetail(request.id),
          );
        },
      ),
    );
  }

  Future<void> _openCreate() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (context) => CreateRequestView(profile: widget.profile),
      ),
    );
    if (created == true) _refreshCurrentPage();
  }

  Future<void> _openDetail(String requestId) async {
    await context.pushNamed<bool>(
      'request-detail',
      pathParameters: {'requestId': requestId},
    );
    _refreshCurrentPage();
  }

  void _refreshCurrentPage() {
    ref.invalidate(
      requestsControllerProvider(
        RequestQuery(
          status: _status,
          priority: _priority,
          modality: _modality,
          page: _page,
        ),
      ),
    );
  }
}

class _RequestsHeader extends StatelessWidget {
  const _RequestsHeader({
    required this.status,
    required this.priority,
    required this.modality,
    required this.isCorporate,
    required this.canCreate,
    required this.onStatusChanged,
    required this.onPriorityChanged,
    required this.onModalityChanged,
    required this.onCreate,
  });

  final String? status;
  final String? priority;
  final String? modality;
  final bool isCorporate;
  final bool canCreate;
  final ValueChanged<String?> onStatusChanged;
  final ValueChanged<String?> onPriorityChanged;
  final ValueChanged<String?> onModalityChanged;
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
            'Solicitudes',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Traslados visibles dentro de tu responsabilidad.',
            style: TextStyle(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.md),
          AdaptiveFormRow(
            children: [
              DropdownButtonFormField<String?>(
                initialValue: status,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Estado'),
                items: const [
                  DropdownMenuItem(value: null, child: Text('Todos')),
                  DropdownMenuItem(value: 'PENDING', child: Text('Pendiente')),
                  DropdownMenuItem(value: 'ASSIGNED', child: Text('Asignada')),
                  DropdownMenuItem(
                    value: 'GOING_TO_PICKUP',
                    child: Text('Hacia recolección'),
                  ),
                  DropdownMenuItem(
                    value: 'AT_PICKUP',
                    child: Text('En recolección'),
                  ),
                  DropdownMenuItem(
                    value: 'PICKED_UP',
                    child: Text('Recolectada'),
                  ),
                  DropdownMenuItem(
                    value: 'IN_TRANSIT',
                    child: Text('En tránsito'),
                  ),
                  DropdownMenuItem(
                    value: 'AT_DESTINATION',
                    child: Text('En destino'),
                  ),
                  DropdownMenuItem(
                    value: 'DELIVERED',
                    child: Text('Entregada'),
                  ),
                  DropdownMenuItem(
                    value: 'PICKUP_FAILED',
                    child: Text('Recolección fallida'),
                  ),
                  DropdownMenuItem(
                    value: 'DELIVERY_FAILED',
                    child: Text('Entrega fallida'),
                  ),
                  DropdownMenuItem(
                    value: 'CANCELLED',
                    child: Text('Cancelada'),
                  ),
                ],
                onChanged: onStatusChanged,
              ),
              DropdownButtonFormField<String?>(
                initialValue: priority,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Prioridad'),
                items: const [
                  DropdownMenuItem(value: null, child: Text('Todas')),
                  DropdownMenuItem(value: 'NORMAL', child: Text('Normal')),
                  DropdownMenuItem(
                    value: 'PRIORITY',
                    child: Text('Prioritaria'),
                  ),
                ],
                onChanged: onPriorityChanged,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          DropdownButtonFormField<String?>(
            initialValue: modality,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Modalidad'),
            items: [
              const DropdownMenuItem(value: null, child: Text('Todas')),
              if (isCorporate) ...const [
                DropdownMenuItem(
                  value: RequestModalities.betweenBranches,
                  child: Text('Entre sucursales'),
                ),
                DropdownMenuItem(
                  value: RequestModalities.transportCompany,
                  child: Text('Empresa de transporte'),
                ),
                DropdownMenuItem(
                  value: RequestModalities.special,
                  child: Text('Envío especial'),
                ),
              ] else
                const DropdownMenuItem(
                  value: RequestModalities.open,
                  child: Text('Abierto'),
                ),
            ],
            onChanged: onModalityChanged,
          ),
          if (canCreate) ...[
            const SizedBox(height: AppSpacing.md),
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add),
              label: const Text('Crear solicitud'),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyRequests extends StatelessWidget {
  const _EmptyRequests();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.xxl,
      ),
      child: Column(
        children: [
          Icon(Icons.inventory_2_outlined, size: 56),
          SizedBox(height: AppSpacing.md),
          Text('No hay solicitudes para estos filtros.'),
        ],
      ),
    );
  }
}
