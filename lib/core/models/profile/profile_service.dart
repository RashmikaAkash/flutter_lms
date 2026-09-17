import './../../errors/api_exception.dart';
import './../profile/full_user_profile.dart';
import './../profile/student_profile.dart';
import './../profile/user_profile.dart';
import './../../network/api_client.dart';
import './../../storage/token_storage.dart';
import 'package:dio/dio.dart';
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';

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
  // GET STUDENT PROFILE
  // ============================================================

  Future<StudentProfile> getStudentProfile() async {
    final response = await _apiClient.get(
      '/api/v1/profiles/student/me',
      requiresAuth: true,
    );

    final responseData = response.data;

    if (responseData is! Map<String, dynamic>) {
      throw const ApiException(
        message: 'Invalid student profile response',
      );
    }

    final data = responseData['data'];

    if (data is! Map<String, dynamic>) {
      throw const ApiException(
        message: 'Student profile data is missing',
      );
    }

    final profile = data['profile'];

    if (profile is! Map<String, dynamic>) {
      throw const ApiException(
        message: 'Student profile is missing',
      );
    }

    return StudentProfile.fromJson(profile);
  }

  // ============================================================
  // UPDATE STUDENT PROFILE
  // ============================================================

  Future<StudentProfile> updateStudentProfile({
    String? educationLevel,
    List<String>? learningGoals,
  }) async {
    final data = <String, dynamic>{};

    if (educationLevel != null) {
      data['educationLevel'] = educationLevel;
    }

    if (learningGoals != null) {
      data['learningGoals'] = learningGoals;
    }

    if (data.isEmpty) {
      throw const ApiException(
        message: 'No student profile changes provided',
      );
    }

    final response = await _apiClient.patch(
      '/api/v1/profiles/student/me',
      data: data,
      requiresAuth: true,
    );

    final responseData = response.data;

    if (responseData is! Map<String, dynamic>) {
      throw const ApiException(
        message: 'Invalid student profile update response',
      );
    }

    final dataObject = responseData['data'];

    if (dataObject is! Map<String, dynamic>) {
      throw const ApiException(
        message: 'Student profile update data is missing',
      );
    }

    final profile = dataObject['profile'];

    if (profile is! Map<String, dynamic>) {
      throw const ApiException(
        message: 'Updated student profile is missing',
      );
    }

    return StudentProfile.fromJson(profile);
  }

  // ============================================================
  // UPLOAD PROFILE IMAGE
  // ============================================================

  Future<UserProfile> uploadProfileImage({
    required String filePath,
  }) async {
    final mimeType = lookupMimeType(filePath);

    final mediaType = mimeType != null
        ? MediaType.parse(mimeType)
        : null;

    final file = await MultipartFile.fromFile(
      filePath,
      filename: filePath.split(RegExp(r'[\\/]')).last,
      contentType: mediaType,
    );

    final formData = FormData.fromMap({
      'profileImage': file,
    });

    final response = await _apiClient.post(
      '/api/v1/users/me/profile-image',
      data: formData,
      requiresAuth: true,
    );

    final responseData = response.data;

    if (responseData is! Map<String, dynamic>) {
      throw const ApiException(
        message: 'Invalid profile image upload response',
      );
    }

    final data = responseData['data'];

    if (data is! Map<String, dynamic>) {
      throw const ApiException(
        message: 'Profile image upload data is missing',
      );
    }

    final user = data['user'];

    if (user is! Map<String, dynamic>) {
      throw const ApiException(
        message: 'Updated user profile is missing',
      );
    }

    return UserProfile.fromJson(user);
  }

  // ============================================================
  // DELETE PROFILE IMAGE
  // ============================================================

  Future<UserProfile> deleteProfileImage() async {
    final response = await _apiClient.delete(
      '/api/v1/users/me/profile-image',
      requiresAuth: true,
    );

    final responseData = response.data;

    if (responseData is! Map<String, dynamic>) {
      throw const ApiException(
        message: 'Invalid profile image deletion response',
      );
    }

    final data = responseData['data'];

    if (data is! Map<String, dynamic>) {
      throw const ApiException(
        message: 'Profile image deletion data is missing',
      );
    }

    final user = data['user'];

    if (user is! Map<String, dynamic>) {
      throw const ApiException(
        message: 'Updated user profile is missing',
      );
    }

    return UserProfile.fromJson(user);
  }

  // ============================================================
  // GET SAVED ROLE
  // ============================================================

  Future<String?> getSavedRole() {
    return _tokenStorage.getRole();
  }
}