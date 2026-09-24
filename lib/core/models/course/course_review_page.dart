import '../pagination.dart';
import 'course_review.dart';

class CourseReviewPage {
  const CourseReviewPage({
    required this.reviews,
    required this.pagination,
  });

  final List<CourseReview> reviews;
  final Pagination pagination;

  factory CourseReviewPage.fromJson(Map<String, dynamic> json) {
    final rawReviews = json['reviews'];
    final reviews = rawReviews is List
        ? rawReviews
            .whereType<Map>()
            .map(
              (item) => CourseReview.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList()
        : const <CourseReview>[];
    final rawPagination = json['pagination'];

    return CourseReviewPage(
      reviews: reviews,
      pagination: rawPagination is Map
          ? Pagination.fromJson(Map<String, dynamic>.from(rawPagination))
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
