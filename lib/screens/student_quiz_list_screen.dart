import 'package:flutter/material.dart';

import '../core/course/course_service.dart';
import '../core/errors/api_exception.dart';
import '../core/models/quiz/quiz.dart';
import '../widgets/message_widget.dart';

class StudentQuizListScreen extends StatefulWidget {
  const StudentQuizListScreen({
    super.key,
    required this.courseId,
  });

  final String courseId;

  @override
  State<StudentQuizListScreen> createState() => _StudentQuizListScreenState();
}

class _StudentQuizListScreenState extends State<StudentQuizListScreen> {
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
      final quizzes = await _courseService.getStudentQuizzes(
        widget.courseId,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _quizzes = quizzes;
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
        _errorMessage = 'Unable to load quizzes. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildQuizCard(Quiz quiz) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: () {
          Navigator.pushNamed(
            context,
            '/student-quiz-detail',
            arguments: quiz.id,
          );
        },
        contentPadding: const EdgeInsets.all(16),
        leading: const CircleAvatar(
          child: Icon(
            Icons.quiz_outlined,
          ),
        ),
        title: Text(
          quiz.title.isEmpty ? 'Quiz' : quiz.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (quiz.description.isNotEmpty)
                Text(
                  quiz.description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 8),
              Text(
                'Passing score: '
                '${quiz.passingScore.toStringAsFixed(0)}%',
              ),
              Text(
                'Time limit: ${quiz.timeLimitMinutes} minute(s)',
              ),
              Text(
                'Maximum attempts: ${quiz.maxAttempts}',
              ),
              if (quiz.section.title.isNotEmpty)
                Text(
                  'Section: ${quiz.section.title}',
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
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: MessageWidget(
            title: 'No quizzes available',
            message: 'This course does not have any published quizzes yet.',
            type: MessageType.info,
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadQuizzes,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            '${_quizzes.length} quiz(es)',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 14),
          ..._quizzes.map(_buildQuizCard),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quizzes'),
      ),
      body: SafeArea(
        child: _buildContent(),
      ),
    );
  }
}
