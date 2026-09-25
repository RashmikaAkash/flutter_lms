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
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (course.thumbnailUrl != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(
                course.thumbnailUrl!,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildPlaceholderHeader(),
              ),
            ),
          )
        else
          _buildPlaceholderHeader(),
        const SizedBox(height: 20),
        Text(
          course.title,
          style: textTheme.headlineSmall?.copyWith(height: 1.2),
        ),
        const SizedBox(height: 10),
        Text(
          course.shortDescription,
          style: textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurfaceVariant,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (course.category.name.isNotEmpty)
              _buildInfoPill(
                Icons.category_outlined,
                course.category.name,
              ),
            _buildInfoPill(
              Icons.signal_cellular_alt_outlined,
              course.level,
            ),
            _buildInfoPill(
              Icons.language_outlined,
              course.language,
            ),
            _buildInfoPill(
              Icons.payments_outlined,
              course.isFree ? 'Free' : 'Price: ${course.price}',
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: Wrap(
            spacing: 22,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star_rounded, color: colorScheme.tertiary),
                  const SizedBox(width: 6),
                  Text(
                    course.averageRating.toStringAsFixed(1),
                    style: textTheme.titleMedium,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '(${course.reviewCount} reviews)',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.people_outline,
                    color: colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${course.totalEnrollments} enrolled',
                    style: textTheme.bodyMedium,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoPill(IconData icon, String label) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      constraints: const BoxConstraints(maxWidth: 260),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: colors.primary),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderHeader() {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: double.infinity,
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            Icons.menu_book_outlined,
            size: 64,
            color: colorScheme.onPrimaryContainer,
          ),
        ),
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
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/course-reviews',
                        arguments: {
                          'courseId': _course!.id,
                          'courseTitle': _course!.title,
                          'isEnrolled': _currentEnrollmentId != null &&
                              _currentEnrollmentId!.isNotEmpty,
                        },
                      );
                    },
                    icon: const Icon(Icons.rate_review_outlined),
                    label: const Text('Reviews'),
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
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      backgroundColor:
                          Theme.of(context).colorScheme.primaryContainer,
                      foregroundColor:
                          Theme.of(context).colorScheme.onPrimaryContainer,
                      child: Text(section.order.toString()),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            section.title,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          if (section.description.isNotEmpty) ...[
                            const SizedBox(height: 5),
                            Text(
                              section.description,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                            ),
                          ],
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Icon(
                                Icons.play_lesson_outlined,
                                size: 17,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${section.lessonCount} lesson(s)',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelMedium
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ),
                        ],
                      ),
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
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.6),
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
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 14),
                    Text(
                      'Loading course details',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
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
                              left: 0,
                              right: 0,
                              bottom: 0,
                              child: Container(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  12,
                                  16,
                                  12,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surface,
                                  border: Border(
                                    top: BorderSide(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .outlineVariant,
                                    ),
                                  ),
                                ),
                                child: SizedBox(
                                  width: double.infinity,
                                  child: _buildEnrollmentButton(),
                                ),
                              ),
                            ),
                        ],
                      ),
      ),
    );
  }
}
