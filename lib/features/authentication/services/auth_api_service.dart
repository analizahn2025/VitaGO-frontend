import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:vitago_app/core/errors/app_failure.dart';
import 'package:vitago_app/core/network/api_client.dart';
import 'package:vitago_app/features/authentication/models/auth_session.dart';

class AuthApiService {
  factory AuthApiService({
    required Dio publicDio,
    required ApiClient apiClient,
  }) {
    return AuthApiService._(publicDio, apiClient);
  }

  AuthApiService._(this._publicDio, this._apiClient);

  final Dio _publicDio;
  final ApiClient _apiClient;

  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _publicDio.post<Map<String, dynamic>>(
        'autenticacion/iniciar-sesion/',
        data: {'correo': email, 'contrasena': password},
        options: Options(receiveTimeout: const Duration(seconds: 60)),
      );
      final data = response.data;
      if (data == null) {
        throw const FormatException('Respuesta de inicio de sesión vacía.');
      }
      return AuthSession.fromLoginResponse(data);
    } on DioException catch (error) {
      _logLoginFailure(error);
      throw AppFailure.fromDio(error);
    } on FormatException {
      throw const AppFailure(
        message:
            'La respuesta de inicio de sesión no tiene el formato esperado.',
      );
    }
  }

  void _logLoginFailure(DioException error) {
    if (!kDebugMode) {
      return;
    }

    final response = error.response;
    final cause = error.error;
    final causeMessage = cause is HttpException
        ? cause.message.replaceAll(RegExp(r'\s+'), ' ').trim()
        : 'none';
    debugPrint(
      '[VitaGo] login: '
      'dio=${error.type.name} '
      'status=${response?.statusCode ?? 'none'} '
      'cause=${cause.runtimeType} '
      'causeMessage=$causeMessage '
      'contentType=${response?.headers.value(Headers.contentTypeHeader) ?? 'none'} '
      'contentLength=${response?.headers.value(Headers.contentLengthHeader) ?? 'none'}',
    );
  }

  Future<void> logout() async {
    try {
      await _apiClient.post<void>('autenticacion/cerrar-sesion/');
    } on DioException catch (error) {
      throw AppFailure.fromDio(error);
    }
  }

  Future<void> logoutAll() async {
    try {
      await _apiClient.post<void>('autenticacion/cerrar-todas-las-sesiones/');
    } on DioException catch (error) {
      throw AppFailure.fromDio(error);
    }
  }
}
