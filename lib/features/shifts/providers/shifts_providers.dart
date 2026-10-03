import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vitago_app/features/authentication/providers/auth_providers.dart';
import 'package:vitago_app/features/shifts/repositories/shifts_repository.dart';
import 'package:vitago_app/features/shifts/repositories/shifts_repository_impl.dart';
import 'package:vitago_app/features/shifts/services/shifts_api_service.dart';

final shiftsApiServiceProvider = Provider<ShiftsApiService>((ref) {
  return ShiftsApiService(ref.watch(apiClientProvider));
});

final shiftsRepositoryProvider = Provider<ShiftsRepository>((ref) {
  return ShiftsRepositoryImpl(ref.watch(shiftsApiServiceProvider));
});
