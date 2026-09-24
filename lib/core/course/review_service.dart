import '../errors/api_exception.dart';
import '../models/course/course_review.dart';
import '../models/course/course_review_page.dart';
import '../network/api_client.dart';

class ReviewService {
  ReviewService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<CourseReviewPage> getCourseReviews(
    String courseId, {
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _apiClient.get(
      '/api/v1/courses/$courseId/reviews',
      queryParameters: {'page': page, 'limit': limit},
      requiresAuth: true,
    );
    final data = _data(response.data, 'course reviews');
    return CourseReviewPage.fromJson(Map<String, dynamic>.from(data));
  }

  Future<CourseReview> createReview({
    required String courseId,
    required int rating,
    String? comment,
  }) async {
    final body = <String, dynamic>{'rating': rating};
    if (comment != null && comment.trim().isNotEmpty) {
      body['comment'] = comment.trim();
    }
    final response = await _apiClient.post(
      '/api/v1/courses/$courseId/reviews',
      data: body,
      requiresAuth: true,
    );
    return _reviewFrom(response.data, 'created');
  }

  Future<CourseReview> updateReview({
    required String reviewId,
    required int rating,
    String? comment,
  }) async {
    final response = await _apiClient.patch(
      '/api/v1/reviews/$reviewId',
      data: {'rating': rating, 'comment': comment?.trim()},
      requiresAuth: true,
    );
    return _reviewFrom(response.data, 'updated');
  }

  Future<void> deleteReview(String reviewId) async {
    await _apiClient.delete(
      '/api/v1/reviews/$reviewId',
      requiresAuth: true,
    );
  }

  CourseReview _reviewFrom(dynamic response, String operation) {
    final data = _data(response, 'review');
    final review = data['review'];
    if (review is! Map) {
      throw ApiException(message: 'Review $operation response is invalid');
    }
    return CourseReview.fromJson(Map<String, dynamic>.from(review));
  }

  Map<String, dynamic> _data(dynamic response, String label) {
    if (response is! Map<String, dynamic>) {
      throw ApiException(message: 'Invalid $label response');
    }
    final data = response['data'];
    if (data is! Map<String, dynamic>) {
      throw ApiException(message: '$label data is unavailable');
    }
    return data;
  }
}
