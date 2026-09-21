import 'package:flutter/material.dart';

import '../core/course/course_service.dart';
import '../core/errors/api_exception.dart';
import '../core/models/course/course_lesson.dart';
import '../core/models/course/course_section.dart';
import '../core/models/course/enrollment_progress.dart';
import '../widgets/message_widget.dart';

class CourseCurriculumScreen extends StatefulWidget {
  const CourseCurriculumScreen({
    super.key,
    required this.courseId,
    this.enrollmentId,
  });

  final String courseId;
  final String? enrollmentId;

  @override
  State<CourseCurriculumScreen> createState() => _CourseCurriculumScreenState();
}

class _CourseCurriculumScreenState extends State<CourseCurriculumScreen> {
  final CourseService _courseService = CourseService();

  List<CourseSection> _sections = [];

  EnrollmentProgress? _enrollmentProgress;

  bool _isLoading = true;
  String? _errorMessage;
  String? _progressErrorMessage;

  final Map<String, EnrollmentLessonProgress?> _lessonProgressById = {};

  @override
  void initState() {
    super.initState();
    _loadSections();
  }

  Future<void> _loadSections() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _progressErrorMessage = null;
      _enrollmentProgress = null;
      _lessonProgressById.clear();
    });

    try {
      final sections = await _courseService.getCourseSections(
        widget.courseId,
      );

      sections.sort(
        (a, b) => a.order.compareTo(b.order),
      );

      EnrollmentProgress? enrollmentProgress;
      String? progressError;

      if (widget.enrollmentId != null && widget.enrollmentId!.isNotEmpty) {
        try {
          enrollmentProgress = await _courseService.getEnrollmentProgress(
            widget.enrollmentId!,
          );

          for (final lesson in enrollmentProgress.lessons) {
            _lessonProgressById[lesson.id] = lesson.progress;
          }
        } on ApiException catch (error) {
          progressError = error.message;
        } catch (_) {
          progressError = 'Unable to load learning progress. Please try again.';
        }
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _sections = sections;
        _enrollmentProgress = enrollmentProgress;
        _progressErrorMessage = progressError;
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
        _errorMessage = 'Unable to load curriculum. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  IconData _lessonIcon(CourseLesson lesson) {
    if (lesson.isText) {
      return Icons.article_outlined;
    }

    if (lesson.isVideo) {
      return Icons.play_circle_outline;
    }

    if (lesson.isDocument) {
      return Icons.description_outlined;
    }

    return Icons.menu_book_outlined;
  }

  Widget _buildProgressSummary() {
    final progress = _enrollmentProgress;

    if (progress == null) {
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 18),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.trending_up_rounded,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Course Progress',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            LinearProgressIndicator(
              value: progress.enrollment.progressPercentage / 100,
              minHeight: 8,
              borderRadius: BorderRadius.circular(10),
            ),
            const SizedBox(height: 8),
            Text(
              '${progress.enrollment.progressPercentage.toStringAsFixed(0)}% completed',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Enrollment status: ${progress.enrollment.status}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            Text(
              '${progress.lessons.length} lesson(s) in this course',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLessonProgress(
    CourseLesson lesson,
  ) {
    final progress = _lessonProgressById[lesson.id];

    if (progress == null || progress.status.isEmpty) {
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: Row(
        children: [
          Icon(
            progress.status == 'COMPLETED'
                ? Icons.check_circle_outline
                : progress.status == 'IN_PROGRESS'
                    ? Icons.play_circle_outline
                    : Icons.radio_button_unchecked,
            size: 16,
            color: progress.status == 'COMPLETED'
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 5),
          Text(
            progress.status.replaceAll('_', ' '),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildLessonTypeBadge(CourseLesson lesson) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        lesson.lessonType,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colorScheme.onSecondaryContainer,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  Widget _buildLessonTile(CourseLesson lesson) {
    return ListTile(
      onTap: () async {
        await Navigator.pushNamed(
          context,
          '/lesson-player',
          arguments: lesson.id,
        );

        if (!mounted) {
          return;
        }

        await _loadSections();
      },
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 2,
      ),
      leading: CircleAvatar(
        child: Icon(
          _lessonIcon(lesson),
          size: 20,
        ),
      ),
      title: Text(
        lesson.title,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (lesson.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              lesson.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (lesson.durationMinutes > 0) ...[
            const SizedBox(height: 5),
            Text(
              '${lesson.durationMinutes} minute(s)',
            ),
          ],
          _buildLessonProgress(lesson),
        ],
      ),
      trailing: _buildLessonTypeBadge(lesson),
    );
  }

  Widget _buildSectionTile(CourseSection section) {
    return _CourseSectionTile(
      section: section,
      courseService: _courseService,
      lessonBuilder: _buildLessonTile,
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: MessageWidget(
            title: 'Unable to load curriculum',
            message: _errorMessage!,
            type: MessageType.error,
            actionLabel: 'Retry',
            onActionPressed: _loadSections,
          ),
        ),
      );
    }

    if (_sections.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: MessageWidget(
            title: 'No curriculum available',
            message: 'This course does not have any available sections yet.',
            type: MessageType.info,
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadSections,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildProgressSummary(),
          if (_progressErrorMessage != null) ...[
            MessageWidget(
              title: 'Progress unavailable',
              message: _progressErrorMessage!,
              type: MessageType.info,
              actionLabel: 'Retry',
              onActionPressed: _loadSections,
            ),
            const SizedBox(height: 14),
          ],
          Text(
            '${_sections.length} section(s)',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 12),
          ..._sections.map(_buildSectionTile),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Curriculum'),
      ),
      body: SafeArea(
        child: _buildContent(),
      ),
    );
  }
}

class _CourseSectionTile extends StatefulWidget {
  const _CourseSectionTile({
    required this.section,
    required this.courseService,
    required this.lessonBuilder,
  });

  final CourseSection section;
  final CourseService courseService;
  final Widget Function(CourseLesson lesson) lessonBuilder;

  @override
  State<_CourseSectionTile> createState() => _CourseSectionTileState();
}

class _CourseSectionTileState extends State<_CourseSectionTile> {
  List<CourseLesson>? _lessons;

  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _loadLessons() async {
    if (_isLoading || _lessons != null) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final lessons = await widget.courseService.getSectionLessons(
        widget.section.id,
      );

      if (!mounted) {
        return;
      }

      lessons.sort(
        (a, b) => a.order.compareTo(b.order),
      );

      setState(() {
        _lessons = lessons;
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
        _errorMessage = 'Unable to load lessons. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildExpandedContent() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(
          16,
          0,
          16,
          16,
        ),
        child: MessageWidget(
          title: 'Unable to load lessons',
          message: _errorMessage!,
          type: MessageType.error,
          actionLabel: 'Retry',
          onActionPressed: _loadLessons,
        ),
      );
    }

    final lessons = _lessons ?? const <CourseLesson>[];

    if (lessons.isEmpty) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          0,
          16,
          16,
        ),
        child: MessageWidget(
          message: 'No lessons are available in this section.',
          type: MessageType.info,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(
        left: 8,
        right: 8,
        bottom: 8,
      ),
      child: Column(
        children: lessons.map(widget.lessonBuilder).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ExpansionTile(
        onExpansionChanged: (expanded) {
          if (expanded) {
            _loadLessons();
          }
        },
        leading: CircleAvatar(
          child: Text(
            widget.section.order.toString(),
          ),
        ),
        title: Text(
          widget.section.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${widget.section.lessonCount} lesson(s)',
        ),
        children: [
          _buildExpandedContent(),
        ],
      ),
    );
  }
}
