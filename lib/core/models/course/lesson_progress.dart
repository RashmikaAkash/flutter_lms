class LessonProgress {
  const LessonProgress({
    required this.id,
    required this.studentId,
    required this.courseId,
    required this.lessonId,
    required this.enrollmentId,
    required this.status,
    required this.startedAt,
    required this.completedAt,
    required this.lastAccessedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String studentId;
  final String courseId;
  final String lessonId;
  final String enrollmentId;
  final String status;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? lastAccessedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isNotStarted => status == 'NOT_STARTED';

  bool get isInProgress => status == 'IN_PROGRESS';

  bool get isCompleted => status == 'COMPLETED';

  factory LessonProgress.fromJson(
    Map<String, dynamic> json,
  ) {
    return LessonProgress(
      id: json['id'] as String? ?? '',
      studentId: json['studentId'] as String? ?? '',
      courseId: json['courseId'] as String? ?? '',
      lessonId: json['lessonId'] as String? ?? '',
      enrollmentId: json['enrollmentId'] as String? ?? '',
      status: json['status'] as String? ?? 'NOT_STARTED',
      startedAt: _parseDate(json['startedAt']),
      completedAt: _parseDate(json['completedAt']),
      lastAccessedAt: _parseDate(json['lastAccessedAt']),
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
}
