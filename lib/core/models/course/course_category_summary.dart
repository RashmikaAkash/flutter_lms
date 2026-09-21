class CourseCategorySummary {
  const CourseCategorySummary({
    required this.id,
    required this.name,
    required this.slug,
    required this.isActive,
  });

  final String id;
  final String name;
  final String slug;
  final bool isActive;

  factory CourseCategorySummary.fromJson(Map<String, dynamic> json) {
    return CourseCategorySummary(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      isActive: json['isActive'] as bool? ?? false,
    );
  }
}
