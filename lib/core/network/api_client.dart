import 'package:dio/dio.dart';

typedef AuthorizationReader = Future<String?> Function();
typedef AuthorizationRefresher = Future<String?> Function();
typedef AuthorizationInvalidator = Future<void> Function();

class ApiClient {
  factory ApiClient({
    required Dio dio,
    required AuthorizationReader readAuthorization,
    required AuthorizationRefresher refreshAuthorization,
    required AuthorizationInvalidator invalidateAuthorization,
  }) {
    return ApiClient._(
      dio,
      readAuthorization,
      refreshAuthorization,
      invalidateAuthorization,
    );
  }

  ApiClient._(
    this._dio,
    this._readAuthorization,
    this._refreshAuthorization,
    this._invalidateAuthorization,
  ) {
    _dio.interceptors.add(
      InterceptorsWrapper(onRequest: _onRequest, onError: _onError),
    );
  }

  static const _alreadyRetriedKey = 'vitago_already_retried';

  final Dio _dio;
  final AuthorizationReader _readAuthorization;
  final AuthorizationRefresher _refreshAuthorization;
  final AuthorizationInvalidator _invalidateAuthorization;

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.get<T>(
      path,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response<T>> patch<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.patch<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response<T>> delete<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.delete<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<void> _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final authorization = await _readAuthorization();
    if (authorization != null) {
      options.headers['Authorization'] = authorization;
    }
    handler.next(options);
  }

  Future<void> _onError(
    DioException error,
    ErrorInterceptorHandler handler,
  ) async {
    final request = error.requestOptions;
    final wasRetried = request.extra[_alreadyRetriedKey] == true;
    if (error.response?.statusCode != 401) {
      handler.next(error);
      return;
    }

    if (wasRetried) {
      await _invalidateAuthorization();
      handler.next(error);
      return;
    }

    try {
      final authorization = await _refreshAuthorization();
      if (authorization == null) {
        handler.next(error);
        return;
      }

      request.headers['Authorization'] = authorization;
      request.extra[_alreadyRetriedKey] = true;
      final response = await _dio.fetch<dynamic>(request);
      handler.resolve(response);
    } on Object {
      handler.next(error);
    }
  }
}
