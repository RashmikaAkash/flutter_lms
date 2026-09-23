import '../models/pagination.dart';
import '../models/quiz/quiz_attempt.dart';

class QuizAttemptPage {
  const QuizAttemptPage({
    required this.attempts,
    required this.pagination,
  });

  final List<QuizAttempt> attempts;
  final Pagination pagination;

  factory QuizAttemptPage.fromJson(
    Map<String, dynamic> json,
  ) {
    final rawAttempts = json['attempts'];

    final attempts = rawAttempts is List
        ? rawAttempts
            .whereType<Map>()
            .map(
              (attempt) => QuizAttempt.fromJson(
                Map<String, dynamic>.from(attempt),
              ),
            )
            .toList()
        : <QuizAttempt>[];

    final rawPagination = json['pagination'];

    final pagination = rawPagination is Map
        ? Pagination.fromJson(
            Map<String, dynamic>.from(rawPagination),
          )
        : const Pagination(
            page: 1,
            limit: 20,
            totalItems: 0,
            totalPages: 0,
            hasNextPage: false,
            hasPreviousPage: false,
          );

    return QuizAttemptPage(
      attempts: attempts,
      pagination: pagination,
    );
  }
}
