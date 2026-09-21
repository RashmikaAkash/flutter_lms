import '../models/course/course_category.dart';
import '../models/pagination.dart';

class CourseCategoryPage {
  const CourseCategoryPage({
    required this.categories,
    required this.pagination,
  });

  final List<CourseCategory> categories;
  final Pagination pagination;

  factory CourseCategoryPage.fromJson(Map<String, dynamic> json) {
    final rawCategories = json['categories'];

    final categories = rawCategories is List
        ? rawCategories
            .whereType<Map<String, dynamic>>()
            .map(CourseCategory.fromJson)
            .toList()
        : <CourseCategory>[];

    final rawPagination = json['pagination'];

    return CourseCategoryPage(
      categories: categories,
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
