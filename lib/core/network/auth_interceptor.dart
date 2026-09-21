import 'package:dio/dio.dart';

import '../config/app_config.dart';
import '../storage/token_storage.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required TokenStorage tokenStorage,
  }) : _tokenStorage = tokenStorage;

  final TokenStorage _tokenStorage;

  bool _isRefreshing = false;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final requiresAuth = options.extra['requiresAuth'] == true;

    if (!requiresAuth) {
      handler.next(options);
      return;
    }

    final accessToken = await _tokenStorage.getAccessToken();

    if (accessToken != null && accessToken.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }

    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final request = err.requestOptions;

    final requiresAuth = request.extra['requiresAuth'] == true;
    final alreadyRetried = request.extra['retried'] == true;

    if (!_shouldRefresh(err, request, requiresAuth, alreadyRetried)) {
      handler.next(err);
      return;
    }

    if (_isRefreshing) {
      handler.next(err);
      return;
    }

    _isRefreshing = true;

    try {
      final newAccessToken = await _refreshAccessToken();

      if (newAccessToken == null || newAccessToken.isEmpty) {
        await _tokenStorage.clearSession();
        handler.next(err);
        return;
      }

      final retryRequest = await _retryRequest(
        request,
        newAccessToken,
      );

      handler.resolve(retryRequest);
    } catch (_) {
      await _tokenStorage.clearSession();
      handler.next(err);
    } finally {
      _isRefreshing = false;
    }
  }

  bool _shouldRefresh(
    DioException error,
    RequestOptions request,
    bool requiresAuth,
    bool alreadyRetried,
  ) {
    if (!requiresAuth) {
      return false;
    }

    if (alreadyRetried) {
      return false;
    }

    if (request.path.contains('/auth/refresh-token')) {
      return false;
    }

    return error.response?.statusCode == 401;
  }

  Future<String?> _refreshAccessToken() async {
    final refreshToken = await _tokenStorage.getRefreshToken();

    if (refreshToken == null || refreshToken.isEmpty) {
      return null;
    }

    final refreshDio = Dio(
      BaseOptions(
        baseUrl: AppConfig.baseUrl,
        connectTimeout: AppConfig.connectTimeout,
        receiveTimeout: AppConfig.receiveTimeout,
        sendTimeout: AppConfig.sendTimeout,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    try {
      final response = await refreshDio.post(
        '/api/v1/auth/refresh-token',
        data: {
          'refreshToken': refreshToken,
        },
      );

      final responseData = response.data;

      if (responseData is! Map<String, dynamic>) {
        return null;
      }

      final data = responseData['data'];

      if (data is! Map<String, dynamic>) {
        return null;
      }

      final tokens = data['tokens'];

      if (tokens is! Map<String, dynamic>) {
        return null;
      }

      final newAccessToken = tokens['accessToken'];
      final newRefreshToken = tokens['refreshToken'];

      if (newAccessToken is! String || newAccessToken.isEmpty) {
        return null;
      }

      if (newRefreshToken is String && newRefreshToken.isNotEmpty) {
        await _tokenStorage.saveRefreshToken(newRefreshToken);
      }

      await _tokenStorage.saveAccessToken(newAccessToken);

      return newAccessToken;
    } on DioException {
      return null;
    } finally {
      refreshDio.close();
    }
  }

  Future<Response<dynamic>> _retryRequest(
    RequestOptions request,
    String accessToken,
  ) async {
    final retryDio = Dio(
      BaseOptions(
        baseUrl: AppConfig.baseUrl,
        connectTimeout: AppConfig.connectTimeout,
        receiveTimeout: AppConfig.receiveTimeout,
        sendTimeout: AppConfig.sendTimeout,
      ),
    );

    final headers = Map<String, dynamic>.from(request.headers);

    headers['Authorization'] = 'Bearer $accessToken';

    final retryOptions = Options(
      method: request.method,
      headers: headers,
      responseType: request.responseType,
      contentType: request.contentType,
      sendTimeout: request.sendTimeout,
      receiveTimeout: request.receiveTimeout,
      extra: {
        ...request.extra,
        'retried': true,
      },
    );

    try {
      return await retryDio.request<dynamic>(
        request.path,
        data: request.data,
        queryParameters: request.queryParameters,
        options: retryOptions,
        cancelToken: request.cancelToken,
        onReceiveProgress: request.onReceiveProgress,
        onSendProgress: request.onSendProgress,
      );
    } finally {
      retryDio.close();
    }
  }
}
