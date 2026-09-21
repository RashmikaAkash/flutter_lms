import '../models/course/course.dart';
import '../models/pagination.dart';

class CoursePage {
  const CoursePage({
    required this.courses,
    required this.pagination,
  });

  final List<Course> courses;
  final Pagination pagination;

  factory CoursePage.fromJson(Map<String, dynamic> json) {
    final rawCourses = json['courses'];

    final courses = rawCourses is List
        ? rawCourses
            .whereType<Map<String, dynamic>>()
            .map(Course.fromJson)
            .toList()
        : <Course>[];

    final rawPagination = json['pagination'];

    return CoursePage(
      courses: courses,
      pagination: rawPagination is Map<String, dynamic>
          ? Pagination.fromJson(rawPagination)
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
