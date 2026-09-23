import 'package:flutter/material.dart';

import '../core/course/course_service.dart';
import '../core/errors/api_exception.dart';
import '../core/models/course/course.dart';
import '../core/models/course/course_section.dart';
import '../widgets/message_widget.dart';
import '../core/models/course/course_enrollment.dart';

class CourseDetailsScreen extends StatefulWidget {
  const CourseDetailsScreen({
    super.key,
    required this.courseId,
    this.showEnrollButton = true,
    this.enrollmentId,
  });

  final String courseId;
  final bool showEnrollButton;
  final String? enrollmentId;

  @override
  State<CourseDetailsScreen> createState() => _CourseDetailsScreenState();
}

class _CourseDetailsScreenState extends State<CourseDetailsScreen> {
  final CourseService _courseService = CourseService();

  Course? _course;
  List<CourseSection> _sections = [];

  bool _isLoading = true;
  bool _isEnrolling = false;
  String? _errorMessage;
  String? _curriculumErrorMessage;
  CourseEnrollment? _existingEnrollment;

  String? _currentEnrollmentId;

  @override
  void initState() {
    super.initState();
    _currentEnrollmentId = widget.enrollmentId;
    _loadCourseDetails();
  }

  Future<void> _loadCourseDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _curriculumErrorMessage = null;
    });

    try {
      final course = await _courseService.getPublishedCourse(
        widget.courseId,
      );

      List<CourseSection> sections = [];
      String? curriculumError;

      try {
        sections = await _courseService.getCourseSections(
          widget.courseId,
        );
      } on ApiException catch (error) {
        if (error.isForbidden) {
          curriculumError = 'Enroll in this course to access its curriculum.';
        } else {
          rethrow;
        }
      }

      if (!mounted) {
        return;
      }

      sections.sort(
        (a, b) => a.order.compareTo(b.order),
      );

      setState(() {
        _course = course;
        _sections = sections;
        _curriculumErrorMessage = curriculumError;
      });
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = error.message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = 'Unable to load course details. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _enroll() async {
    if (_course == null || _isEnrolling) {
      return;
    }

    setState(() {
      _isEnrolling = true;
    });

    try {
      final result = await _courseService.enrollInCourse(
        _course!.id,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _existingEnrollment = result.enrollment;
        _currentEnrollmentId = result.enrollment.id;
      });

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Successfully enrolled in this course.',
          ),
        ),
      );

      await _loadCourseDetails();
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to enroll in this course. Please try again.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isEnrolling = false;
        });
      }
    }
  }

  Widget _buildEnrollmentButton() {
    final enrollment = _existingEnrollment;

    if (enrollment == null) {
      return FilledButton.icon(
        onPressed: _isEnrolling ? null : _enroll,
        icon: _isEnrolling
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              )
            : const Icon(Icons.school_outlined),
        label: Text(
          _isEnrolling ? 'Enrolling...' : 'Enroll in Course',
        ),
      );
    }

    final isCompleted = enrollment.progressPercentage >= 100;

    if (!isCompleted) {
      return FilledButton.icon(
        onPressed: null,
        icon: const Icon(
          Icons.check_circle_outline,
        ),
        label: const Text('Already Enrolled'),
      );
    }

    return FilledButton.icon(
      onPressed: _isEnrolling ? null : _confirmReEnrollment,
      icon: const Icon(
        Icons.refresh_rounded,
      ),
      label: const Text('Re-enroll in Course'),
    );
  }

  Future<void> _confirmReEnrollment() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Re-enroll in course?'),
          content: const Text(
            'You have already completed this course. '
            'Would you like to enroll again?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Re-enroll'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _enroll();
    }
  }

  Widget _buildCourseHeader(Course course) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (course.thumbnailUrl != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(
              course.thumbnailUrl!,
              width: double.infinity,
              height: 210,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) {
                return _buildPlaceholderHeader();
              },
            ),
          )
        else
          _buildPlaceholderHeader(),
        const SizedBox(height: 18),
        Text(
          course.title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          course.shortDescription,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            Chip(
              label: Text(course.level),
              avatar: const Icon(
                Icons.signal_cellular_alt,
                size: 18,
              ),
            ),
            Chip(
              label: Text(course.language),
              avatar: const Icon(
                Icons.language,
                size: 18,
              ),
            ),
            Chip(
              label: Text(
                course.isFree ? 'Free' : 'Price: ${course.price}',
              ),
              avatar: const Icon(
                Icons.payments_outlined,
                size: 18,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            const Icon(Icons.star_rounded),
            const SizedBox(width: 5),
            Text(
              course.averageRating.toStringAsFixed(1),
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '(${course.reviewCount} reviews)',
            ),
            const SizedBox(width: 16),
            Icon(
              Icons.people_outline,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 5),
            Text('${course.totalEnrollments} enrolled'),
          ],
        ),
      ],
    );
  }

  Widget _buildPlaceholderHeader() {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: 210,
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(
        Icons.menu_book_outlined,
        size: 64,
        color: colorScheme.onPrimaryContainer,
      ),
    );
  }

  Widget _buildInstructor(Course course) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundImage: course.instructor.profileImageUrl != null
                  ? NetworkImage(
                      course.instructor.profileImageUrl!,
                    )
                  : null,
              child: course.instructor.profileImageUrl == null
                  ? const Icon(Icons.person_outline)
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Instructor',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    course.instructor.fullName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  if (course.instructor.bio.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      course.instructor.bio,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurriculum() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Curriculum',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      '/course-curriculum',
                      arguments: {
                        'courseId': _course!.id,
                        'enrollmentId': _currentEnrollmentId,
                      },
                    );
                  },
                  child: const Text('View Full'),
                ),
              ],
            ),
            if (_currentEnrollmentId != null &&
                _currentEnrollmentId!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/student-quizzes',
                        arguments: {
                          'courseId': _course!.id,
                        },
                      );
                    },
                    icon: const Icon(
                      Icons.quiz_outlined,
                    ),
                    label: const Text('Quizzes'),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/student-assignments',
                        arguments: {
                          'courseId': _course!.id,
                        },
                      );
                    },
                    icon: const Icon(
                      Icons.assignment_outlined,
                    ),
                    label: const Text('Assignments'),
                  ),
                ],
              ),
            ],
          ],
        ),
        const SizedBox(height: 10),
        if (_curriculumErrorMessage != null)
          MessageWidget(
            title: 'Curriculum Locked',
            message: _curriculumErrorMessage!,
            type: MessageType.info,
          )
        else if (_sections.isEmpty)
          const MessageWidget(
            message: 'No curriculum sections are available.',
          )
        else
          ..._sections.map(
            (section) => Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: CircleAvatar(
                  child: Text(
                    section.order.toString(),
                  ),
                ),
                title: Text(section.title),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (section.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        section.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      '${section.lessonCount} lesson(s)',
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCourseContent(Course course) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        16,
        16,
        16,
        110,
      ),
      children: [
        _buildCourseHeader(course),
        const SizedBox(height: 24),
        Text(
          'About this course',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          course.description,
        ),
        const SizedBox(height: 24),
        _buildInstructor(course),
        const SizedBox(height: 24),
        _buildCurriculum(),
        if (course.learningOutcomes.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text(
            'Learning Outcomes',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          ...course.learningOutcomes.map(
            (item) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(
                Icons.check_circle_outline,
              ),
              title: Text(item),
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Course Details'),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : _errorMessage != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: MessageWidget(
                        title: 'Unable to load course',
                        message: _errorMessage!,
                        type: MessageType.error,
                        actionLabel: 'Retry',
                        onActionPressed: _loadCourseDetails,
                      ),
                    ),
                  )
                : _course == null
                    ? const Center(
                        child: MessageWidget(
                          message: 'Course details are unavailable.',
                        ),
                      )
                    : Stack(
                        children: [
                          _buildCourseContent(_course!),
                          if (widget.showEnrollButton)
                            Positioned(
                              left: 16,
                              right: 16,
                              bottom: 16,
                              child: _buildEnrollmentButton(),
                            ),
                        ],
                      ),
      ),
    );
  }
}
