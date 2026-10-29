import 'package:vitago_app/core/models/paginated_result.dart';
import 'package:vitago_app/features/shifts/models/driver_shift.dart';
import 'package:vitago_app/features/tracking/models/tracking_point.dart';

abstract interface class ShiftsRepository {
  Future<DriverShift> startShift(ShiftCoordinatesInput input);

  Future<DriverShift?> getActiveShift();
  Future<ActiveShiftDay> getActiveShiftDay();
  Future<DriverShift> startLunch(String shiftId);
  Future<DriverShift> finishLunch(String shiftId);

  Future<PaginatedResult<DriverShift>> getShifts(ShiftQuery query);

  Future<DriverShift> getShift(String shiftId);

  Future<DriverShift> finishShift(String shiftId, ShiftCoordinatesInput input);

  Future<DriverShift> confirmGpsSynchronization(
    String shiftId,
    List<GpsSessionManifest> sessions,
  );

  Future<PaginatedResult<MileageRevision>> getMileageRevisions(String shiftId);
}
