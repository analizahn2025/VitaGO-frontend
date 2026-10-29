import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vitago_app/core/models/paginated_result.dart';
import 'package:vitago_app/features/fleet/providers/driver_reports_providers.dart';
import 'package:vitago_app/features/fleet/models/driver_report.dart';

final driverReportsControllerProvider = FutureProvider.autoDispose
    .family<PaginatedResult<DriverDailyReport>, DriverReportQuery>(
      (ref, query) =>
          ref.watch(driverReportsRepositoryProvider).getReports(query),
    );
final driverReportControllerProvider = FutureProvider.autoDispose
    .family<DriverDailyReport, ({String id, String? date})>(
      (ref, query) => ref
          .watch(driverReportsRepositoryProvider)
          .getReport(query.id, query.date),
    );
final driverTemperaturesControllerProvider = FutureProvider.autoDispose
    .family<
      PaginatedResult<DriverTemperatureReading>,
      ({String id, String date, int page})
    >(
      (ref, query) => ref
          .watch(driverReportsRepositoryProvider)
          .getTemperatures(query.id, query.date, query.page),
    );
