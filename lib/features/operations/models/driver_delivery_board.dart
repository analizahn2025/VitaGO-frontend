import 'package:vitago_app/features/requests/models/request_models.dart';

class DriverDeliveryBoard {
  const DriverDeliveryBoard({required this.inProgress, required this.history});

  factory DriverDeliveryBoard.fromRequests(
    Iterable<ServiceRequestSummary> requests,
  ) {
    final sorted = requests.toList(growable: false)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return DriverDeliveryBoard(
      inProgress: sorted
          .where((request) => !request.isTerminal)
          .toList(growable: false),
      history: sorted
          .where((request) => request.isTerminal)
          .toList(growable: false),
    );
  }

  final List<ServiceRequestSummary> inProgress;
  final List<ServiceRequestSummary> history;

  bool get hasActiveAssignments => inProgress.isNotEmpty;
}
