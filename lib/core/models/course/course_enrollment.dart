class CourseEnrollment {
  const CourseEnrollment({
    required this.id,
    required this.studentId,
    required this.courseId,
    required this.courseTitle,
    required this.courseLevel,
    required this.courseLanguage,
    required this.courseStatus,
    required this.thumbnailUrl,
    required this.status,
    required this.progressPercentage,
    required this.enrolledAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String studentId;
  final String courseId;
  final String courseTitle;
  final String courseLevel;
  final String courseLanguage;
  final String courseStatus;
  final String? thumbnailUrl;
  final String status;
  final double progressPercentage;
  final DateTime? enrolledAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory CourseEnrollment.fromJson(Map<String, dynamic> json) {
    final rawCourse = json['courseId'];

    final courseMap = rawCourse is Map
        ? Map<String, dynamic>.from(rawCourse)
        : <String, dynamic>{};

    return CourseEnrollment(
      id: json['id'] as String? ?? '',
      studentId: json['studentId'] as String? ?? '',
      courseId: courseMap['id'] as String? ?? json['courseId'] as String? ?? '',
      courseTitle: courseMap['title'] as String? ?? '',
      courseLevel: courseMap['level'] as String? ?? '',
      courseLanguage: courseMap['language'] as String? ?? '',
      courseStatus: courseMap['status'] as String? ?? '',
      thumbnailUrl: _parseNullableString(
        courseMap['thumbnailUrl'],
      ),
      status: json['status'] as String? ?? '',
      progressPercentage: _parseDouble(
        json['progressPercentage'],
      ),
      enrolledAt: _parseDate(json['enrolledAt']),
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
    );
  }

  static double _parseDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value is! String || value.isEmpty) {
      return null;
    }

    return DateTime.tryParse(value);
  }

  static String? _parseNullableString(dynamic value) {
    if (value is! String || value.isEmpty) {
      return null;
    }

    return value;
  }
}
