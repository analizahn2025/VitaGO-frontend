import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:vitago_app/core/models/scoped_role.dart';
import 'package:vitago_app/core/network/api_client.dart';
import 'package:vitago_app/core/permissions/app_permissions.dart';
import 'package:vitago_app/core/permissions/scope_type.dart';
import 'package:vitago_app/features/profile/models/user_profile.dart';

const reportCompanyId = '395be863-81e1-4196-a668-b698af836653';
const reportPermissions = [
  AppPermissions.viewDrivers,
  AppPermissions.viewReports,
  AppPermissions.viewRequests,
  AppPermissions.viewShifts,
  AppPermissions.viewEvidence,
];
UserProfile administrativeProfile({
  List<String> permissions = reportPermissions,
  ScopeType scope = ScopeType.global,
}) => UserProfile(
  user: const ProfileUser(
    id: 'admin',
    email: 'admin@example.com',
    firstNames: 'Administración',
    lastNames: 'Prueba',
    status: 'ACTIVO',
  ),
  permissions: permissions,
  company: const ProfileOrganization(id: reportCompanyId, name: 'Analiza'),
  roles: [
    ScopedRole(
      code: 'ROL_PRUEBA',
      name: 'Rol de prueba',
      scopeType: scope,
      companyId: scope == ScopeType.global ? null : reportCompanyId,
      branchId: scope == ScopeType.branch ? 'branch' : null,
    ),
  ],
);
Map<String, dynamic> driverReportFixture() =>
    (jsonDecode(
          File('test/fixtures/driver_daily_report.json').readAsStringSync(),
        ) as Map<String, dynamic>)['resultados'][0]
        as Map<String, dynamic>;

class ContractApi {
  ContractApi(this.respond) {
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          calls.add(options);
          final result = respond(options);
          final response = Response(
            requestOptions: options,
            statusCode: result.status,
            data: result.data,
          );
          if (result.status >= 400) {
            handler.reject(
              DioException(
                requestOptions: options,
                response: response,
                type: DioExceptionType.badResponse,
              ),
            );
          } else {
            handler.resolve(response);
          }
        },
      ),
    );
    client = ApiClient(
      dio: dio,
      readAuthorization: () async => null,
      refreshAuthorization: () async => null,
      invalidateAuthorization: () async {},
    );
  }
  final ({int status, Map<String, dynamic> data}) Function(RequestOptions)
  respond;
  final calls = <RequestOptions>[];
  late final ApiClient client;
}
