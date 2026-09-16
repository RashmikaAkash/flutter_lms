import '../network/api_client.dart';
import '../storage/token_storage.dart';

class AuthService {
  AuthService({
    ApiClient? apiClient,
    TokenStorage? tokenStorage,
  })  : _apiClient = apiClient ?? ApiClient(),
        _tokenStorage = tokenStorage ?? TokenStorage();

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  Future<String> login({
    required String email,
    required String password,
  }) async {
    final response = await _apiClient.post(
      '/api/v1/auth/login',
      data: {
        'email': email,
        'password': password,
      },
      requiresAuth: false,
    );

    final responseData = response.data;

    if (responseData is! Map<String, dynamic>) {
      throw Exception('Invalid login response');
    }

    final data = responseData['data'];

    if (data is! Map<String, dynamic>) {
      throw Exception('Login data is missing');
    }

    final user = data['user'];

    if (user is! Map<String, dynamic>) {
      throw Exception('User data is missing');
    }

    final tokens = data['tokens'];

    if (tokens is! Map<String, dynamic>) {
      throw Exception('Token data is missing');
    }

    final accessToken = tokens['accessToken'];
    final refreshToken = tokens['refreshToken'];
    final role = user['role'];

    if (accessToken is! String || accessToken.isEmpty) {
      throw Exception('Access token is missing');
    }

    if (refreshToken is! String || refreshToken.isEmpty) {
      throw Exception('Refresh token is missing');
    }

    if (role is! String || role.isEmpty) {
      throw Exception('User role is missing');
    }

    await _tokenStorage.saveSession(
      accessToken: accessToken,
      refreshToken: refreshToken,
      role: role,
    );

    return role;
  }

  Future<void> logout() async {
    try {
      await _apiClient.post(
        '/api/v1/auth/logout',
        requiresAuth: true,
      );
    } finally {
      await _tokenStorage.clearSession();
    }
  }
}