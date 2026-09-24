class CourseReview {
  const CourseReview({
    required this.id,
    required this.courseId,
    required this.studentId,
    required this.studentName,
    required this.rating,
    required this.comment,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String courseId;
  final String studentId;
  final String studentName;
  final int rating;
  final String? comment;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory CourseReview.fromJson(Map<String, dynamic> json) {
    final student = json['studentId'];
    final studentMap = student is Map
        ? Map<String, dynamic>.from(student)
        : const <String, dynamic>{};
    final firstName = studentMap['firstName'] as String? ?? '';
    final lastName = studentMap['lastName'] as String? ?? '';

    return CourseReview(
      id: json['id'] as String? ?? '',
      courseId: _idFrom(json['courseId']),
      studentId: _idFrom(student),
      studentName: '$firstName $lastName'.trim(),
      rating: _parseInt(json['rating']),
      comment: json['comment'] as String?,
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
    );
  }

  static String _idFrom(dynamic value) {
    if (value is Map) {
      return value['id']?.toString() ?? '';
    }
    return value?.toString() ?? '';
  }

  static int _parseInt(dynamic value) {
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value is! String || value.isEmpty) {
      return null;
    }
    return DateTime.tryParse(value);
  }
}
