class InstructorAssignmentSubmission {
  const InstructorAssignmentSubmission({
    required this.id,
    required this.assignmentId,
    required this.student,
    required this.enrollmentId,
    required this.submittedAt,
    required this.textAnswer,
    required this.status,
    this.fileUrl,
    this.fileName,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String assignmentId;
  final InstructorSubmissionStudent student;
  final String enrollmentId;
  final DateTime submittedAt;
  final String textAnswer;
  final String status;
  final String? fileUrl;
  final String? fileName;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isGraded => status == 'GRADED';

  factory InstructorAssignmentSubmission.fromJson(
      Map<String, dynamic> json,
      ) {
    final rawStudent = json['studentId'];

    final studentMap = rawStudent is Map
        ? Map<String, dynamic>.from(rawStudent)
        : <String, dynamic>{};

    return InstructorAssignmentSubmission(
      id: json['id']?.toString() ?? '',
      assignmentId: json['assignmentId']?.toString() ?? '',
      student: InstructorSubmissionStudent.fromJson(studentMap),
      enrollmentId: json['enrollmentId']?.toString() ?? '',
      submittedAt: DateTime.parse(
        json['submittedAt'] as String,
      ),
      textAnswer: json['textAnswer']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      fileUrl: json['fileUrl']?.toString(),
      fileName: json['fileName']?.toString(),
      createdAt: DateTime.parse(
        json['createdAt'] as String,
      ),
      updatedAt: DateTime.parse(
        json['updatedAt'] as String,
      ),
    );
  }
}

class InstructorSubmissionStudent {
  const InstructorSubmissionStudent({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
  });

  final String id;
  final String firstName;
  final String lastName;
  final String email;

  String get fullName {
    final name = '$firstName $lastName'.trim();
    return name.isEmpty ? email : name;
  }

  factory InstructorSubmissionStudent.fromJson(
      Map<String, dynamic> json,
      ) {
    return InstructorSubmissionStudent(
      id: json['id']?.toString() ?? '',
      firstName: json['firstName']?.toString() ?? '',
      lastName: json['lastName']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
    );
  }
}