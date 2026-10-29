import 'package:flutter/material.dart';
import 'package:vitago_app/features/requests/models/request_models.dart';
import 'package:vitago_app/features/requests/views/confirm_request_stage_view.dart';
import 'package:vitago_app/features/requests/views/transition_request_view.dart';

Future<ServiceRequestDetail?> presentDriverRequestStage(
  BuildContext context, {
  required ServiceRequestDetail request,
  required String targetStatus,
  required bool needsPhoto,
  bool useModal = true,
}) {
  final form = const {'PICKED_UP', 'DELIVERED'}.contains(targetStatus)
      ? ConfirmRequestStageView(request: request, targetStatus: targetStatus)
      : TransitionRequestView(
          request: request,
          allowedStatuses: [targetStatus],
          gpsRequired: true,
        );
  if (!useModal) {
    return Navigator.of(context)
        .push<ServiceRequestDetail>(MaterialPageRoute(builder: (_) => form));
  }
  return showModalBottomSheet<ServiceRequestDetail>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    clipBehavior: Clip.antiAlias,
    builder: (_) => FractionallySizedBox(heightFactor: 0.94, child: form),
  );
}
