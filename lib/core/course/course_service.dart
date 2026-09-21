import '../models/course/course.dart';
import '../network/api_client.dart';
import 'course_category_page.dart';
import 'course_page.dart';
import '../models/course/course_section.dart';
import 'course_section_page.dart';
import 'course_enrollment_result.dart';
import 'course_enrollment_page.dart';
import 'course_lesson_page.dart';
import '../models/course/course_lesson.dart';
import '../models/course/lesson_progress.dart';
import 'lesson_completion_result.dart';
import '../models/course/enrollment_progress.dart';
import '../errors/api_exception.dart';

class CourseService {
  CourseService({
    ApiClient? apiClient,
  }) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<LessonProgress> startLesson(
    String lessonId,
  ) async {
    final response = await _apiClient.patch(
      '/api/v1/lessons/$lessonId/start',
      requiresAuth: true,
    );

    final responseData = response.data;

    if (responseData is! Map<String, dynamic>) {
      throw Exception('Invalid start lesson response.');
    }

    final data = responseData['data'];

    if (data is! Map<String, dynamic>) {
      throw Exception('Invalid start lesson data.');
    }

    final lessonProgress = data['lessonProgress'];

    if (lessonProgress is! Map<String, dynamic>) {
      throw Exception('Lesson progress not found.');
    }

    return LessonProgress.fromJson(
      lessonProgress,
    );
  }

  Future<EnrollmentProgress> getEnrollmentProgress(
    String enrollmentId,
  ) async {
    final response = await _apiClient.get(
      '/api/v1/enrollments/$enrollmentId/progress',
      requiresAuth: true,
    );

    final responseData = response.data;

    if (responseData is! Map<String, dynamic>) {
      throw const ApiException(
        message: 'Invalid enrollment progress response',
      );
    }

    final data = responseData['data'];

    if (data is! Map<String, dynamic>) {
      throw const ApiException(
        message: 'Enrollment progress data is unavailable',
      );
    }

    return EnrollmentProgress.fromJson(
      Map<String, dynamic>.from(data),
    );
  }

  Future<LessonCompletionResult> completeLesson(
    String lessonId,
  ) async {
    final response = await _apiClient.patch(
      '/api/v1/lessons/$lessonId/complete',
      requiresAuth: true,
    );

    final responseData = response.data;

    if (responseData is! Map<String, dynamic>) {
      throw Exception('Invalid complete lesson response.');
    }

    final data = responseData['data'];

    if (data is! Map<String, dynamic>) {
      throw Exception('Invalid complete lesson data.');
    }

    return LessonCompletionResult.fromJson(data);
  }

  Future<List<CourseLesson>> getSectionLessons(
    String sectionId,
  ) async {
    final response = await _apiClient.get(
      '/api/v1/sections/$sectionId/lessons',
      requiresAuth: true,
    );

    final responseData = response.data;

    if (responseData is! Map<String, dynamic>) {
      throw Exception('Invalid lessons response.');
    }

    final data = responseData['data'];

    if (data is! Map<String, dynamic>) {
      throw Exception('Invalid lessons data.');
    }

    final lessons = CourseLessonPage.fromJson(data).lessons;

    lessons.sort(
      (a, b) => a.order.compareTo(b.order),
    );

    return lessons;
  }

  Future<CourseLesson> getLesson(
    String lessonId,
  ) async {
    final response = await _apiClient.get(
      '/api/v1/lessons/$lessonId',
      requiresAuth: true,
    );

    final responseData = response.data;

    if (responseData is! Map<String, dynamic>) {
      throw Exception('Invalid lesson response.');
    }

    final data = responseData['data'];

    if (data is! Map<String, dynamic>) {
      throw Exception('Invalid lesson data.');
    }

    final lesson = data['lesson'];

    if (lesson is! Map<String, dynamic>) {
      throw Exception('Lesson details not found.');
    }

    return CourseLesson.fromJson(lesson);
  }

