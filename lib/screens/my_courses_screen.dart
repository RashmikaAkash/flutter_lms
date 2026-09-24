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

  Future<void> _openCourse(CourseEnrollment enrollment) async {
    if (enrollment.courseId.isEmpty) {
      return;
    }

    await Navigator.pushNamed(
      context,
      '/course-details',
      arguments: {
        'courseId': enrollment.courseId,
        'showEnrollButton': false,
        'enrollmentId': enrollment.id,
      },
    );

    if (!mounted) {
      return;
    }

    await _loadEnrollments(
      page: _currentPage,
    );
  }

  Widget _buildCourseCard(
    CourseEnrollment enrollment,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

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
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
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
                      style: textTheme.titleMedium,
                    ),
                    if (enrollment.courseLevel.isNotEmpty ||
                        enrollment.courseLanguage.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          if (enrollment.courseLevel.isNotEmpty)
                            _buildDetailTag(
                              Icons.signal_cellular_alt_outlined,
                              enrollment.courseLevel,
                            ),
                          if (enrollment.courseLanguage.isNotEmpty)
                            _buildDetailTag(
                              Icons.language_outlined,
                              enrollment.courseLanguage,
                            ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Course progress',
                            style: textTheme.labelMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        Text(
                          '${progress.toStringAsFixed(0)}%',
                          style: textTheme.labelLarge?.copyWith(
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    LinearProgressIndicator(
                      value: progress / 100,
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(8),
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

  Widget _buildDetailTag(IconData icon, String label) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      constraints: const BoxConstraints(maxWidth: 180),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: colors.onSurfaceVariant),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
            ),
          ),
        ],
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
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        runSpacing: 8,
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
          Text(
            'Page $_currentPage of ${pagination.totalPages}',
          ),
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
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 14),
            Text(
              'Loading your courses',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
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
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your learning',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Pick up where you left off.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 176,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      '/completed-courses',
                    );
                  },
                  icon: const Icon(Icons.emoji_events_outlined),
                  label: const Text('Completed'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Text(
                  'In progress',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${enrollments.length} active',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color:
                            Theme.of(context).colorScheme.onSecondaryContainer,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (enrollments.isEmpty) ...[
            const MessageWidget(
              title: 'No active courses',
              message: 'You do not have any courses in progress. '
                  'Completed courses can be viewed separately.',
              type: MessageType.info,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/course-browse');
              },
              icon: const Icon(Icons.explore_outlined),
              label: const Text('Browse courses'),
            ),
          ] else
            LayoutBuilder(
              builder: (context, constraints) {
                final twoColumns = constraints.maxWidth >= 680;
                final cardWidth = twoColumns
                    ? ((constraints.maxWidth - 16) / 2).clamp(0, 560).toDouble()
                    : constraints.maxWidth;
                return Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 16,
                  runSpacing: 14,
                  children: enrollments
                      .map(
                        (enrollment) => SizedBox(
                          width: cardWidth,
                          child: _buildCourseCard(enrollment),
                        ),
                      )
                      .toList(),
                );
              },
            ),
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
