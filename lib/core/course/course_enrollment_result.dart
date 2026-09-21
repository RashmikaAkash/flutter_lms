import '../models/course/course_enrollment.dart';

class CourseEnrollmentResult {
  const CourseEnrollmentResult({
    required this.enrollment,
  });

  final CourseEnrollment enrollment;

  factory CourseEnrollmentResult.fromJson(
    Map<String, dynamic> json,
  ) {
    final enrollment = json['enrollment'];

    if (enrollment is! Map<String, dynamic>) {
      throw Exception('Enrollment data not found.');
    }

    return CourseEnrollmentResult(
      enrollment: CourseEnrollment.fromJson(enrollment),
    );
  }
}
