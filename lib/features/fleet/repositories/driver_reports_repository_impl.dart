import 'package:vitago_app/core/models/paginated_result.dart';
import 'package:vitago_app/features/fleet/models/driver_report.dart';
import 'package:vitago_app/features/fleet/services/driver_reports_api_service.dart';
import 'package:vitago_app/features/fleet/repositories/driver_reports_repository.dart';

class DriverReportsRepositoryImpl implements DriverReportsRepository {
  const DriverReportsRepositoryImpl(this._api);
  final DriverReportsApiService _api;
  @override
  Future<PaginatedResult<DriverDailyReport>> getReports(
    DriverReportQuery query,
  ) => _api.getReports(query);
  @override
  Future<DriverDailyReport> getReport(String id, String? date) =>
      _api.getReport(id, date);
  @override
  Future<PaginatedResult<DriverTemperatureReading>> getTemperatures(
    String id,
    String date,
    int page,
  ) => _api.getTemperatures(id, date, page);
}
