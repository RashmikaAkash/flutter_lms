import '../network/api_client.dart';
import '../storage/token_storage.dart';
import '../errors/api_exception.dart';

class AuthService {
  AuthService({
    ApiClient? apiClient,
    TokenStorage? tokenStorage,
  })  : _apiClient = apiClient ?? ApiClient(),
        _tokenStorage = tokenStorage ?? TokenStorage();

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  // ============================================================
  // LOGIN
  // ============================================================

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
      throw const ApiException(
        message: 'Invalid login response',
      );
    }

    final data = responseData['data'];

    if (data is! Map<String, dynamic>) {
      throw const ApiException(
        message: 'Login data is missing',
      );
    }

    final user = data['user'];

    if (user is! Map<String, dynamic>) {
      throw const ApiException(
        message: 'User data is missing',
      );
    }

    final tokens = data['tokens'];

    if (tokens is! Map<String, dynamic>) {
      throw const ApiException(
        message: 'Token data is missing',
      );
    }

    final accessToken = tokens['accessToken'];
    final refreshToken = tokens['refreshToken'];
    final role = user['role'];

    if (accessToken is! String || accessToken.isEmpty) {
      throw const ApiException(
        message: 'Access token is missing',
      );
    }

    if (refreshToken is! String || refreshToken.isEmpty) {
      throw const ApiException(
        message: 'Refresh token is missing',
      );
    }

    if (role is! String || role.isEmpty) {
      throw const ApiException(
        message: 'User role is missing',
      );
    }

    await _tokenStorage.saveSession(
      accessToken: accessToken,
      refreshToken: refreshToken,
      role: role,
    );

    return role;
  }

  // ============================================================
  // STUDENT REGISTRATION
  // ============================================================

  Future<String> registerStudent({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String confirmPassword,
    required String dateOfBirth,
    required String educationLevel,
    required List<String> learningGoals,
  }) async {
    final response = await _apiClient.post(
      '/api/v1/auth/register/student',
      data: {
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'password': password,
        'confirmPassword': confirmPassword,
        'dateOfBirth': dateOfBirth,
        'educationLevel': educationLevel,
        'learningGoals': learningGoals,
      },
      requiresAuth: false,
    );

    return _extractMessage(
      response.data,
      fallback: 'Student registration successful',
    );
  }

  // ============================================================
  // INSTRUCTOR REGISTRATION
  // ============================================================

  Future<String> registerInstructor({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String confirmPassword,
    required String headline,
    required String qualification,
    required int experienceYears,
    required List<String> expertise,
    required String biography,
  }) async {
    final response = await _apiClient.post(
      '/api/v1/auth/register/instructor',
      data: {
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'password': password,
        'confirmPassword': confirmPassword,
        'headline': headline,
        'qualification': qualification,
        'experienceYears': experienceYears,
        'expertise': expertise,
        'biography': biography,
      },
      requiresAuth: false,
    );

    return _extractMessage(
      response.data,
      fallback: 'Instructor registration successful',
    );
  }

  // ============================================================
  // RESEND VERIFICATION OTP
  // ============================================================

  Future<String> resendVerificationOtp({
    required String email,
  }) async {
    final response = await _apiClient.post(
      '/api/v1/auth/resend-verification-otp',
      data: {
        'email': email,
      },
      requiresAuth: false,
    );

    return _extractMessage(
      response.data,
      fallback: 'Verification OTP sent successfully',
    );
  }

  // ============================================================
  // VERIFY EMAIL
  // ============================================================

  Future<String> verifyEmail({
    required String email,
    required String otp,
  }) async {
    final response = await _apiClient.post(
      '/api/v1/auth/verify-email',
      data: {
        'email': email,
        'otp': otp,
      },
      requiresAuth: false,
    );

    return _extractMessage(
      response.data,
      fallback: 'Email verified successfully',
    );
  }

  // ============================================================
  // FORGOT PASSWORD
  // ============================================================

  Future<String> forgotPassword({
    required String email,
  }) async {
    final response = await _apiClient.post(
      '/api/v1/auth/forgot-password',
      data: {
        'email': email,
      },
      requiresAuth: false,
    );

    return _extractMessage(
      response.data,
      fallback: 'Password-reset OTP sent successfully',
    );
  }

  // ============================================================
  // VERIFY PASSWORD RESET OTP
  // ============================================================

  Future<String> verifyPasswordResetOtp({
    required String email,
    required String otp,
  }) async {
    final response = await _apiClient.post(
      '/api/v1/auth/verify-password-reset-otp',
      data: {
        'email': email,
        'otp': otp,
      },
      requiresAuth: false,
    );

    final responseData = response.data;

    if (responseData is! Map<String, dynamic>) {
      throw const ApiException(
        message: 'Invalid server response',
      );
    }

    final data = responseData['data'];

    if (data is! Map<String, dynamic>) {
      throw const ApiException(
        message: 'Password reset data is missing',
      );
    }

    final resetToken = data['resetToken'];

    if (resetToken is! String || resetToken.isEmpty) {
      throw const ApiException(
        message: 'Password reset token is missing',
      );
    }

    return resetToken;
  }

  // ============================================================
  // RESET PASSWORD
  // ============================================================

  Future<String> resetPassword({
    required String resetToken,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final response = await _apiClient.post(
      '/api/v1/auth/reset-password',
      data: {
        'resetToken': resetToken,
        'newPassword': newPassword,
        'confirmPassword': confirmPassword,
      },
      requiresAuth: false,
    );

    return _extractMessage(
      response.data,
      fallback: 'Password reset successfully. Please sign in again.',
    );
  }

  // ============================================================
  // LOGOUT
  // ============================================================

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

  // ============================================================
  // LOGOUT ALL
  // ============================================================

  Future<void> logoutAll() async {
    try {
      await _apiClient.post(
        '/api/v1/auth/logout-all',
        requiresAuth: true,
      );
    } finally {
      await _tokenStorage.clearSession();
    }
  }

  // ============================================================
  // RESPONSE MESSAGE HELPER
  // ============================================================

  String _extractMessage(
      dynamic responseData, {
        required String fallback,
      }) {
    if (responseData is! Map<String, dynamic>) {
      throw const ApiException(
        message: 'Invalid server response',
      );
    }

    final message = responseData['message'];

    if (message is String && message.trim().isNotEmpty) {
      return message;
    }

    return fallback;
  }
}