class CourseLesson {
  const CourseLesson({
    required this.id,
    required this.courseId,
    required this.sectionId,
    required this.title,
    required this.description,
    required this.lessonType,
    required this.durationMinutes,
    required this.order,
    required this.isPreview,
    required this.isPublished,
    required this.documentName,
    required this.documentUrl,
    required this.textContent,
    required this.videoUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String courseId;
  final String sectionId;
  final String title;
  final String description;
  final String lessonType;
  final int durationMinutes;
  final int order;
  final bool isPreview;
  final bool isPublished;

  final String? documentName;
  final String? documentUrl;
  final String? textContent;
  final String? videoUrl;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isText => lessonType == 'TEXT';

  bool get isVideo => lessonType == 'VIDEO';

  bool get isDocument => lessonType == 'DOCUMENT';

  factory CourseLesson.fromJson(Map<String, dynamic> json) {
    return CourseLesson(
      id: json['id'] as String? ?? '',
      courseId: json['courseId'] as String? ?? '',
      sectionId: json['sectionId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      lessonType: json['lessonType'] as String? ?? '',
      durationMinutes: _parseInt(json['durationMinutes']),
      order: _parseInt(json['order']),
      isPreview: json['isPreview'] as bool? ?? false,
      isPublished: json['isPublished'] as bool? ?? false,
      documentName: _parseNullableString(
        json['documentName'],
      ),
      documentUrl: _parseNullableString(
        json['documentUrl'],
      ),
      textContent: _parseNullableString(
        json['textContent'],
      ),
      videoUrl: _parseNullableString(
        json['videoUrl'],
      ),
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) {
      return value;
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String? _parseNullableString(dynamic value) {
    if (value is! String || value.isEmpty) {
      return null;
    }

    return value;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value is! String || value.isEmpty) {
      return null;
    }

    return DateTime.tryParse(value);
  }
}
