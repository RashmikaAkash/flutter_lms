import 'package:flutter/material.dart';

import '../core/course/course_service.dart';
import '../core/errors/api_exception.dart';
import '../core/models/course/course.dart';
import '../core/models/course/course_lesson.dart';
import '../core/models/course/course_section.dart';
import '../widgets/message_widget.dart';
import '../widgets/primary_button.dart';

class InstructorCourseSetupScreen extends StatefulWidget {
  const InstructorCourseSetupScreen({
    required this.courseId,
    super.key,
  });

  final String courseId;

  @override
  State<InstructorCourseSetupScreen> createState() =>
      _InstructorCourseSetupScreenState();
}

class _InstructorCourseSetupScreenState
    extends State<InstructorCourseSetupScreen> {
  final _courseService = CourseService();
  final _sectionFormKey = GlobalKey<FormState>();
  final _lessonFormKey = GlobalKey<FormState>();
  final _sectionTitleController = TextEditingController();
  final _sectionDescriptionController = TextEditingController();
  final _lessonTitleController = TextEditingController();
  final _lessonDescriptionController = TextEditingController();
  final _lessonTextController = TextEditingController();
  final _durationController = TextEditingController(text: '0');

  Course? _course;
  CourseSection? _section;
  CourseLesson? _lesson;
  bool _isLoading = true;
  bool _isPreview = false;
  String? _loadError;
  String? _activeAction;

  bool get _isBusy => _activeAction != null;
  bool get _isCoursePublished => _course?.status == 'PUBLISHED';

  @override
  void initState() {
    super.initState();
    _loadExistingSetup();
  }

  @override
  void dispose() {
    _sectionTitleController.dispose();
    _sectionDescriptionController.dispose();
    _lessonTitleController.dispose();
    _lessonDescriptionController.dispose();
    _lessonTextController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingSetup() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final course = await _courseService.getInstructorCourse(widget.courseId);
      final sections = await _courseService.getCourseSections(widget.courseId);
      CourseSection? section;
      for (final candidate in sections) {
        if (candidate.isPublished) {
          section = candidate;
          break;
        }
      }
      section ??= sections.isEmpty ? null : sections.first;

      CourseLesson? lesson;
      if (section != null) {
        final lessons = await _courseService.getSectionLessons(section.id);
        for (final candidate in lessons) {
          if (candidate.isPublished) {
            lesson = candidate;
            break;
          }
        }
        lesson ??= lessons.isEmpty ? null : lessons.first;
      }

      if (!mounted) return;
      setState(() {
        _course = course;
        _section = section;
        _lesson = lesson;
        _isLoading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = 'Unable to load course setup. Please try again.';
      });
    }
  }

  Future<void> _runAction(
    String action,
    Future<void> Function() operation,
  ) async {
    if (_isBusy) return;
    setState(() => _activeAction = action);
    try {
      await operation();
    } on ApiException catch (error) {
      if (mounted) {
        _showMessage(_friendlyError(error));
      }
    } catch (_) {
      if (mounted) {
        _showMessage('Unable to complete this step. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _activeAction = null);
    }
  }

  String _friendlyError(ApiException error) {
    final body = error.responseBody;
    if (error.statusCode == 409 && body is Map) {
      if (body['errorCode'] == 'PUBLISHED_LESSON_REQUIRED') {
        return 'Please create and publish at least one lesson in a published section before publishing this course.';
      }
      final message = body['message'];
      if (message is String && message.trim().isNotEmpty) return message;
    }
    return error.message;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _createSection() async {
    if (!(_sectionFormKey.currentState?.validate() ?? false)) return;
    await _runAction('section', () async {
      final section = await _courseService.createInstructorSection(
        courseId: widget.courseId,
        title: _sectionTitleController.text,
        description: _sectionDescriptionController.text,
        isPublished: true,
      );
      if (!mounted) return;
      setState(() => _section = section);
    });
  }

  Future<void> _publishSection() async {
    final section = _section;
    if (section == null) return;
    await _runAction('section', () async {
      final updated = await _courseService.publishInstructorSection(section.id);
      if (!mounted) return;
      setState(() => _section = updated);
    });
  }

  Future<void> _createLesson() async {
    if (!(_lessonFormKey.currentState?.validate() ?? false)) return;
    final section = _section;
    if (section == null || !section.isPublished) return;
    await _runAction('lesson', () async {
      final lesson = await _courseService.createInstructorTextLesson(
        sectionId: section.id,
        title: _lessonTitleController.text,
        description: _lessonDescriptionController.text,
        textContent: _lessonTextController.text,
        durationMinutes: int.parse(_durationController.text.trim()),
        isPreview: _isPreview,
      );
      if (!mounted) return;
      setState(() => _lesson = lesson);
    });
  }

  Future<void> _publishLesson() async {
    final lesson = _lesson;
    if (lesson == null || lesson.isPublished) return;
    await _runAction('lesson', () async {
      final published = await _courseService.publishInstructorLesson(lesson.id);
      final section = _section;
      if (section == null) return;
      final refreshedLessons =
          await _courseService.getSectionLessons(section.id);
      CourseLesson? confirmedLesson;
      for (final item in refreshedLessons) {
        if (item.id == published.id) {
          confirmedLesson = item;
          break;
        }
      }
      if (confirmedLesson?.isPublished != true) {
        throw const ApiException(
          message: 'The backend did not confirm that the lesson is published.',
        );
      }
      if (!mounted) return;
      setState(() => _lesson = confirmedLesson);
      _showMessage('Lesson published successfully.');
    });
  }

  Future<void> _publishCourse() async {
    if (_section?.isPublished != true || _lesson?.isPublished != true) return;
    await _runAction('course', () async {
      final published = await _courseService.publishInstructorCourse(
        widget.courseId,
      );
      if (published.status != 'PUBLISHED') {
        throw const ApiException(
          message: 'The backend did not confirm that the course is published.',
        );
      }
      final refreshed =
          await _courseService.getInstructorCourse(widget.courseId);
      if (!mounted) return;
      setState(() => _course = refreshed);
      if (refreshed.status == 'PUBLISHED') {
        _showMessage('Course published successfully.');
      } else {
        _showMessage('Course status refreshed: ${refreshed.status}');
      }
    });
  }

  Widget _stepRow(String label, bool complete) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(
            complete ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 20,
            color: complete ? colors.primary : colors.outline,
          ),
          const SizedBox(width: 10),
          Text(label),
        ],
      ),
    );
  }

  Widget _buildProgressCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _course?.title.isNotEmpty == true
                  ? _course!.title
                  : 'Course setup',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            _stepRow('Course created', _course != null),
            _stepRow(
                'Published section created', _section?.isPublished == true),
            _stepRow('TEXT lesson created', _lesson != null),
            _stepRow('Lesson published', _lesson?.isPublished == true),
            _stepRow('Course published', _isCoursePublished),
            if (_course != null) ...[
              const SizedBox(height: 8),
              Chip(label: Text('Backend status: ${_course!.status}')),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Form(
          key: _sectionFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Create first section',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 16),
              TextFormField(
                controller: _sectionTitleController,
                enabled: !_isBusy,
                decoration: const InputDecoration(labelText: 'Section title'),
                validator: (value) {
                  final title = value?.trim() ?? '';
                  if (title.length < 2 || title.length > 150) {
                    return 'Enter 2 to 150 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _sectionDescriptionController,
                enabled: !_isBusy,
                maxLines: 3,
                decoration:
                    const InputDecoration(labelText: 'Description (optional)'),
                validator: (value) => (value?.trim().length ?? 0) > 1000
                    ? 'Use 1000 characters or fewer'
                    : null,
              ),
              const SizedBox(height: 18),
              PrimaryButton(
                label: _activeAction == 'section'
                    ? 'Creating section...'
                    : 'Create published section',
                icon: Icons.library_add_outlined,
                isLoading: _activeAction == 'section',
                onPressed: _isBusy ? null : _createSection,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionPublishAction() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Section created: ${_section!.title}'),
            const SizedBox(height: 12),
            PrimaryButton(
              label: _activeAction == 'section'
                  ? 'Publishing section...'
                  : 'Publish section',
              icon: Icons.publish_outlined,
              isLoading: _activeAction == 'section',
              onPressed: _isBusy ? null : _publishSection,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLessonForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Form(
          key: _lessonFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Create first TEXT lesson',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 16),
              TextFormField(
                controller: _lessonTitleController,
                enabled: !_isBusy,
                decoration: const InputDecoration(labelText: 'Lesson title'),
                validator: (value) {
                  final title = value?.trim() ?? '';
                  if (title.length < 2 || title.length > 150) {
                    return 'Enter 2 to 150 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _lessonDescriptionController,
                enabled: !_isBusy,
                maxLines: 2,
                decoration:
                    const InputDecoration(labelText: 'Description (optional)'),
                validator: (value) => (value?.trim().length ?? 0) > 1000
                    ? 'Use 1000 characters or fewer'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _lessonTextController,
                enabled: !_isBusy,
                minLines: 5,
                maxLines: 10,
                decoration: const InputDecoration(
                  labelText: 'Lesson text content',
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  final content = value?.trim() ?? '';
                  if (content.isEmpty) {
                    return 'Text content is required';
                  }
                  if (content.length > 50000) {
                    return 'Use 50000 characters or fewer';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _durationController,
                enabled: !_isBusy,
                keyboardType: TextInputType.number,
                decoration:
                    const InputDecoration(labelText: 'Duration (minutes)'),
                validator: (value) {
                  final duration = int.tryParse(value?.trim() ?? '');
                  if (duration == null || duration < 0 || duration > 1440) {
                    return 'Enter a whole number from 0 to 1440';
                  }
                  return null;
                },
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Make this lesson a preview'),
                value: _isPreview,
                onChanged: _isBusy
                    ? null
                    : (value) => setState(() => _isPreview = value),
              ),
              const SizedBox(height: 12),
              PrimaryButton(
                label: _activeAction == 'lesson'
                    ? 'Creating lesson...'
                    : 'Create TEXT lesson',
                icon: Icons.menu_book_outlined,
                isLoading: _activeAction == 'lesson',
                onPressed: _isBusy ? null : _createLesson,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLessonPublishAction() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Lesson created: ${_lesson!.title}'),
            const SizedBox(height: 12),
            PrimaryButton(
              label: _activeAction == 'lesson'
                  ? 'Publishing lesson...'
                  : 'Publish lesson',
              icon: Icons.publish_outlined,
              isLoading: _activeAction == 'lesson',
              onPressed: _isBusy ? null : _publishLesson,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoursePublishAction() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Lesson published: ${_lesson!.title}'),
            const SizedBox(height: 12),
            PrimaryButton(
              label: _activeAction == 'course'
                  ? 'Publishing course...'
                  : 'Publish course',
              icon: Icons.publish_outlined,
              isLoading: _activeAction == 'course',
              onPressed: _isBusy ? null : _publishCourse,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    if (_isCoursePublished) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Course published successfully.'),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Done'),
              ),
            ],
          ),
        ),
      );
    }
    if (_course?.status == 'ARCHIVED') {
      return const MessageWidget(
        title: 'Course archived',
        message: 'Archived courses cannot be changed or published.',
        type: MessageType.info,
      );
    }
    if (_section == null) return _buildSectionForm();
    if (!_section!.isPublished) return _buildSectionPublishAction();
    if (_lesson == null) return _buildLessonForm();
    if (!_lesson!.isPublished) return _buildLessonPublishAction();
    return _buildCoursePublishAction();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Course setup'),
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context, _isCoursePublished),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _loadError != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: MessageWidget(
                        title: 'Unable to load course setup',
                        message: _loadError!,
                        type: MessageType.error,
                        actionLabel: 'Retry',
                        onActionPressed: _loadExistingSetup,
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 680),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildProgressCard(),
                            const SizedBox(height: 16),
                            _buildCurrentStep(),
                          ],
                        ),
                      ),
                    ),
                  ),
      ),
    );
  }
}
