import 'student_profile.dart';
import 'user_profile.dart';

class FullUserProfile {
  const FullUserProfile({
    required this.user,
    required this.profile,
  });

  final UserProfile user;
  final StudentProfile? profile;

  factory FullUserProfile.fromJson(
      Map<String, dynamic> json, {
        String? role,
      }) {
    final userJson = json['user'];

    if (userJson is! Map<String, dynamic>) {
      throw const FormatException('User profile data is missing');
    }

    final profileJson = json['profile'];

    return FullUserProfile(
      user: UserProfile.fromJson(userJson),
      profile: role == 'STUDENT' &&
          profileJson is Map<String, dynamic>
          ? StudentProfile.fromJson(profileJson)
          : null,
    );
  }
}