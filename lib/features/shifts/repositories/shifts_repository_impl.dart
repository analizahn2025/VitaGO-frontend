import 'package:vitago_app/core/models/paginated_result.dart';
import 'package:vitago_app/features/shifts/models/driver_shift.dart';
import 'package:vitago_app/features/shifts/repositories/shifts_repository.dart';
import 'package:vitago_app/features/shifts/services/shifts_api_service.dart';

class ShiftsRepositoryImpl implements ShiftsRepository {
  const ShiftsRepositoryImpl(this._apiService);

  final ShiftsApiService _apiService;

  @override
  Future<DriverShift> startShift(ShiftCoordinatesInput input) =>
      _apiService.startShift(input);

  @override
  Future<DriverShift?> getActiveShift() => _apiService.getActiveShift();

  @override
  Future<PaginatedResult<DriverShift>> getShifts(ShiftQuery query) =>
      _apiService.getShifts(query);

  @override
  Future<DriverShift> getShift(String shiftId) => _apiService.getShift(shiftId);

  @override
  Future<DriverShift> finishShift(
    String shiftId,
    ShiftCoordinatesInput input,
  ) => _apiService.finishShift(shiftId, input);
}
