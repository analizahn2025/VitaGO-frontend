import 'package:dio/dio.dart';
import 'package:vitago_app/core/errors/app_failure.dart';
import 'package:vitago_app/core/network/api_client.dart';
import 'package:vitago_app/features/profile/models/user_profile.dart';

class ProfileApiService {
  const ProfileApiService(this._apiClient);

  final ApiClient _apiClient;

  Future<UserProfile> getCurrentProfile() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        'usuarios/mi-perfil/',
      );
      final data = response.data;
      if (data == null) {
        throw const FormatException('Respuesta de perfil vacía.');
      }
      return UserProfile.fromJson(data);
    } on DioException catch (error) {
      throw AppFailure.fromDio(error);
    } on FormatException {
      throw const AppFailure(
        message: 'El perfil recibido no tiene el formato esperado.',
      );
    }
  }
}
