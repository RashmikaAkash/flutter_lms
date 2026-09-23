class QuizAttempt {
  const QuizAttempt({
    required this.quizId,
    required this.studentId,
    required this.enrollmentId,
    required this.score,
    required this.totalMarks,
    required this.percentage,
    required this.passed,
    required this.status,
    required this.attemptNumber,
    required this.id,
    required this.answers,
    required this.startedAt,
    required this.createdAt,
    required this.updatedAt,
    required this.submittedAt,
  });

  final String quizId;
  final String studentId;
  final String enrollmentId;
  final double score;
  final double totalMarks;
  final double percentage;
  final bool passed;
  final String status;
  final int attemptNumber;
  final String id;
  final List<dynamic> answers;
  final DateTime? startedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? submittedAt;

  bool get isInProgress => status == 'IN_PROGRESS';

  factory QuizAttempt.fromJson(
    Map<String, dynamic> json,
  ) {
    return QuizAttempt(
      submittedAt: _parseDate(json['submittedAt']),
      quizId: json['quizId'] as String? ?? '',
      studentId: json['studentId'] as String? ?? '',
      enrollmentId: json['enrollmentId'] as String? ?? '',
      score: _parseDouble(json['score']),
      totalMarks: _parseDouble(json['totalMarks']),
      percentage: _parseDouble(json['percentage']),
      passed: json['passed'] == true,
      status: json['status'] as String? ?? '',
      attemptNumber: _parseInt(json['attemptNumber']),
      id: json['id'] as String? ?? '',
      answers: json['answers'] is List
          ? List<dynamic>.from(json['answers'] as List)
          : const [],
      startedAt: _parseDate(json['startedAt']),
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
