class CourseSection {
  const CourseSection({
    required this.id,
    required this.courseId,
    required this.title,
    required this.description,
    required this.order,
    required this.isPublished,
    required this.createdAt,
    required this.updatedAt,
    required this.lessonCount,
  });

  final String id;
  final String courseId;
  final String title;
  final String description;
  final int order;
  final bool isPublished;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int lessonCount;

  factory CourseSection.fromJson(Map<String, dynamic> json) {
    return CourseSection(
      id: json['id'] as String? ?? '',
      courseId: json['courseId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      order: _parseInt(json['order']),
      isPublished: json['isPublished'] as bool? ?? false,
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
      lessonCount: _parseInt(json['lessonCount']),
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) {
      return value;
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
