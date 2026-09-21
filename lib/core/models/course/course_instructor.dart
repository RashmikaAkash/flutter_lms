class CourseInstructor {
  const CourseInstructor({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.bio,
    required this.profileImageUrl,
  });

  final String id;
  final String firstName;
  final String lastName;
  final String bio;
  final String? profileImageUrl;

  String get fullName {
    final name = '$firstName $lastName'.trim();
    return name.isEmpty ? 'Unknown Instructor' : name;
  }

  factory CourseInstructor.fromJson(Map<String, dynamic> json) {
    return CourseInstructor(
      id: json['id'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      bio: json['bio'] as String? ?? '',
      profileImageUrl: _parseNullableString(json['profileImageUrl']),
    );
  }

  static String? _parseNullableString(dynamic value) {
    if (value is! String || value.isEmpty) {
      return null;
    }

    return value;
  }
}
