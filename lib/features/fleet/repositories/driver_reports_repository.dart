import 'package:vitago_app/core/models/paginated_result.dart';
import 'package:vitago_app/features/fleet/models/driver_report.dart';

abstract interface class DriverReportsRepository {
  Future<PaginatedResult<DriverDailyReport>> getReports(
    DriverReportQuery query,
  );
  Future<DriverDailyReport> getReport(String id, String? date);
  Future<PaginatedResult<DriverTemperatureReading>> getTemperatures(
    String id,
    String date,
    int page,
  );
}
