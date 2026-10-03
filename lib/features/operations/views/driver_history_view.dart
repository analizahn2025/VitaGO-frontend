import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vitago_app/app/theme/app_design_tokens.dart';
import 'package:vitago_app/features/operations/controllers/driver_delivery_controller.dart';
import 'package:vitago_app/features/operations/widgets/driver_requests_section.dart';
import 'package:vitago_app/features/profile/models/user_profile.dart';
import 'package:vitago_app/features/shifts/views/shift_history_view.dart';

class DriverHistoryView extends ConsumerStatefulWidget {
  const DriverHistoryView({required this.profile, super.key});

  final UserProfile profile;

  @override
  ConsumerState<DriverHistoryView> createState() => _DriverHistoryViewState();
}

class _DriverHistoryViewState extends ConsumerState<DriverHistoryView> {
  bool _showShifts = false;

  @override
  Widget build(BuildContext context) {
    final board = ref.watch(driverDeliveryControllerProvider);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          child: SegmentedButton<bool>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(
                value: false,
                icon: Icon(Icons.inventory_2_outlined),
                label: Text('Servicios'),
              ),
              ButtonSegment(
                value: true,
                icon: Icon(Icons.schedule_outlined),
                label: Text('Jornadas'),
              ),
            ],
            selected: {_showShifts},
            onSelectionChanged: (selection) {
              setState(() => _showShifts = selection.first);
            },
          ),
        ),
        Expanded(
          child: _showShifts
              ? const ShiftHistoryView(embedded: true)
              : RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(driverDeliveryControllerProvider);
                    await ref.read(driverDeliveryControllerProvider.future);
                  },
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    children: [
                      DriverRequestsSection(
                        board: board,
                        showHistory: true,
                        title: 'Servicios finalizados',
                        onRetry: () =>
                            ref.invalidate(driverDeliveryControllerProvider),
                        onOpenRequest: _openRequest,
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  Future<void> _openRequest(String requestId) async {
    await context.pushNamed<void>(
      'request-detail',
      pathParameters: {'requestId': requestId},
    );
    ref.invalidate(driverDeliveryControllerProvider);
  }
}
