class Quiz {
  const Quiz({
    required this.id,
    required this.courseId,
    required this.section,
    required this.title,
    required this.description,
    required this.passingScore,
    required this.timeLimitMinutes,
    required this.maxAttempts,
    required this.isPublished,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String courseId;
  final QuizSectionSummary section;
  final String title;
  final String description;
  final double passingScore;
  final int timeLimitMinutes;
  final int maxAttempts;
  final bool isPublished;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory Quiz.fromJson(
    Map<String, dynamic> json,
  ) {
    final rawSection = json['sectionId'];

    final sectionMap = rawSection is Map
        ? Map<String, dynamic>.from(rawSection)
        : <String, dynamic>{
            'id': rawSection?.toString() ?? '',
          };

    return Quiz(
      id: json['id']?.toString() ?? '',
      courseId: json['courseId']?.toString() ?? '',
      section: QuizSectionSummary.fromJson(sectionMap),
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      passingScore: _parseDouble(json['passingScore']),
      timeLimitMinutes: _parseInt(json['timeLimitMinutes']),
      maxAttempts: _parseInt(json['maxAttempts']),
      isPublished: json['isPublished'] as bool? ?? false,
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

  static int _parseInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
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
}

class QuizSectionSummary {
  const QuizSectionSummary({
    required this.id,
    required this.title,
    required this.order,
    required this.isPublished,
  });

  final String id;
  final String title;
  final int order;
  final bool isPublished;

  factory QuizSectionSummary.fromJson(
    Map<String, dynamic> json,
  ) {
    return QuizSectionSummary(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      order: _parseInt(json['order']),
      isPublished: json['isPublished'] as bool? ?? false,
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }
}
