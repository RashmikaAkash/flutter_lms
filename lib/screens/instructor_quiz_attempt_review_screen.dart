import 'package:flutter/material.dart';

import '../core/course/course_service.dart';
import '../core/errors/api_exception.dart';
import '../core/models/quiz/quiz_attempt.dart';
import '../core/models/quiz/quiz_detail.dart';
import '../widgets/message_widget.dart';

class InstructorQuizAttemptReviewScreen extends StatefulWidget {
  const InstructorQuizAttemptReviewScreen({
    super.key,
    required this.quizId,
    required this.attempt,
  });

  final String quizId;
  final QuizAttempt attempt;

  @override
  State<InstructorQuizAttemptReviewScreen> createState() =>
      _InstructorQuizAttemptReviewScreenState();
}

class _InstructorQuizAttemptReviewScreenState
    extends State<InstructorQuizAttemptReviewScreen> {
  final CourseService _courseService = CourseService();

  QuizDetail? _quizDetail;

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadReview();
  }

  Future<void> _loadReview() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final quizDetail = await _courseService.getInstructorQuiz(
        widget.quizId,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _quizDetail = quizDetail;
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
        _errorMessage = 'Unable to load quiz review. Please try again.';
      });
    }
  }

  QuizAttemptAnswer? _findAnswer(String questionId) {
    for (final answer in widget.attempt.answers) {
      if (answer.questionId == questionId) {
        return answer;
      }
    }

    return null;
  }

  bool _isCorrect(
    QuizQuestion question,
    QuizAttemptAnswer? answer,
  ) {
    if (answer == null) {
      return false;
    }

    final selectedIds = [...answer.selectedOptionIds]..sort();
    final correctIds = [...question.correctOptionIds]..sort();

    if (selectedIds.length != correctIds.length) {
      return false;
    }

    for (var index = 0; index < selectedIds.length; index++) {
      if (selectedIds[index] != correctIds[index]) {
        return false;
      }
    }

    return true;
  }

  String _formatDate(DateTime? date) {
    if (date == null) {
      return 'Not available';
    }

    final localDate = date.toLocal();

    final day = localDate.day.toString().padLeft(2, '0');
    final month = localDate.month.toString().padLeft(2, '0');
    final year = localDate.year.toString();

    final hour = localDate.hour.toString().padLeft(2, '0');
    final minute = localDate.minute.toString().padLeft(2, '0');

    return '$year-$month-$day $hour:$minute';
  }

  Widget _buildAttemptSummary() {
    final attempt = widget.attempt;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Student Attempt',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              attempt.studentDisplayName,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            if (attempt.studentEmail.isNotEmpty) ...[
              const SizedBox(height: 3),
              Text(
                attempt.studentEmail,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  label: Text(
                    'Attempt #${attempt.attemptNumber}',
                  ),
                ),
                Chip(
                  label: Text(
                    attempt.status.isEmpty ? 'UNKNOWN' : attempt.status,
                  ),
                ),
                Chip(
                  label: Text(
                    'Score: '
                    '${attempt.score.toStringAsFixed(0)} / '
                    '${attempt.totalMarks.toStringAsFixed(0)}',
                  ),
                ),
                Chip(
                  label: Text(
                    '${attempt.percentage.toStringAsFixed(0)}%',
                  ),
                ),
                Chip(
                  avatar: Icon(
                    attempt.passed
                        ? Icons.check_circle_outline
                        : Icons.cancel_outlined,
                    size: 18,
                  ),
                  label: Text(
                    attempt.passed ? 'Passed' : 'Not Passed',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Started: ${_formatDate(attempt.startedAt)}',
            ),
            const SizedBox(height: 4),
            Text(
              'Submitted: ${_formatDate(attempt.submittedAt)}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionCard(
    QuizQuestion question,
    int index,
  ) {
    final answer = _findAnswer(question.id);
    final selectedIds = answer?.selectedOptionIds ?? const <String>[];
    final hasAnswer = answer != null && selectedIds.isNotEmpty;
    final isCorrect = _isCorrect(question, answer);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 16,
                  child: Text('${index + 1}'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    question.questionText,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  label: Text(question.questionType),
                ),
                Chip(
                  label: Text('${question.marks} mark(s)'),
                ),
                Chip(
                  avatar: Icon(
                    hasAnswer && isCorrect
                        ? Icons.check_circle_outline
                        : hasAnswer
                            ? Icons.cancel_outlined
                            : Icons.help_outline,
                    size: 18,
                  ),
                  label: Text(
                    !hasAnswer
                        ? 'Not Answered'
                        : isCorrect
                            ? 'Correct'
                            : 'Incorrect',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (question.options.isEmpty)
              const Text('No options available.')
            else
              ...question.options.map(
                (option) {
                  final isSelected = selectedIds.contains(option.id);
                  final isCorrectOption =
                      question.correctOptionIds.contains(option.id);

                  return Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : isCorrectOption
                                ? Theme.of(context).colorScheme.secondary
                                : Theme.of(context).colorScheme.outlineVariant,
                        width: isSelected || isCorrectOption ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${option.id}. ${option.text}',
                          ),
                        ),
                        if (isSelected)
                          const Padding(
                            padding: EdgeInsets.only(left: 8),
                            child: Icon(
                              Icons.radio_button_checked,
                            ),
                          ),
                        if (isCorrectOption)
                          const Padding(
                            padding: EdgeInsets.only(left: 8),
                            child: Icon(
                              Icons.check_circle,
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            const SizedBox(height: 4),
            if (question.correctOptionIds.isNotEmpty)
              Text(
                'Correct answer: '
                '${question.correctOptionIds.join(', ')}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            if (hasAnswer)
              Text(
                'Student answer: ${selectedIds.join(', ')}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
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
            title: 'Unable to load review',
            message: _errorMessage!,
            type: MessageType.error,
            actionLabel: 'Retry',
            onActionPressed: _loadReview,
          ),
        ),
      );
    }

    final quizDetail = _quizDetail;

    if (quizDetail == null) {
      return const Center(
        child: MessageWidget(
          title: 'Review unavailable',
          message: 'Quiz review data is not available.',
          type: MessageType.info,
        ),
      );
    }

    final questions = [...quizDetail.questions]..sort(
        (a, b) => a.order.compareTo(b.order),
      );

    return RefreshIndicator(
      onRefresh: _loadReview,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          16,
          16,
          16,
          24,
        ),
        children: [
          _buildAttemptSummary(),
          const SizedBox(height: 16),
          Text(
            'Answer Review',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 12),
          if (questions.isEmpty)
            const MessageWidget(
              title: 'No questions',
              message: 'This quiz does not contain any questions.',
              type: MessageType.info,
            )
          else
            ...questions.asMap().entries.map(
              (entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildQuestionCard(
                    entry.value,
                    entry.key,
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Attempt'),
      ),
      body: SafeArea(
        child: _buildContent(),
      ),
    );
  }
}
