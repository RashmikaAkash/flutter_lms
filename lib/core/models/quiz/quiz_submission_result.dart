import 'quiz_attempt.dart';

class QuizSubmissionResult {
  const QuizSubmissionResult({
    required this.attempt,
    required this.score,
    required this.totalMarks,
    required this.percentage,
    required this.passed,
    required this.passingScore,
    required this.timedOut,
  });

  final QuizAttempt attempt;
  final double score;
  final double totalMarks;
  final double percentage;
  final bool passed;
  final double passingScore;
  final bool timedOut;

  factory QuizSubmissionResult.fromJson(
      Map<String, dynamic> json,
      ) {
    final attemptJson = json['attempt'];
    final resultJson = json['result'];

    if (attemptJson is! Map) {
      throw const FormatException(
        'Submitted attempt is unavailable.',
      );
    }

    if (resultJson is! Map) {
      throw const FormatException(
        'Quiz submission result is unavailable.',
      );
    }

    final attempt = QuizAttempt.fromJson(
      Map<String, dynamic>.from(attemptJson),
    );

    final result = Map<String, dynamic>.from(resultJson);

    return QuizSubmissionResult(
      attempt: attempt,
      score: _parseDouble(result['score']),
      totalMarks: _parseDouble(result['totalMarks']),
      percentage: _parseDouble(result['percentage']),
      passed: result['passed'] == true,
      passingScore: _parseDouble(result['passingScore']),
      timedOut: result['timedOut'] == true,
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
}