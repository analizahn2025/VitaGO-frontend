import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:vitago_app/core/errors/app_failure.dart';

class DeviceLocation {
  const DeviceLocation({
    required this.latitude,
    required this.longitude,
    required this.recordedAt,
    this.accuracyMeters,
    this.speedMetersPerSecond,
    this.headingDegrees,
  });

  final double latitude;
  final double longitude;
  final DateTime recordedAt;
  final double? accuracyMeters;
  final double? speedMetersPerSecond;
  final double? headingDegrees;

  String get latitudeText => latitude.toStringAsFixed(6);

  String get longitudeText => longitude.toStringAsFixed(6);
}

class DeviceLocationService {
  const DeviceLocationService();

  Future<bool> isServiceEnabled() => Geolocator.isLocationServiceEnabled();

  Stream<bool> watchServiceEnabled() async* {
    yield await isServiceEnabled();
    yield* Geolocator.getServiceStatusStream().map(
      (status) => status == ServiceStatus.enabled,
    );
  }

  Future<DeviceLocation> getCurrentLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw const AppFailure(
          message: 'No puedes continuar porque tienes el GPS apagado.',
        );
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        throw const AppFailure(
          message: 'VitaGo necesita permiso de ubicación para continuar.',
        );
      }
      if (permission == LocationPermission.deniedForever) {
        throw const AppFailure(
          message: 'El permiso de ubicación está bloqueado. Habilítalo en los ajustes del dispositivo.',
        );
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      return DeviceLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        recordedAt: position.timestamp,
        accuracyMeters: position.accuracy >= 0 ? position.accuracy : null,
        speedMetersPerSecond: position.speed >= 0 ? position.speed : null,
        headingDegrees: position.heading >= 0 && position.heading < 360
            ? position.heading
            : null,
      );
    } on AppFailure {
      rethrow;
    } on TimeoutException {
      throw const AppFailure(
        message: 'La ubicación tardó demasiado. Inténtalo nuevamente.',
      );
    } on PermissionDeniedException {
      throw const AppFailure(
        message: 'VitaGo necesita permiso de ubicación para continuar.',
      );
    } on LocationServiceDisabledException {
      throw const AppFailure(
        message: 'No puedes continuar porque tienes el GPS apagado.',
      );
    } on Object {
      throw const AppFailure(
        message: 'No fue posible obtener la ubicación del dispositivo.',
      );
    }
  }

  Future<bool> openSettings() => Geolocator.openAppSettings();

  Future<bool> openLocationSettings() => Geolocator.openLocationSettings();
}
