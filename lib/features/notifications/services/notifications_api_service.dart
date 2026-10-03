import 'package:dio/dio.dart';
import 'package:vitago_app/core/errors/app_failure.dart';
import 'package:vitago_app/core/network/api_client.dart';
import 'package:vitago_app/features/notifications/models/driver_notification.dart';

class NotificationsApiService {
  const NotificationsApiService(this._apiClient);

  final ApiClient _apiClient;

  Future<DriverNotificationFeed> getNotifications() async {
    try {
      final response = await _apiClient.get<Object?>(
        'notificaciones/',
        queryParameters: const {'pagina': 1, 'tamano_pagina': 50},
      );
      return DriverNotificationFeed.fromJson(response.data);
    } on DioException catch (error) {
      throw AppFailure.fromDio(error);
    } on FormatException {
      throw const AppFailure(
        message: 'Las notificaciones no tienen el formato esperado.',
      );
    }
  }

  Future<int> getUnreadCount() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        'notificaciones/conteo-no-leidas/',
      );
      final data = response.data;
      if (data == null || !data.containsKey('conteo_no_leidas')) {
        throw const FormatException('Respuesta sin conteo.');
      }
      return int.parse(data['conteo_no_leidas'].toString());
    } on DioException catch (error) {
      throw AppFailure.fromDio(error);
    } on FormatException {
      throw const AppFailure(
        message: 'El conteo de notificaciones no tiene el formato esperado.',
      );
    }
  }

  Future<DriverNotification> markRead(String notificationId) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        'notificaciones/$notificationId/marcar-leida/',
      );
      final data = response.data;
      if (data == null) throw const FormatException('Respuesta vacía.');
      return DriverNotification.fromJson(data);
    } on DioException catch (error) {
      throw AppFailure.fromDio(error);
    } on FormatException {
      throw const AppFailure(
        message: 'La notificación actualizada no tiene el formato esperado.',
      );
    }
  }
}
