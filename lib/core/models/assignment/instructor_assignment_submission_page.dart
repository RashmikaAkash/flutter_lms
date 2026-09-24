import 'instructor_assignment_submission.dart';

class InstructorAssignmentSubmissionPage {
  const InstructorAssignmentSubmissionPage({
    required this.submissions,
    required this.pagination,
  });

  final List<InstructorAssignmentSubmission> submissions;
  final InstructorSubmissionPagination pagination;

  factory InstructorAssignmentSubmissionPage.fromJson(
    Map<String, dynamic> json,
  ) {
    final rawSubmissions = json['submissions'];
    final rawPagination = json['pagination'];

    return InstructorAssignmentSubmissionPage(
      submissions: rawSubmissions is List
          ? rawSubmissions
              .whereType<Map>()
              .map(
                (item) => InstructorAssignmentSubmission.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList()
          : <InstructorAssignmentSubmission>[],
      pagination: rawPagination is Map
          ? InstructorSubmissionPagination.fromJson(
              Map<String, dynamic>.from(rawPagination),
            )
          : const InstructorSubmissionPagination(
              page: 1,
              limit: 20,
              totalItems: 0,
              totalPages: 1,
              hasNextPage: false,
              hasPreviousPage: false,
            ),
    );
  }
}

class InstructorSubmissionPagination {
  const InstructorSubmissionPagination({
    required this.page,
    required this.limit,
    required this.totalItems,
    required this.totalPages,
    required this.hasNextPage,
    required this.hasPreviousPage,
  });

  final int page;
  final int limit;
  final int totalItems;
  final int totalPages;
  final bool hasNextPage;
  final bool hasPreviousPage;

  factory InstructorSubmissionPagination.fromJson(
    Map<String, dynamic> json,
  ) {
    return InstructorSubmissionPagination(
      page: _parseInt(json['page']),
      limit: _parseInt(json['limit']),
      totalItems: _parseInt(json['totalItems']),
      totalPages: _parseInt(json['totalPages']),
      hasNextPage: json['hasNextPage'] as bool? ?? false,
      hasPreviousPage: json['hasPreviousPage'] as bool? ?? false,
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
