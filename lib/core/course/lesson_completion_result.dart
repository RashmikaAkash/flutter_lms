import '../models/course/course_progress.dart';
import '../models/course/lesson_progress.dart';

class LessonCompletionResult {
  const LessonCompletionResult({
    required this.lessonProgress,
    required this.courseProgress,
  });

  final LessonProgress lessonProgress;
  final CourseProgress courseProgress;

  factory LessonCompletionResult.fromJson(
    Map<String, dynamic> json,
  ) {
    final rawLessonProgress = json['lessonProgress'];
    final rawCourseProgress = json['courseProgress'];

    if (rawLessonProgress is! Map<String, dynamic>) {
      throw Exception('Lesson progress data not found.');
    }

    if (rawCourseProgress is! Map<String, dynamic>) {
      throw Exception('Course progress data not found.');
    }

    return LessonCompletionResult(
      lessonProgress: LessonProgress.fromJson(
        rawLessonProgress,
      ),
      courseProgress: CourseProgress.fromJson(
        rawCourseProgress,
      ),
    );
  }
}
