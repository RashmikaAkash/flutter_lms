class AssignmentSubmission {
  const AssignmentSubmission({
    required this.id,
    required this.assignmentId,
    required this.studentId,
    required this.enrollmentId,
    required this.submittedAt,
    required this.textAnswer,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.fileUrl,
    this.fileName,

  });

  final String id;
  final String assignmentId;
  final String studentId;
  final String enrollmentId;
  final DateTime? submittedAt;
  final String textAnswer;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? fileUrl;
  final String? fileName;

  bool get isSubmitted => status == 'SUBMITTED';

  factory AssignmentSubmission.fromJson(
    Map<String, dynamic> json,
  ) {
    return AssignmentSubmission(
      id: json['id']?.toString() ?? '',
      assignmentId: json['assignmentId']?.toString() ?? '',
      studentId: json['studentId']?.toString() ?? '',
      enrollmentId: json['enrollmentId']?.toString() ?? '',
      submittedAt: _parseDate(json['submittedAt']),
      textAnswer: json['textAnswer']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
      fileUrl: json['fileUrl'] as String?,
      fileName: json['fileName'] as String?,
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value is! String || value.isEmpty) {
      return null;
    }

    return DateTime.tryParse(value);
  }
}
