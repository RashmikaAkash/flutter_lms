import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  TokenStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const String _accessTokenKey = 'accessToken';
  static const String _refreshTokenKey = 'refreshToken';
  static const String _roleKey = 'role';
  static const String _onboardingCompletedKey = 'onboardingCompleted';

  Future<void> saveAccessToken(String token) async {
    await _storage.write(
      key: _accessTokenKey,
      value: token,
    );
  }

  Future<String?> getAccessToken() async {
    return _storage.read(key: _accessTokenKey);
  }

  Future<void> saveRefreshToken(String token) async {
    await _storage.write(
      key: _refreshTokenKey,
      value: token,
    );
  }

  Future<String?> getRefreshToken() async {
    return _storage.read(key: _refreshTokenKey);
  }

  Future<void> saveRole(String role) async {
    await _storage.write(
      key: _roleKey,
      value: role,
    );
  }

  Future<String?> getRole() async {
    return _storage.read(key: _roleKey);
  }

  Future<void> saveSession({
    required String accessToken,
    required String refreshToken,
    required String role,
  }) async {
    await Future.wait([
      saveAccessToken(accessToken),
      saveRefreshToken(refreshToken),
      saveRole(role),
    ]);
  }

  Future<void> saveOnboardingCompleted() async {
    await _storage.write(
      key: _onboardingCompletedKey,
      value: 'true',
    );
  }

  Future<bool> isOnboardingCompleted() async {
    final value = await _storage.read(
      key: _onboardingCompletedKey,
    );

    return value == 'true';
  }

  Future<void> clearSession() async {
    await Future.wait([
      _storage.delete(key: _accessTokenKey),
      _storage.delete(key: _refreshTokenKey),
      _storage.delete(key: _roleKey),
    ]);
  }
}