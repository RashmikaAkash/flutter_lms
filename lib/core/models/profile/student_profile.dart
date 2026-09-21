class StudentProfile {
  const StudentProfile({
    required this.id,
    required this.userId,
    required this.dateOfBirth,
    required this.educationLevel,
    required this.learningGoals,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final DateTime? dateOfBirth;
  final String educationLevel;
  final List<String> learningGoals;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory StudentProfile.fromJson(Map<String, dynamic> json) {
    return StudentProfile(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      dateOfBirth: _parseDate(json['dateOfBirth']),
      educationLevel: json['educationLevel'] as String? ?? '',
      learningGoals: _parseStringList(json['learningGoals']),
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value is! String || value.isEmpty) {
      return null;
    }

    return DateTime.tryParse(value);
  }

  static List<String> _parseStringList(dynamic value) {
    if (value is! List) {
      return const [];
    }

    return value.whereType<String>().toList();
  }
}
