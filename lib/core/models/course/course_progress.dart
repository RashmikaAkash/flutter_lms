class CourseProgress {
  const CourseProgress({
    required this.progressPercentage,
    required this.enrollmentStatus,
    required this.totalLessons,
    required this.completedLessons,
  });

  final double progressPercentage;
  final String enrollmentStatus;
  final int totalLessons;
  final int completedLessons;

  factory CourseProgress.fromJson(
    Map<String, dynamic> json,
  ) {
    return CourseProgress(
      progressPercentage: _parseDouble(
        json['progressPercentage'],
      ),
      enrollmentStatus: json['enrollmentStatus'] as String? ?? '',
      totalLessons: _parseInt(
        json['totalLessons'],
      ),
      completedLessons: _parseInt(
        json['completedLessons'],
      ),
    );
  }

  static double _parseDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int _parseInt(dynamic value) {
    if (value is int) {
      return value;
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
