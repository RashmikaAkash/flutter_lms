import '../models/course/course_enrollment.dart';
import '../models/pagination.dart';

class CourseEnrollmentPage {
  const CourseEnrollmentPage({
    required this.enrollments,
    required this.pagination,
  });

  final List<CourseEnrollment> enrollments;
  final Pagination pagination;

  factory CourseEnrollmentPage.fromJson(
    Map<String, dynamic> json,
  ) {
    final rawEnrollments = json['enrollments'];

    final enrollments = <CourseEnrollment>[];

    if (rawEnrollments is List) {
      for (final item in rawEnrollments) {
        if (item is Map) {
          enrollments.add(
            CourseEnrollment.fromJson(
              Map<String, dynamic>.from(item),
            ),
          );
        }
      }
    }

    final rawPagination = json['pagination'];

    return CourseEnrollmentPage(
      enrollments: enrollments,
      pagination: rawPagination is Map
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
            ),
    );
  }
}