  Future<CourseEnrollmentPage> getMyEnrollments({
    int page = 1,
    int limit = 20,
    String? status,
  }) async {
    final queryParameters = <String, dynamic>{
      'page': page,
      'limit': limit,
    };

    if (status != null && status.isNotEmpty) {
      queryParameters['status'] = status;
    }

    final response = await _apiClient.get(
      '/api/v1/enrollments/me',
      queryParameters: queryParameters,
      requiresAuth: true,
    );

    final responseData = response.data;

    if (responseData is! Map<String, dynamic>) {
      throw Exception('Invalid enrollments response.');
    }

    final data = responseData['data'];

    if (data is! Map<String, dynamic>) {
      throw Exception('Invalid enrollments data.');
    }

    return CourseEnrollmentPage.fromJson(data);
  }

  Future<CourseEnrollmentResult> enrollInCourse(
    String courseId,
  ) async {
    final response = await _apiClient.post(
      '/api/v1/courses/$courseId/enroll',
      requiresAuth: true,
    );

    final responseData = response.data;

    if (responseData is! Map<String, dynamic>) {
      throw Exception('Invalid enrollment response.');
    }

    final data = responseData['data'];

    if (data is! Map<String, dynamic>) {
      throw Exception('Invalid enrollment data.');
    }

    return CourseEnrollmentResult.fromJson(data);
  }

  Future<List<CourseSection>> getCourseSections(
    String courseId,
  ) async {
    final response = await _apiClient.get(
      '/api/v1/courses/$courseId/sections',
      requiresAuth: true,
    );

    final responseData = response.data;

    if (responseData is! Map<String, dynamic>) {
      throw Exception('Invalid course sections response.');
    }

    final data = responseData['data'];

    if (data is! Map<String, dynamic>) {
      throw Exception('Invalid course sections data.');
    }

    return CourseSectionPage.fromJson(data).sections;
  }

  Future<CourseCategoryPage> getActiveCategories({
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _apiClient.get(
      '/api/v1/categories',
      queryParameters: {
        'page': page,
        'limit': limit,
        'activeOnly': true,
      },
      requiresAuth: true,
    );

    final responseData = response.data;

    if (responseData is! Map<String, dynamic>) {
      throw Exception('Invalid categories response.');
    }

    final data = responseData['data'];

    if (data is! Map<String, dynamic>) {
      throw Exception('Invalid categories data.');
    }

    return CourseCategoryPage.fromJson(data);
  }

  Future<CoursePage> getPublishedCourses({
    int page = 1,
    int limit = 20,
    String? search,
    String? level,
  }) async {
    final queryParameters = <String, dynamic>{
      'page': page,
      'limit': limit,
    };

    if (search != null && search.trim().isNotEmpty) {
      queryParameters['search'] = search.trim();
    }

    if (level != null && level.trim().isNotEmpty) {
      queryParameters['level'] = level.trim();
    }

    final response = await _apiClient.get(
      '/api/v1/courses',
      queryParameters: queryParameters,
      requiresAuth: true,
    );

    final responseData = response.data;

    if (responseData is! Map<String, dynamic>) {
      throw Exception('Invalid courses response.');
    }

    final data = responseData['data'];

    if (data is! Map<String, dynamic>) {
      throw Exception('Invalid courses data.');
    }

    return CoursePage.fromJson(data);
  }

  Future<Course> getPublishedCourse(String courseId) async {
    final response = await _apiClient.get(
      '/api/v1/courses/$courseId',
      requiresAuth: true,
    );

    final responseData = response.data;

    if (responseData is! Map<String, dynamic>) {
      throw Exception('Invalid course response.');
    }

    final data = responseData['data'];

    if (data is! Map<String, dynamic>) {
      throw Exception('Invalid course data.');
    }

    final course = data['course'];

    if (course is! Map<String, dynamic>) {
      throw Exception('Course details not found.');
    }

    return Course.fromJson(course);
  }
}
