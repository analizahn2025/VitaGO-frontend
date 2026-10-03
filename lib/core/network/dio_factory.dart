import 'package:dio/dio.dart';
import 'package:vitago_app/app/config/app_config.dart';

abstract final class DioFactory {
  static Dio create(AppConfig config) {
    return Dio(
      BaseOptions(
        baseUrl: config.apiBaseUri.toString(),
        connectTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 20),
        contentType: Headers.jsonContentType,
        responseType: ResponseType.json,
        headers: const {'Accept': Headers.jsonContentType},
      ),
    );
  }
}
