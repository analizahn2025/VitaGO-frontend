import 'package:vitago_app/core/models/paginated_result.dart';
import 'package:vitago_app/features/shifts/models/driver_shift.dart';

abstract interface class ShiftsRepository {
  Future<DriverShift> startShift(ShiftCoordinatesInput input);

  Future<DriverShift?> getActiveShift();

  Future<PaginatedResult<DriverShift>> getShifts(ShiftQuery query);

  Future<DriverShift> getShift(String shiftId);

  Future<DriverShift> finishShift(String shiftId, ShiftCoordinatesInput input);
}
