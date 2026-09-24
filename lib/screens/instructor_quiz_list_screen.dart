import 'package:flutter/material.dart';

import '../core/course/course_service.dart';
import '../core/errors/api_exception.dart';
import '../core/models/quiz/quiz.dart';
import '../widgets/message_widget.dart';

class InstructorQuizListScreen extends StatefulWidget {
  const InstructorQuizListScreen({
    super.key,
    required this.courseId,
  });

  final String courseId;

  @override
  State<InstructorQuizListScreen> createState() =>
      _InstructorQuizListScreenState();
}

class _InstructorQuizListScreenState extends State<InstructorQuizListScreen> {
  final CourseService _courseService = CourseService();

  List<Quiz> _quizzes = [];

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadQuizzes();
  }

  Future<void> _loadQuizzes() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final quizzes = await _courseService.getInstructorQuizzes(
        widget.courseId,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _quizzes = quizzes;
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
        _errorMessage = 'Unable to load instructor quizzes. Please try again.';
      });
    }
  }

  Widget _buildQuizCard(Quiz quiz) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.pushNamed(
            context,
            '/instructor-quiz-detail',
            arguments: quiz.id,
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                quiz.title.isEmpty ? 'Quiz' : quiz.title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              if (quiz.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  quiz.description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(
                    avatar: Icon(
                      quiz.isPublished
                          ? Icons.public_outlined
                          : Icons.drafts_outlined,
                      size: 18,
                    ),
                    label: Text(
                      quiz.isPublished ? 'PUBLISHED' : 'DRAFT',
                    ),
                  ),
                  Chip(
                    avatar: const Icon(
                      Icons.flag_outlined,
                      size: 18,
                    ),
                    label: Text(
                      'Pass: '
                      '${quiz.passingScore.toStringAsFixed(0)}%',
                    ),
                  ),
                  Chip(
                    avatar: const Icon(
                      Icons.schedule_outlined,
                      size: 18,
                    ),
                    label: Text(
                      '${quiz.timeLimitMinutes} min',
                    ),
                  ),
                  Chip(
                    avatar: const Icon(
                      Icons.replay_outlined,
                      size: 18,
                    ),
                    label: Text(
                      '${quiz.maxAttempts} attempt(s)',
                    ),
                  ),
                ],
              ),
              if (quiz.section.title.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'Section: ${quiz.section.title}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
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
            title: 'Unable to load quizzes',
            message: _errorMessage!,
            type: MessageType.error,
            actionLabel: 'Retry',
            onActionPressed: _loadQuizzes,
          ),
        ),
      );
    }

    if (_quizzes.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadQuizzes,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          children: const [
            SizedBox(height: 80),
            MessageWidget(
              title: 'No quizzes found',
              message: 'This course does not have any quizzes yet.',
              type: MessageType.info,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadQuizzes,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          16,
          16,
          16,
          24,
        ),
        itemCount: _quizzes.length,
        separatorBuilder: (context, index) {
          return const SizedBox(height: 12);
        },
        itemBuilder: (context, index) {
          return _buildQuizCard(
            _quizzes[index],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Quizzes'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await Navigator.pushNamed(
            context,
            '/instructor-create-quiz',
            arguments: widget.courseId,
          );

          if (created == true && mounted) {
            _loadQuizzes();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Create Quiz'),
      ),
      body: SafeArea(
        child: _buildContent(),
      ),
    );
  }
}
