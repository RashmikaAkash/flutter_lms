import 'package:flutter/material.dart';

import '../core/course/course_enrollment_page.dart';
import '../core/course/course_service.dart';
import '../core/errors/api_exception.dart';
import '../core/models/course/course_enrollment.dart';
import '../widgets/message_widget.dart';

class MyCoursesScreen extends StatefulWidget {
  const MyCoursesScreen({super.key});

  @override
  State<MyCoursesScreen> createState() => _MyCoursesScreenState();
}

class _MyCoursesScreenState extends State<MyCoursesScreen> {
  final CourseService _courseService = CourseService();

  CourseEnrollmentPage? _enrollmentPage;

  bool _isLoading = true;
  String? _errorMessage;

  int _currentPage = 1;

  static const int _pageLimit = 10;

  @override
  void initState() {
    super.initState();
    _loadEnrollments();
  }

  Future<void> _loadEnrollments({
    int page = 1,
  }) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _courseService.getMyEnrollments(
        page: page,
        limit: _pageLimit,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _enrollmentPage = result;
        _currentPage = result.pagination.page;
      });
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = error.message;
        _enrollmentPage = null;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = 'Unable to load your courses. Please try again.';
        _enrollmentPage = null;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _openCourse(CourseEnrollment enrollment) {
    if (enrollment.courseId.isEmpty) {
      return;
    }

    Navigator.pushNamed(
      context,
      '/course-details',
      arguments: {
        'courseId': enrollment.courseId,
        'showEnrollButton': false,
        'enrollmentId': enrollment.id,
      },
    );
  }

  Widget _buildCourseCard(
    CourseEnrollment enrollment,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    final progress = enrollment.progressPercentage.clamp(
      0,
      100,
    );

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openCourse(enrollment),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 82,
                height: 82,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                clipBehavior: Clip.antiAlias,
                child: enrollment.thumbnailUrl != null
                    ? Image.network(
                        enrollment.thumbnailUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) {
                          return Icon(
                            Icons.menu_book_outlined,
                            color: colorScheme.onPrimaryContainer,
                          );
                        },
                      )
                    : Icon(
                        Icons.menu_book_outlined,
                        color: colorScheme.onPrimaryContainer,
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      enrollment.courseTitle.isEmpty
                          ? 'Course'
                          : enrollment.courseTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 6),
                    if (enrollment.courseLevel.isNotEmpty)
                      Text(
                        enrollment.courseLevel,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    if (enrollment.courseLanguage.isNotEmpty)
                      Text(
                        enrollment.courseLanguage,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    const SizedBox(height: 10),
                    LinearProgressIndicator(
                      value: progress / 100,
                      minHeight: 7,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${progress.toStringAsFixed(0)}% completed',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPagination() {
    final pagination = _enrollmentPage?.pagination;

    if (pagination == null || pagination.totalPages <= 1) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          OutlinedButton.icon(
            onPressed: pagination.hasPreviousPage && !_isLoading
                ? () => _loadEnrollments(
                      page: _currentPage - 1,
                    )
                : null,
            icon: const Icon(Icons.chevron_left),
            label: const Text('Previous'),
          ),
          const SizedBox(width: 12),
          Text(
            'Page $_currentPage of ${pagination.totalPages}',
          ),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: pagination.hasNextPage && !_isLoading
                ? () => _loadEnrollments(
                      page: _currentPage + 1,
                    )
                : null,
            icon: const Icon(Icons.chevron_right),
            label: const Text('Next'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading && _enrollmentPage == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null && _enrollmentPage == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: MessageWidget(
            title: 'Unable to load courses',
            message: _errorMessage!,
            type: MessageType.error,
            actionLabel: 'Retry',
            onActionPressed: () => _loadEnrollments(
              page: _currentPage,
            ),
          ),
        ),
      );
    }

    final enrollments = (_enrollmentPage?.enrollments ?? [])
        .where(
          (enrollment) => enrollment.progressPercentage < 100,
        )
        .toList();

    return RefreshIndicator(
      onRefresh: () => _loadEnrollments(
        page: _currentPage,
      ),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/completed-courses',
                );
              },
              icon: const Icon(
                Icons.emoji_events_outlined,
              ),
              label: const Text(
                'View Completed Courses',
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '${enrollments.length} active course(s)',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 14),
          if (enrollments.isEmpty)
            const MessageWidget(
              title: 'No active courses',
              message: 'You do not have any courses in progress. '
                  'Completed courses can be viewed separately.',
              type: MessageType.info,
            )
          else
            ...enrollments.map(_buildCourseCard),
          _buildPagination(),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Courses'),
      ),
      body: SafeArea(
        child: _buildContent(),
      ),
    );
  }
}
