class EnrollmentProgress {
  const EnrollmentProgress({
    required this.enrollment,
    required this.lessons,
  });

  final EnrollmentProgressEnrollment enrollment;
  final List<EnrollmentProgressLesson> lessons;

  factory EnrollmentProgress.fromJson(Map<String, dynamic> json) {
    final rawLessons = json['lessons'];

    return EnrollmentProgress(
      enrollment: EnrollmentProgressEnrollment.fromJson(
        Map<String, dynamic>.from(
          (json['enrollment'] as Map?) ?? <String, dynamic>{},
        ),
      ),
      lessons: rawLessons is List
          ? rawLessons
              .whereType<Map>()
              .map(
                (item) => EnrollmentProgressLesson.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList()
          : <EnrollmentProgressLesson>[],
    );
  }
}

class EnrollmentProgressEnrollment {
  const EnrollmentProgressEnrollment({
    required this.id,
    required this.studentId,
    required this.courseId,
    required this.status,
    required this.progressPercentage,
    required this.enrolledAt,
    required this.createdAt,
    required this.updatedAt,
    required this.lastAccessedAt,
  });

  final String id;
  final String studentId;
  final String courseId;
  final String status;
  final double progressPercentage;
  final DateTime? enrolledAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? lastAccessedAt;

  factory EnrollmentProgressEnrollment.fromJson(
    Map<String, dynamic> json,
  ) {
    return EnrollmentProgressEnrollment(
      id: json['id']?.toString() ?? '',
      studentId: json['studentId']?.toString() ?? '',
      courseId: _parseId(json['courseId']),
      status: json['status']?.toString() ?? '',
      progressPercentage: _parseDouble(json['progressPercentage']),
      enrolledAt: _parseDateTime(json['enrolledAt']),
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseDateTime(json['updatedAt']),
      lastAccessedAt: _parseDateTime(json['lastAccessedAt']),
    );
  }

  static String _parseId(dynamic value) {
    if (value is Map) {
      return value['id']?.toString() ?? '';
    }

    return value?.toString() ?? '';
  }

  static double _parseDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) {
      return null;
    }

    return DateTime.tryParse(value.toString());
  }
}

class EnrollmentProgressLesson {
  const EnrollmentProgressLesson({
    required this.id,
    required this.courseId,
    required this.section,
    required this.title,
    required this.lessonType,
    required this.durationMinutes,
    required this.order,
    required this.progress,
  });

  final String id;
  final String courseId;
  final EnrollmentProgressSection section;
  final String title;
  final String lessonType;
  final int durationMinutes;
  final int order;
  final EnrollmentLessonProgress? progress;

  factory EnrollmentProgressLesson.fromJson(
    Map<String, dynamic> json,
  ) {
    final rawSection = json['sectionId'];

    final sectionMap = rawSection is Map
        ? Map<String, dynamic>.from(rawSection)
        : <String, dynamic>{};

    final rawProgress = json['progress'];

    return EnrollmentProgressLesson(
      id: json['id']?.toString() ?? '',
      courseId: _parseId(json['courseId']),
      section: EnrollmentProgressSection.fromJson(sectionMap),
      title: json['title']?.toString() ?? '',
      lessonType: json['lessonType']?.toString() ?? '',
      durationMinutes: _parseInt(json['durationMinutes']),
      order: _parseInt(json['order']),
      progress: rawProgress is Map
          ? EnrollmentLessonProgress.fromJson(
              Map<String, dynamic>.from(rawProgress),
            )
          : null,
    );
  }

  static String _parseId(dynamic value) {
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
}

class EnrollmentProgressSection {
  const EnrollmentProgressSection({
    required this.id,
    required this.title,
    required this.order,
  });

  final String id;
  final String title;
  final int order;

  factory EnrollmentProgressSection.fromJson(
    Map<String, dynamic> json,
  ) {
    return EnrollmentProgressSection(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      order: _parseInt(json['order']),
    );
  }

  static int _parseInt(dynamic value) {
    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class EnrollmentLessonProgress {
  const EnrollmentLessonProgress({
    required this.status,
    required this.startedAt,
    required this.completedAt,
    required this.lastAccessedAt,
  });

  final String status;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? lastAccessedAt;

  factory EnrollmentLessonProgress.fromJson(
    Map<String, dynamic> json,
  ) {
    return EnrollmentLessonProgress(
      status: json['status']?.toString() ?? '',
      startedAt: _parseDateTime(json['startedAt']),
      completedAt: _parseDateTime(json['completedAt']),
      lastAccessedAt: _parseDateTime(json['lastAccessedAt']),
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) {
      return null;
    }

    return DateTime.tryParse(value.toString());
  }
}
