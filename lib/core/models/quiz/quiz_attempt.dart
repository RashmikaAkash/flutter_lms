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
    this.studentFirstName = '',
    this.studentLastName = '',
    this.studentEmail = '',
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
  final List<QuizAttemptAnswer> answers;
  final DateTime? startedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? submittedAt;

  final String studentFirstName;
  final String studentLastName;
  final String studentEmail;

  bool get isInProgress => status == 'IN_PROGRESS';

  String get studentDisplayName {
    final fullName = '$studentFirstName $studentLastName'.trim();

    if (fullName.isNotEmpty) {
      return fullName;
    }

    return studentId.isEmpty ? 'Unknown student' : studentId;
  }

  factory QuizAttempt.fromJson(
    Map<String, dynamic> json,
  ) {
    final rawStudentId = json['studentId'];

    String studentId = '';
    String studentFirstName = '';
    String studentLastName = '';
    String studentEmail = '';

    if (rawStudentId is Map) {
      final studentMap = Map<String, dynamic>.from(rawStudentId);

      studentId = studentMap['id']?.toString() ?? '';
      studentFirstName = studentMap['firstName']?.toString() ?? '';
      studentLastName = studentMap['lastName']?.toString() ?? '';
      studentEmail = studentMap['email']?.toString() ?? '';
    } else {
      studentId = rawStudentId?.toString() ?? '';
    }

    return QuizAttempt(
      submittedAt: _parseDate(json['submittedAt']),
      quizId: json['quizId']?.toString() ?? '',
      studentId: studentId,
      enrollmentId: json['enrollmentId']?.toString() ?? '',
      score: _parseDouble(json['score']),
      totalMarks: _parseDouble(json['totalMarks']),
      percentage: _parseDouble(json['percentage']),
      passed: json['passed'] == true,
      status: json['status']?.toString() ?? '',
      attemptNumber: _parseInt(json['attemptNumber']),
      id: json['id']?.toString() ?? '',
      answers: json['answers'] is List
          ? (json['answers'] as List)
              .whereType<Map>()
              .map(
                (item) => QuizAttemptAnswer.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList()
          : const [],
      startedAt: _parseDate(json['startedAt']),
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
      studentFirstName: studentFirstName,
      studentLastName: studentLastName,
      studentEmail: studentEmail,
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

class QuizAttemptAnswer {
  const QuizAttemptAnswer({
    required this.questionId,
    required this.selectedOptionIds,
  });

  final String questionId;
  final List<String> selectedOptionIds;

  factory QuizAttemptAnswer.fromJson(
    Map<String, dynamic> json,
  ) {
    final rawSelectedOptionIds = json['selectedOptionIds'];

    return QuizAttemptAnswer(
      questionId: json['questionId']?.toString() ?? '',
      selectedOptionIds: rawSelectedOptionIds is List
          ? rawSelectedOptionIds.map((item) => item.toString()).toList()
          : const [],
    );
  }
}
