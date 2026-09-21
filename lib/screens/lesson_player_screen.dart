import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

import '../core/course/course_service.dart';
import '../core/errors/api_exception.dart';
import '../core/models/course/course_lesson.dart';
import '../core/models/course/course_progress.dart';
import '../core/models/course/lesson_progress.dart';
import '../widgets/message_widget.dart';

class LessonPlayerScreen extends StatefulWidget {
  const LessonPlayerScreen({
    super.key,
    required this.lessonId,
  });

  final String lessonId;

  @override
  State<LessonPlayerScreen> createState() => _LessonPlayerScreenState();
}

class _LessonPlayerScreenState extends State<LessonPlayerScreen> {
  final CourseService _courseService = CourseService();

  CourseLesson? _lesson;
  LessonProgress? _lessonProgress;
  CourseProgress? _courseProgress;

  VideoPlayerController? _videoController;

  bool _isLoading = true;
  bool _isStarting = false;
  bool _isCompleting = false;

  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadLesson();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _loadLesson() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final lesson = await _courseService.getLesson(
        widget.lessonId,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _lesson = lesson;
      });

      if (lesson.isVideo &&
          lesson.videoUrl != null &&
          lesson.videoUrl!.isNotEmpty) {
        await _initializeVideo(lesson.videoUrl!);
      }
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
        _errorMessage = 'Unable to load this lesson. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _initializeVideo(String url) async {
    final controller = VideoPlayerController.networkUrl(
      Uri.parse(url),
    );

    try {
      await controller.initialize();

      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _videoController = controller;
      });
    } catch (_) {
      await controller.dispose();

      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = 'Unable to load the video. Please try again.';
      });
    }
  }

  Future<void> _startLesson() async {
    if (_isStarting || _lesson == null) {
      return;
    }

    setState(() {
      _isStarting = true;
    });

    try {
      final progress = await _courseService.startLesson(
        _lesson!.id,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _lessonProgress = progress;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lesson started.'),
        ),
      );
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
            'Unable to start the lesson. Please try again.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isStarting = false;
        });
      }
    }
  }

  Future<void> _completeLesson() async {
    if (_isCompleting || _lesson == null) {
      return;
    }

    setState(() {
      _isCompleting = true;
    });

    try {
      final result = await _courseService.completeLesson(
        _lesson!.id,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _lessonProgress = result.lessonProgress;
        _courseProgress = result.courseProgress;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lesson completed successfully.'),
        ),
      );
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
            'Unable to complete the lesson. Please try again.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCompleting = false;
        });
      }
    }
  }

  Future<void> _openDocument(String url) async {
    final uri = Uri.tryParse(url);

    if (uri == null) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid document URL.'),
        ),
      );

      return;
    }

    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to open this document.',
          ),
        ),
      );
    }
  }

  Widget _buildLessonTypeChip() {
    final lesson = _lesson!;
    final colorScheme = Theme.of(context).colorScheme;

    return Chip(
      avatar: Icon(
        lesson.isText
            ? Icons.article_outlined
            : lesson.isVideo
                ? Icons.play_circle_outline
                : Icons.description_outlined,
        size: 18,
      ),
      label: Text(lesson.lessonType),
      backgroundColor: colorScheme.secondaryContainer,
    );
  }

  Widget _buildVideoPlayer() {
    final controller = _videoController;

    if (controller == null || !controller.value.isInitialized) {
      return const SizedBox(
        height: 220,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final aspectRatio = controller.value.aspectRatio > 0
        ? controller.value.aspectRatio
        : 16 / 9;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: aspectRatio,
            child: VideoPlayer(controller),
          ),
          Container(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Row(
              children: [
                IconButton(
                  onPressed: () {
                    setState(() {
                      if (controller.value.isPlaying) {
                        controller.pause();
                      } else {
                        controller.play();
                      }
                    });
                  },
                  icon: Icon(
                    controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                  ),
                ),
                Expanded(
                  child: VideoProgressIndicator(
                    controller,
                    allowScrubbing: true,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLessonContent() {
    final lesson = _lesson!;

    if (lesson.isText) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: SelectableText(
            lesson.textContent?.isNotEmpty == true
                ? lesson.textContent!
                : 'No text content is available.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  height: 1.6,
                ),
          ),
        ),
      );
    }

    if (lesson.isVideo) {
      return _buildVideoPlayer();
    }

    if (lesson.isDocument) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              const Icon(
                Icons.description_outlined,
                size: 52,
              ),
              const SizedBox(height: 12),
              Text(
                lesson.documentName?.isNotEmpty == true
                    ? lesson.documentName!
                    : 'Course Document',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed:
                    lesson.documentUrl != null && lesson.documentUrl!.isNotEmpty
                        ? () => _openDocument(
                              lesson.documentUrl!,
                            )
                        : null,
                icon: const Icon(
                  Icons.open_in_new,
                ),
                label: const Text('Open Document'),
              ),
            ],
          ),
        ),
      );
    }

    return const MessageWidget(
      title: 'Unsupported lesson type',
      message: 'This lesson type is not supported by the mobile app.',
      type: MessageType.warning,
    );
  }

  Widget _buildProgressCard() {
    final progress = _lessonProgress;

    if (progress == null && _courseProgress == null) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (progress != null) ...[
              Text(
                'Lesson Status',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 6),
              Text(progress.status),
            ],
            if (_courseProgress != null) ...[
              const SizedBox(height: 14),
              Text(
                'Course Progress',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: _courseProgress!.progressPercentage / 100,
                minHeight: 8,
                borderRadius: BorderRadius.circular(10),
              ),
              const SizedBox(height: 8),
              Text(
                '${_courseProgress!.progressPercentage}'
                '% completed • '
                '${_courseProgress!.completedLessons}/'
                '${_courseProgress!.totalLessons} lessons',
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_lesson == null) {
      return const SizedBox.shrink();
    }

    final lesson = _lesson!;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        16,
        16,
        16,
        120,
      ),
      children: [
        Text(
          lesson.title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildLessonTypeChip(),
            if (lesson.durationMinutes > 0)
              Chip(
                avatar: const Icon(
                  Icons.schedule_outlined,
                  size: 18,
                ),
                label: Text(
                  '${lesson.durationMinutes} min',
                ),
              ),
            if (lesson.isPreview)
              const Chip(
                avatar: Icon(
                  Icons.visibility_outlined,
                  size: 18,
                ),
                label: Text('Preview'),
              ),
          ],
        ),
        if (lesson.description.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            lesson.description,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
        const SizedBox(height: 20),
        if (_errorMessage == null) _buildLessonContent(),
        const SizedBox(height: 20),
        _buildProgressCard(),
      ],
    );
  }

  Widget _buildBottomAction() {
    if (_lesson == null) {
      return const SizedBox.shrink();
    }

    final isCompleted = _lessonProgress?.isCompleted == true;
    final hasStarted = _lessonProgress != null;

    if (isCompleted) {
      return FilledButton.icon(
        onPressed: null,
        icon: const Icon(
          Icons.check_circle,
        ),
        label: const Text('Lesson Completed'),
      );
    }

    if (!hasStarted) {
      return FilledButton.icon(
        onPressed: _isStarting ? null : _startLesson,
        icon: _isStarting
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              )
            : const Icon(
                Icons.play_arrow_rounded,
              ),
        label: Text(
          _isStarting ? 'Starting...' : 'Start Lesson',
        ),
      );
    }

    return FilledButton.icon(
      onPressed: _isCompleting ? null : _completeLesson,
      icon: _isCompleting
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
              ),
            )
          : const Icon(
              Icons.check_circle_outline,
            ),
      label: Text(
        _isCompleting ? 'Completing...' : 'Complete Lesson',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lesson'),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : _errorMessage != null && _lesson == null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: MessageWidget(
                        title: 'Unable to open lesson',
                        message: _errorMessage!,
                        type: MessageType.error,
                        actionLabel: 'Retry',
                        onActionPressed: _loadLesson,
                      ),
                    ),
                  )
                : Stack(
                    children: [
                      _buildContent(),
                      if (_lesson != null)
                        Positioned(
                          left: 16,
                          right: 16,
                          bottom: 16,
                          child: _buildBottomAction(),
                        ),
                    ],
                  ),
      ),
    );
  }
}
