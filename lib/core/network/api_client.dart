import 'package:dio/dio.dart';

import '../config/app_config.dart';
import '../errors/api_exception.dart';
import '../storage/token_storage.dart';
import 'auth_interceptor.dart';

class ApiClient {
  ApiClient({
    Dio? dio,
    TokenStorage? tokenStorage,
  })  : _dio = dio ?? Dio(),
        _tokenStorage = tokenStorage ?? TokenStorage() {
    _configure();
  }

  final Dio _dio;
  final TokenStorage _tokenStorage;

  void _configure() {
    _dio.options = BaseOptions(
      baseUrl: AppConfig.baseUrl,
      connectTimeout: AppConfig.connectTimeout,
      receiveTimeout: AppConfig.receiveTimeout,
      sendTimeout: AppConfig.sendTimeout,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    );

    _dio.interceptors.add(
      AuthInterceptor(
        tokenStorage: _tokenStorage,
      ),
    );
  }

  Future<Response<dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    bool requiresAuth = false,
  }) async {
    try {
      return await _dio.get(
        path,
        queryParameters: queryParameters,
        options: Options(
          extra: {
            'requiresAuth': requiresAuth,
          },
        ),
      );
    } on DioException catch (error) {
      throw _handleDioException(error);
    }
  }

  Future<Response<dynamic>> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    bool requiresAuth = false,
  }) async {
    try {
      return await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: Options(
          extra: {
            'requiresAuth': requiresAuth,
          },
        ),
      );
    } on DioException catch (error) {
      throw _handleDioException(error);
    }
  }

  Future<Response<dynamic>> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    bool requiresAuth = false,
  }) async {
    try {
      return await _dio.patch(
        path,
        data: data,
        queryParameters: queryParameters,
        options: Options(
          extra: {
            'requiresAuth': requiresAuth,
          },
        ),
      );
    } on DioException catch (error) {
      throw _handleDioException(error);
    }
  }

  Future<Response<dynamic>> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    bool requiresAuth = false,
  }) async {
    try {
      return await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: Options(
          extra: {
            'requiresAuth': requiresAuth,
          },
        ),
      );
    } on DioException catch (error) {
      throw _handleDioException(error);
    }
  }

  ApiException _handleDioException(DioException error) {
    final response = error.response;

    if (response != null) {
      final statusCode = response.statusCode;

      String? message;

      final responseData = response.data;

      if (responseData is Map<String, dynamic>) {
        final rawMessage = responseData['message'];

        if (rawMessage is String && rawMessage.isNotEmpty) {
          message = rawMessage;
        }
      }

      return ApiException.fromStatusCode(
        statusCode: statusCode ?? 0,
        message: message,
        responseBody: response.data,
      );
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return const ApiException(
          message: 'Connection timed out. Please try again.',
        );

      case DioExceptionType.sendTimeout:
        return const ApiException(
          message: 'Request timed out. Please try again.',
        );

      case DioExceptionType.receiveTimeout:
        return const ApiException(
          message: 'Server response timed out. Please try again.',
        );

      case DioExceptionType.transformTimeout:
        return const ApiException(
          message: 'Response processing timed out. Please try again.',
        );

      case DioExceptionType.connectionError:
        return const ApiException(
          message: 'Unable to connect to the server.',
        );

      case DioExceptionType.cancel:
        return const ApiException(
          message: 'Request was cancelled.',
        );

      case DioExceptionType.badCertificate:
        return const ApiException(
          message: 'Secure connection could not be established.',
        );

      case DioExceptionType.badResponse:
        return ApiException.fromStatusCode(
          statusCode: response?.statusCode ?? 0,
        );

      case DioExceptionType.unknown:
        return const ApiException(
          message: 'An unexpected network error occurred.',
        );
    }
  }
}
