import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vitago_app/core/permissions/app_permissions.dart';
import 'package:vitago_app/core/widgets/edit_operational_count_view.dart';
import 'package:vitago_app/features/fleet/controllers/fleet_controller.dart';
import 'package:vitago_app/features/profile/models/user_profile.dart';
import 'package:vitago_app/features/requests/controllers/requests_controller.dart';
import 'package:vitago_app/features/requests/models/request_models.dart';
import 'package:vitago_app/features/routes/providers/routes_providers.dart';

bool canUpdateRequestTubeCount(
  ServiceRequestDetail request,
  UserProfile profile,
) =>
    profile.can(AppPermissions.assignRequests) &&
    !request.isTerminal &&
    (request.summary.tubeCount == null ||
        const {
          'PENDING',
          'ASSIGNED',
          'GOING_TO_PICKUP',
          'AT_PICKUP',
        }.contains(request.status));

class UpdateRequestTubeCountView extends ConsumerWidget {
  const UpdateRequestTubeCountView({
    required this.request,
    required this.profile,
    super.key,
  });
  final ServiceRequestDetail request;
  final UserProfile profile;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!canUpdateRequestTubeCount(request, profile)) {
      return const Scaffold(
        body: SafeArea(
          child: Center(
            child: Text('No puedes cambiar la cantidad de este envío.'),
          ),
        ),
      );
    }
    return EditOperationalCountView(
      title: request.summary.tubeCount == null
          ? 'Declarar tubos'
          : 'Corregir tubos',
      label: 'Cantidad de tubos',
      fieldName: 'cantidad_tubos',
      initialValue: request.summary.tubeCount,
      description:
          '${request.number}. Ingresa el conteo real; el servidor validará el estado y el cupo.',
      onSave: (count, reason) async {
        await ref
            .read(requestActionsControllerProvider)
            .updateTubeCount(request.id, count, reason);
        ref.invalidate(requestControllerProvider(request.id));
        ref.invalidate(requestsControllerProvider);
        ref.invalidate(requesterSummaryControllerProvider);
        ref.invalidate(ownDriverProfileControllerProvider);
        ref.invalidate(driversControllerProvider);
        ref.invalidate(availableDriversForRequestControllerProvider);
        ref.invalidate(myRouteProvider);
      },
    );
  }
}
