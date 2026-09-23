import 'quiz.dart';

class QuizDetail {
  const QuizDetail({
    required this.quiz,
    required this.questions,
  });

  final Quiz quiz;
  final List<QuizQuestion> questions;

  factory QuizDetail.fromJson(
    Map<String, dynamic> json,
  ) {
    final rawQuiz = json['quiz'];

    final quizMap = rawQuiz is Map
        ? Map<String, dynamic>.from(rawQuiz)
        : <String, dynamic>{};

    final rawQuestions = json['questions'];

    return QuizDetail(
      quiz: Quiz.fromJson(quizMap),
      questions: rawQuestions is List
          ? rawQuestions
              .whereType<Map>()
              .map(
                (item) => QuizQuestion.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList()
          : <QuizQuestion>[],
    );
  }
}

class QuizQuestion {
  const QuizQuestion({
    required this.id,
    required this.questionText,
    required this.questionType,
    required this.options,
    required this.marks,
    required this.order,
  });

  final String id;
  final String questionText;
  final String questionType;
  final List<QuizOption> options;
  final int marks;
  final int order;

  factory QuizQuestion.fromJson(
    Map<String, dynamic> json,
  ) {
    final rawOptions = json['options'];

    return QuizQuestion(
      id: json['id']?.toString() ?? '',
      questionText: json['questionText']?.toString() ?? '',
      questionType: json['questionType']?.toString() ?? '',
      options: rawOptions is List
          ? rawOptions
              .whereType<Map>()
              .map(
                (item) => QuizOption.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList()
          : <QuizOption>[],
      marks: _parseInt(json['marks']),
      order: _parseInt(json['order']),
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

class QuizOption {
  const QuizOption({
    required this.id,
    required this.text,
  });

  final String id;
  final String text;

  factory QuizOption.fromJson(
    Map<String, dynamic> json,
  ) {
    return QuizOption(
      id: json['id']?.toString() ?? '',
      text: json['text']?.toString() ?? '',
    );
  }
}
