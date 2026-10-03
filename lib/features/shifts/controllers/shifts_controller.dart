import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vitago_app/core/models/paginated_result.dart';
import 'package:vitago_app/features/shifts/models/driver_shift.dart';
import 'package:vitago_app/features/shifts/providers/shifts_providers.dart';
import 'package:vitago_app/features/shifts/repositories/shifts_repository.dart';

final activeShiftControllerProvider = FutureProvider.autoDispose<DriverShift?>((
  ref,
) {
  return ref.watch(shiftsRepositoryProvider).getActiveShift();
});

final shiftsControllerProvider = FutureProvider.autoDispose
    .family<PaginatedResult<DriverShift>, ShiftQuery>((ref, query) {
      return ref.watch(shiftsRepositoryProvider).getShifts(query);
    });

final shiftControllerProvider = FutureProvider.autoDispose
    .family<DriverShift, String>((ref, shiftId) {
      return ref.watch(shiftsRepositoryProvider).getShift(shiftId);
    });

final shiftActionsControllerProvider = Provider<ShiftActionsController>((ref) {
  return ShiftActionsController(ref.watch(shiftsRepositoryProvider));
});

class ShiftActionsController {
  const ShiftActionsController(this._repository);

  final ShiftsRepository _repository;

  Future<DriverShift> start(ShiftCoordinatesInput input) =>
      _repository.startShift(input);

  Future<DriverShift> finish(String shiftId, ShiftCoordinatesInput input) =>
      _repository.finishShift(shiftId, input);
}
