import './../../errors/api_exception.dart';
import './../profile/full_user_profile.dart';
import './../profile/user_profile.dart';
import './../../network/api_client.dart';
import './../../storage/token_storage.dart';

class ProfileService {
  ProfileService({
    ApiClient? apiClient,
    TokenStorage? tokenStorage,
  })  : _apiClient = apiClient ?? ApiClient(),
        _tokenStorage = tokenStorage ?? TokenStorage();

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  // ============================================================
  // GET FULL PROFILE
  // ============================================================

  Future<FullUserProfile> getFullProfile() async {
    final response = await _apiClient.get(
      '/api/v1/users/me/full-profile',
      requiresAuth: true,
    );

    final responseData = response.data;

    if (responseData is! Map<String, dynamic>) {
      throw const ApiException(
        message: 'Invalid profile response',
      );
    }

    final data = responseData['data'];

    if (data is! Map<String, dynamic>) {
      throw const ApiException(
        message: 'Profile data is missing',
      );
    }

    final user = data['user'];

    if (user is! Map<String, dynamic>) {
      throw const ApiException(
        message: 'User profile is missing',
      );
    }

    final role = user['role'];

    return FullUserProfile.fromJson(
      data,
      role: role is String ? role : null,
    );
  }

  // ============================================================
  // UPDATE SHARED USER PROFILE
  // ============================================================

  Future<UserProfile> updateUserProfile({
    String? firstName,
    String? lastName,
    String? bio,
  }) async {
    final data = <String, dynamic>{};

    if (firstName != null) {
      data['firstName'] = firstName;
    }

    if (lastName != null) {
      data['lastName'] = lastName;
    }

    if (bio != null) {
      data['bio'] = bio;
    }

    if (data.isEmpty) {
      throw const ApiException(
        message: 'No profile changes provided',
      );
    }

    final response = await _apiClient.patch(
      '/api/v1/users/me',
      data: data,
      requiresAuth: true,
    );

    final responseData = response.data;

    if (responseData is! Map<String, dynamic>) {
      throw const ApiException(
        message: 'Invalid profile update response',
      );
    }

    final responseUser = responseData['data'] is Map<String, dynamic>
        ? responseData['data']['user']
        : null;

    if (responseUser is! Map<String, dynamic>) {
      throw const ApiException(
        message: 'Updated user profile is missing',
      );
    }

    return UserProfile.fromJson(responseUser);
  }

  // ============================================================
  // GET SAVED ROLE
  // ============================================================

  Future<String?> getSavedRole() {
    return _tokenStorage.getRole();
  }
}