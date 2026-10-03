import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vitago_app/features/operations/models/driver_delivery_board.dart';
import 'package:vitago_app/features/requests/models/request_inputs.dart';
import 'package:vitago_app/features/requests/models/request_models.dart';
import 'package:vitago_app/features/requests/providers/requests_providers.dart';

final driverDeliveryControllerProvider =
    FutureProvider.autoDispose<DriverDeliveryBoard>((ref) async {
      final repository = ref.watch(requestsRepositoryProvider);
      final requests = <ServiceRequestSummary>[];
      var page = 1;

      while (true) {
        final result = await repository.getRequests(
          RequestQuery(page: page, pageSize: 100),
        );
        requests.addAll(result.items);
        if (!result.hasNext || result.items.isEmpty) break;
        page++;
      }

      return DriverDeliveryBoard.fromRequests(requests);
    });
