import '../models/course/course_section.dart';

class CourseSectionPage {
  const CourseSectionPage({
    required this.sections,
  });

  final List<CourseSection> sections;

  factory CourseSectionPage.fromJson(Map<String, dynamic> json) {
    final rawSections = json['sections'];

    final sections = rawSections is List
        ? rawSections
            .whereType<Map<String, dynamic>>()
            .map(CourseSection.fromJson)
            .toList()
        : <CourseSection>[];

    return CourseSectionPage(
      sections: sections,
    );
  }
}
