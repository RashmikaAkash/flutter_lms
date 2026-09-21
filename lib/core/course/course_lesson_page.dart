import '../models/course/course_lesson.dart';

class CourseLessonPage {
  const CourseLessonPage({
    required this.lessons,
  });

  final List<CourseLesson> lessons;

  factory CourseLessonPage.fromJson(
    Map<String, dynamic> json,
  ) {
    final rawLessons = json['lessons'];

    final lessons = rawLessons is List
        ? rawLessons
            .whereType<Map<String, dynamic>>()
            .map(CourseLesson.fromJson)
            .toList()
        : <CourseLesson>[];

    return CourseLessonPage(
      lessons: lessons,
    );
  }
}
