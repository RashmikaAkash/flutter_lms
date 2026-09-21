import 'course_category_summary.dart';
import 'course_instructor.dart';

class Course {
  const Course({
    required this.id,
    required this.instructor,
    required this.category,
    required this.title,
    required this.slug,
    required this.shortDescription,
    required this.description,
    required this.level,
    required this.language,
    required this.isFree,
    required this.price,
    required this.requirements,
    required this.learningOutcomes,
    required this.targetAudience,
    required this.status,
    required this.averageRating,
    required this.reviewCount,
    required this.totalEnrollments,
    required this.createdAt,
    required this.updatedAt,
    required this.thumbnailUrl,
    required this.publishedAt,
  });

  final String id;
  final CourseInstructor instructor;
  final CourseCategorySummary category;
  final String title;
  final String slug;
  final String shortDescription;
  final String description;
  final String level;
  final String language;
  final bool isFree;
  final double price;
  final List<String> requirements;
  final List<String> learningOutcomes;
  final List<String> targetAudience;
  final String status;
  final double averageRating;
  final int reviewCount;
  final int totalEnrollments;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? thumbnailUrl;
  final DateTime? publishedAt;

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id'] as String? ?? '',
      instructor: _parseInstructor(json['instructorId']),
      category: _parseCategory(json['categoryId']),
      title: json['title'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      shortDescription: json['shortDescription'] as String? ?? '',
      description: json['description'] as String? ?? '',
      level: json['level'] as String? ?? '',
      language: json['language'] as String? ?? '',
      isFree: json['isFree'] as bool? ?? false,
      price: _parseDouble(json['price']),
      requirements: _parseStringList(json['requirements']),
      learningOutcomes: _parseStringList(json['learningOutcomes']),
      targetAudience: _parseStringList(json['targetAudience']),
      status: json['status'] as String? ?? '',
      averageRating: _parseDouble(json['averageRating']),
      reviewCount: _parseInt(json['reviewCount']),
      totalEnrollments: _parseInt(json['totalEnrollments']),
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
      thumbnailUrl: _parseNullableString(json['thumbnailUrl']),
      publishedAt: _parseDate(json['publishedAt']),
    );
  }

  static CourseInstructor _parseInstructor(dynamic value) {
    if (value is Map<String, dynamic>) {
      return CourseInstructor.fromJson(value);
    }

    return const CourseInstructor(
      id: '',
      firstName: '',
      lastName: '',
      bio: '',
      profileImageUrl: null,
    );
  }

  static CourseCategorySummary _parseCategory(dynamic value) {
    if (value is Map<String, dynamic>) {
      return CourseCategorySummary.fromJson(value);
    }

    return const CourseCategorySummary(
      id: '',
      name: '',
      slug: '',
      isActive: false,
    );
  }

  static List<String> _parseStringList(dynamic value) {
    if (value is! List) {
      return const [];
    }

    return value.whereType<String>().toList();
  }

  static int _parseInt(dynamic value) {
    if (value is int) {
      return value;
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double _parseDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value is! String || value.isEmpty) {
      return null;
    }

    return DateTime.tryParse(value);
  }

  static String? _parseNullableString(dynamic value) {
    if (value is! String || value.isEmpty) {
      return null;
    }

    return value;
  }
}
