import 'package:flutter/material.dart';

import '../core/course/course_service.dart';
import '../core/course/quiz_attempt_page.dart';
import '../core/errors/api_exception.dart';
import '../core/models/quiz/quiz_attempt.dart';
import '../widgets/message_widget.dart';

class InstructorQuizAttemptsScreen extends StatefulWidget {
  const InstructorQuizAttemptsScreen({
    super.key,
    required this.quizId,
  });

  final String quizId;

  @override
  State<InstructorQuizAttemptsScreen> createState() =>
      _InstructorQuizAttemptsScreenState();
}

class _InstructorQuizAttemptsScreenState
    extends State<InstructorQuizAttemptsScreen> {
  final CourseService _courseService = CourseService();

  QuizAttemptPage? _attemptPage;

  bool _isLoading = true;
  bool _isChangingPage = false;
  String? _errorMessage;

  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    _loadAttempts();
  }

  Future<void> _loadAttempts({
    int page = 1,
  }) async {
    if (page == _currentPage) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    } else {
      setState(() {
        _isChangingPage = true;
        _errorMessage = null;
      });
    }

    try {
      final attemptPage = await _courseService.getInstructorAttempts(
        quizId: widget.quizId,
        page: page,
        limit: 20,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _attemptPage = attemptPage;
        _currentPage = page;
        _isLoading = false;
        _isChangingPage = false;
      });
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _isChangingPage = false;
        _errorMessage = error.message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _isChangingPage = false;
        _errorMessage = 'Unable to load quiz attempts. Please try again.';
      });
    }
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

  Color _statusColor(BuildContext context, QuizAttempt attempt) {
    final colorScheme = Theme.of(context).colorScheme;

    switch (attempt.status) {
      case 'SUBMITTED':
      case 'COMPLETED':
        return colorScheme.primary;

      case 'IN_PROGRESS':
        return colorScheme.secondary;

      case 'TIMED_OUT':
        return colorScheme.error;

      default:
        return colorScheme.outline;
    }
  }

  Widget _buildAttemptCard(QuizAttempt attempt) {
    final statusColor = _statusColor(context, attempt);

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
                  child: Text(
                    '${attempt.attemptNumber}',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Student: ${attempt.studentDisplayName}',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
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
                      const SizedBox(height: 4),
                      Text(
                        'Attempt #${attempt.attemptNumber}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                Chip(
                  label: Text(
                    attempt.status.isEmpty ? 'UNKNOWN' : attempt.status,
                  ),
                  side: BorderSide(
                    color: statusColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  avatar: const Icon(
                    Icons.star_outline,
                    size: 18,
                  ),
                  label: Text(
                    'Score: '
                    '${attempt.score.toStringAsFixed(0)}'
                    ' / '
                    '${attempt.totalMarks.toStringAsFixed(0)}',
                  ),
                ),
                Chip(
                  avatar: const Icon(
                    Icons.percent,
                    size: 18,
                  ),
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
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/instructor-quiz-attempt-review',
                  arguments: {
                    'quizId': widget.quizId,
                    'attempt': attempt,
                  },
                );
              },
              icon: const Icon(Icons.rate_review_outlined),
              label: const Text('Review Attempt'),
            ),
            Text(
              'Started: ${_formatDate(attempt.startedAt)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            Text(
              'Submitted: ${_formatDate(attempt.submittedAt)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPagination() {
    final pagination = _attemptPage?.pagination;

    if (pagination == null || pagination.totalPages <= 1) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        16,
        4,
        16,
        24,
      ),
      child: Row(
        children: [
          OutlinedButton.icon(
            onPressed: !pagination.hasPreviousPage || _isChangingPage
                ? null
                : () {
                    _loadAttempts(
                      page: _currentPage - 1,
                    );
                  },
            icon: const Icon(
              Icons.chevron_left,
            ),
            label: const Text('Previous'),
          ),
          const Spacer(),
          Text(
            'Page ${pagination.page} of '
            '${pagination.totalPages}',
          ),
          const Spacer(),
          OutlinedButton.icon(
            onPressed: !pagination.hasNextPage || _isChangingPage
                ? null
                : () {
                    _loadAttempts(
                      page: _currentPage + 1,
                    );
                  },
            icon: const Icon(
              Icons.chevron_right,
            ),
            label: const Text('Next'),
          ),
        ],
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
            title: 'Unable to load attempts',
            message: _errorMessage!,
            type: MessageType.error,
            actionLabel: 'Retry',
            onActionPressed: _loadAttempts,
          ),
        ),
      );
    }

    final attemptPage = _attemptPage;

    if (attemptPage == null || attemptPage.attempts.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadAttempts,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          children: const [
            SizedBox(height: 80),
            MessageWidget(
              title: 'No attempts yet',
              message:
                  'No students have submitted an attempt for this quiz yet.',
              type: MessageType.info,
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadAttempts,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                16,
                16,
                16,
                12,
              ),
              itemCount: attemptPage.attempts.length,
              separatorBuilder: (context, index) {
                return const SizedBox(height: 12);
              },
              itemBuilder: (context, index) {
                return _buildAttemptCard(
                  attemptPage.attempts[index],
                );
              },
            ),
          ),
        ),
        if (_isChangingPage)
          const LinearProgressIndicator(
            minHeight: 2,
          ),
        _buildPagination(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz Attempts'),
      ),
      body: SafeArea(
        child: _buildContent(),
      ),
    );
  }
}
