import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vitago_app/app/theme/app_design_tokens.dart';
import 'package:vitago_app/core/formatters/app_date_format.dart';
import 'package:vitago_app/core/widgets/async_state_view.dart';
import 'package:vitago_app/core/widgets/pagination_footer.dart';
import 'package:vitago_app/core/widgets/status_badge.dart';
import 'package:vitago_app/features/shifts/controllers/shifts_controller.dart';
import 'package:vitago_app/features/shifts/models/driver_shift.dart';
import 'package:vitago_app/features/shifts/views/shift_detail_view.dart';

class ShiftHistoryView extends ConsumerStatefulWidget {
  const ShiftHistoryView({this.embedded = false, super.key});

  final bool embedded;

  @override
  ConsumerState<ShiftHistoryView> createState() => _ShiftHistoryViewState();
}

class _ShiftHistoryViewState extends ConsumerState<ShiftHistoryView> {
  int _page = 1;
  String? _status;

  @override
  Widget build(BuildContext context) {
    final query = ShiftQuery(status: _status, page: _page);
    final shifts = ref.watch(shiftsControllerProvider(query));
    return Scaffold(
      appBar: widget.embedded
          ? null
          : AppBar(title: const Text('Historial de jornadas')),
      body: SafeArea(
        child: shifts.when(
          loading: () => const AppLoadingView(label: 'Cargando jornadas…'),
          error: (error, stackTrace) => AppErrorView(
            error: error,
            onRetry: () => ref.invalidate(shiftsControllerProvider(query)),
          ),
          data: (result) => RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(shiftsControllerProvider(query));
              await ref.read(shiftsControllerProvider(query).future);
            },
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: result.items.length + 2,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: DropdownButtonFormField<String?>(
                      initialValue: _status,
                      decoration: const InputDecoration(labelText: 'Estado'),
                      items: const [
                        DropdownMenuItem(value: null, child: Text('Todas')),
                        DropdownMenuItem(
                          value: 'ACTIVA',
                          child: Text('Activas'),
                        ),
                        DropdownMenuItem(
                          value: 'FINALIZADA',
                          child: Text('Finalizadas'),
                        ),
                      ],
                      onChanged: (value) => setState(() {
                        _status = value;
                        _page = 1;
                      }),
                    ),
                  );
                }
                if (index == result.items.length + 1) {
                  if (result.items.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(AppSpacing.xxl),
                      child: Center(
                        child: Text('No hay jornadas registradas.'),
                      ),
                    );
                  }
                  return PaginationFooter(
                    page: _page,
                    totalItems: result.count,
                    hasPrevious: result.hasPrevious,
                    hasNext: result.hasNext,
                    onPrevious: () => setState(() => _page--),
                    onNext: () => setState(() => _page++),
                  );
                }
                final shift = result.items[index - 1];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.xs,
                  ),
                  leading: const Icon(Icons.schedule_outlined),
                  title: Text(AppDateFormat.dateTime(shift.startedAt)),
                  subtitle: Text('${shift.completedServices} servicios'),
                  trailing: StatusBadge(status: shift.status),
                  onTap: () => Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      builder: (context) => ShiftDetailView(shift: shift),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
