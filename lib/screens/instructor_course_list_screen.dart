import 'package:flutter/material.dart';

import '../core/course/course_page.dart';
import '../core/course/course_service.dart';
import '../core/errors/api_exception.dart';
import '../core/models/course/course.dart';
import 'instructor_create_course_screen.dart';
import 'instructor_course_setup_screen.dart';
import '../widgets/message_widget.dart';

class InstructorCourseListScreen extends StatefulWidget {
  const InstructorCourseListScreen({
    super.key,
  });

  @override
  State<InstructorCourseListScreen> createState() =>
      _InstructorCourseListScreenState();
}

class _InstructorCourseListScreenState
    extends State<InstructorCourseListScreen> {
  final CourseService _courseService = CourseService();

  CoursePage? _coursePage;

  bool _isLoading = true;
  String? _errorMessage;
  String? _openingSetupCourseId;

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _courseService.getInstructorCourses(
        page: 1,
        limit: 20,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _coursePage = result;
        _isLoading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage = error.message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage = 'Unable to load your courses. Please try again.';
      });
    }
  }

  Future<void> _openCreateCourse() async {
    final created = await Navigator.push<Course>(
      context,
      MaterialPageRoute<Course>(
        builder: (context) => const InstructorCreateCourseScreen(),
      ),
    );

    if (created == null || !mounted) {
      return;
    }

    await _loadCourses();
    if (mounted) await _openCourseSetup(created.id);
  }

  Future<void> _openCourseSetup(String courseId) async {
    if (_openingSetupCourseId != null) return;
    setState(() => _openingSetupCourseId = courseId);
    try {
      final completed = await Navigator.push<bool>(
        context,
        MaterialPageRoute<bool>(
          builder: (context) => InstructorCourseSetupScreen(courseId: courseId),
        ),
      );
      if (completed == true && mounted) await _loadCourses();
    } finally {
      if (mounted) setState(() => _openingSetupCourseId = null);
    }
  }

  Widget _buildCourseCard(Course course) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.pushNamed(
            context,
            '/instructor-assignment-list',
            arguments: course.id,
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                course.title.isEmpty ? 'Course' : course.title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              if (course.shortDescription.isNotEmpty)
                Text(
                  course.shortDescription,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(
                    avatar: const Icon(
                      Icons.public_outlined,
                      size: 18,
                    ),
                    label: Text(
                      course.status.isEmpty
                          ? 'Status unavailable'
                          : course.status,
                    ),
                  ),
                  Chip(
                    avatar: const Icon(
                      Icons.language_outlined,
                      size: 18,
                    ),
                    label: Text(
                      course.language.isEmpty
                          ? 'Language unavailable'
                          : course.language,
                    ),
                  ),
                  Chip(
                    avatar: const Icon(
                      Icons.people_outline,
                      size: 18,
                    ),
                    label: Text(
                      '${course.totalEnrollments} enrollment(s)',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.end,
                children: [
                  if (course.status == 'DRAFT')
                    FilledButton.icon(
                      onPressed: _openingSetupCourseId == null
                          ? () => _openCourseSetup(course.id)
                          : null,
                      icon: _openingSetupCourseId == course.id
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.playlist_add_check_outlined),
                      label: Text(
                        _openingSetupCourseId == course.id
                            ? 'Opening setup...'
                            : 'Continue setup',
                      ),
                    )
                  else if (course.status == 'PUBLISHED')
                    const Chip(
                      avatar: Icon(Icons.check_circle_outline, size: 18),
                      label: Text('Published'),
                    ),
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/instructor-assignment-list',
                        arguments: course.id,
                      );
                    },
                    icon: const Icon(
                      Icons.assignment_outlined,
                    ),
                    label: const Text('View Assignments'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/instructor-quizzes',
                        arguments: course.id,
                      );
                    },
                    icon: const Icon(
                      Icons.quiz_outlined,
                    ),
                    label: const Text('View Quizzes'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
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
            title: 'Unable to load courses',
            message: _errorMessage!,
            type: MessageType.error,
            actionLabel: 'Retry',
            onActionPressed: _loadCourses,
          ),
        ),
      );
    }

    final page = _coursePage;

    if (page == null || page.courses.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadCourses,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 80),
            MessageWidget(
              title: 'No courses yet',
              message: 'Create a course to start building your catalogue.',
              type: MessageType.info,
              actionLabel: 'Create course',
              onActionPressed: _openCreateCourse,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadCourses,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          16,
          16,
          16,
          24,
        ),
        itemCount: page.courses.length,
        separatorBuilder: (context, index) {
          return const SizedBox(height: 12);
        },
        itemBuilder: (context, index) {
          return _buildCourseCard(
            page.courses[index],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Courses'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton.icon(
              onPressed: _openCreateCourse,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Create Course'),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: _buildContent(),
      ),
    );
  }
}
