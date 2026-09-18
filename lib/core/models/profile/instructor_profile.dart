class InstructorProfile {
  const InstructorProfile({
    required this.id,
    required this.userId,
    required this.headline,
    required this.qualification,
    required this.experienceYears,
    required this.expertise,
    required this.biography,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final String headline;
  final String qualification;
  final int experienceYears;
  final List<String> expertise;
  final String biography;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory InstructorProfile.fromJson(Map<String, dynamic> json) {
    return InstructorProfile(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      headline: json['headline'] as String? ?? '',
      qualification: json['qualification'] as String? ?? '',
      experienceYears: json['experienceYears'] is int
          ? json['experienceYears'] as int
          : int.tryParse(
        json['experienceYears']?.toString() ?? '',
      ) ??
          0,
      expertise: json['expertise'] is List
          ? (json['expertise'] as List)
          .map((item) => item.toString())
          .toList()
          : const [],
      biography: json['biography'] as String? ?? '',
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseDateTime(json['updatedAt']),
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }

    return null;
  }
}