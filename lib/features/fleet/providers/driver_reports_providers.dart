import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vitago_app/features/authentication/providers/auth_providers.dart';
import 'package:vitago_app/features/fleet/repositories/driver_reports_repository.dart';
import 'package:vitago_app/features/fleet/repositories/driver_reports_repository_impl.dart';
import 'package:vitago_app/features/fleet/services/driver_reports_api_service.dart';

final driverReportsApiServiceProvider = Provider<DriverReportsApiService>(
  (ref) => DriverReportsApiService(ref.watch(apiClientProvider)),
);
final driverReportsRepositoryProvider = Provider<DriverReportsRepository>(
  (ref) =>
      DriverReportsRepositoryImpl(ref.watch(driverReportsApiServiceProvider)),
);
