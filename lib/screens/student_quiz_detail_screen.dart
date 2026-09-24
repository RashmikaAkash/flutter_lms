import 'package:flutter/material.dart';

import '../core/course/course_service.dart';
import '../core/errors/api_exception.dart';
import '../core/models/quiz/quiz_attempt.dart';
import '../core/models/quiz/quiz_detail.dart';
import '../widgets/message_widget.dart';
import '../core/models/quiz/quiz_answer.dart';
import '../core/models/quiz/quiz_submission_result.dart';
import 'dart:async';

class StudentQuizDetailScreen extends StatefulWidget {
  const StudentQuizDetailScreen({
    super.key,
    required this.quizId,
  });

  final String quizId;

  @override
  State<StudentQuizDetailScreen> createState() =>
      _StudentQuizDetailScreenState();
}

class _StudentQuizDetailScreenState extends State<StudentQuizDetailScreen> {
  final CourseService _courseService = CourseService();

  QuizDetail? _quizDetail;
  QuizAttempt? _quizAttempt;
  List<QuizAttempt> _attempts = [];
  QuizSubmissionResult? _submissionResult;

  bool _isLoading = true;
  bool _isStarting = false;
  bool _isSubmitting = false;
  String? _errorMessage;
  String? _startAttemptError;
  Duration? _remainingTime;
  Timer? _quizTimer;

  final Map<String, List<String>> _selectedAnswers = {};

  @override
  void initState() {
    super.initState();
    _loadQuiz();
  }

  Future<void> _loadQuiz() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _courseService.getStudentQuiz(
        widget.quizId,
      );

      final attemptsResult = await _courseService.getStudentAttempts(
        quizId: widget.quizId,
        page: 1,
        limit: 20,
      );

      final attempts = [...attemptsResult.attempts]..sort(
          (a, b) => b.attemptNumber.compareTo(a.attemptNumber),
        );

      if (!mounted) {
        return;
      }

      setState(() {
        _quizDetail = result;
        _attempts = attempts;
        _quizAttempt = attempts.isEmpty ? null : attempts.first;
      });

      final latestAttempt = attempts.isEmpty ? null : attempts.first;

      if (latestAttempt != null && latestAttempt.isInProgress) {
        _startQuizTimer(latestAttempt);
      } else {
        _stopQuizTimer();
        _remainingTime = null;
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
        _errorMessage = 'Unable to load quiz. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _startAttempt() async {
    if (_isStarting) {
      return;
    }

    final quiz = _quizDetail?.quiz;

    if (quiz == null) {
      return;
    }

    if (_attempts.length >= quiz.maxAttempts) {
      setState(() {
        _startAttemptError = 'You have used all available quiz attempts.';
      });

      return;
    }

    setState(() {
      _isStarting = true;
      _startAttemptError = null;
      _submissionResult = null;
      _selectedAnswers.clear();
    });

    try {
      final attempt = await _courseService.startQuizAttempt(
        widget.quizId,
      );

      if (!mounted) {
        return;
      }

      final updatedAttempts = [..._attempts];

      final existingIndex = updatedAttempts.indexWhere(
        (item) => item.id == attempt.id,
      );

      if (existingIndex >= 0) {
        updatedAttempts[existingIndex] = attempt;
      } else {
        updatedAttempts.add(attempt);
      }

      updatedAttempts.sort(
        (a, b) => b.attemptNumber.compareTo(a.attemptNumber),
      );

      setState(() {
        _attempts = updatedAttempts;
        _quizAttempt = attempt;
      });

      _startQuizTimer(attempt);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Quiz attempt started successfully.'),
        ),
      );
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _startAttemptError = error.message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _startAttemptError = 'Unable to start quiz attempt. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isStarting = false;
        });
      }
    }
  }

  void _startQuizTimer(QuizAttempt attempt) {
    _quizTimer?.cancel();

    final quiz = _quizDetail?.quiz;
    final startedAt = attempt.startedAt;

    if (quiz == null ||
        startedAt == null ||
        !attempt.isInProgress ||
        quiz.timeLimitMinutes <= 0) {
      _remainingTime = null;
      return;
    }

    final totalDuration = Duration(
      minutes: quiz.timeLimitMinutes,
    );

    void updateRemainingTime() {
      final elapsed = DateTime.now().toUtc().difference(
            startedAt.toUtc(),
          );

      final remaining = totalDuration - elapsed;

      if (remaining <= Duration.zero) {
        _quizTimer?.cancel();

        if (mounted) {
          setState(() {
            _remainingTime = Duration.zero;
          });

          _submitAttempt();
        }

        return;
      }

      if (mounted) {
        setState(() {
          _remainingTime = remaining;
        });
      }
    }

    updateRemainingTime();

    _quizTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => updateRemainingTime(),
    );
  }

  void _stopQuizTimer() {
    _quizTimer?.cancel();
    _quizTimer = null;
  }

  Future<void> _submitAttempt() async {
    final attempt = _quizAttempt;

    if (attempt == null || _isSubmitting) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final answers = _selectedAnswers.entries
          .map(
            (entry) => QuizAnswer(
              questionId: entry.key,
              selectedOptionIds: entry.value,
            ),
          )
          .toList();

      final result = await _courseService.submitQuizAttempt(
        attempt.id,
        answers,
      );

      _stopQuizTimer();

      if (!mounted) {
        return;
      }

      setState(() {
        _submissionResult = result;
        _quizAttempt = result.attempt;

        final updatedAttempts = [..._attempts];
        final existingIndex = updatedAttempts.indexWhere(
          (attempt) => attempt.id == result.attempt.id,
        );

        if (existingIndex >= 0) {
          updatedAttempts[existingIndex] = result.attempt;
        } else {
          updatedAttempts.add(result.attempt);
        }

        updatedAttempts.sort(
          (a, b) => b.attemptNumber.compareTo(a.attemptNumber),
        );

        _attempts = updatedAttempts;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Quiz submitted successfully.'),
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
            'Unable to submit quiz. Please try again.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Widget _buildQuizHeader() {
    final quiz = _quizDetail!.quiz;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              quiz.title.isEmpty ? 'Quiz' : quiz.title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            if (quiz.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                quiz.description,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
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
                    '${quiz.timeLimitMinutes} minute(s)',
                  ),
                ),
                Chip(
                  avatar: const Icon(
                    Icons.refresh_outlined,
                    size: 18,
                  ),
                  label: Text(
                    '${quiz.maxAttempts} attempt(s)',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttemptCard() {
    final attempt = _quizAttempt!;
    final isSubmitted = !attempt.isInProgress;
    final submissionResult = _submissionResult;

    final score = submissionResult?.score ?? attempt.score;
    final totalMarks = submissionResult?.totalMarks ?? attempt.totalMarks;
    final percentage = submissionResult?.percentage ?? attempt.percentage;
    final passed = submissionResult?.passed ?? attempt.passed;
    final timedOut = submissionResult?.timedOut ?? false;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  child: Icon(
                    isSubmitted
                        ? Icons.check_circle_outline
                        : Icons.play_arrow_rounded,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    isSubmitted
                        ? 'Quiz Completed'
                        : 'Attempt #${attempt.attemptNumber}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Status: ${attempt.status.isEmpty ? 'IN_PROGRESS' : attempt.status}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (!isSubmitted && _remainingTime != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.timer_outlined,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Time remaining',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const Spacer(),
                    Text(
                      _formatRemainingTime(_remainingTime!),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ),
            ],
            if (isSubmitted) ...[
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
                      'Score: ${score.toStringAsFixed(0)}',
                    ),
                  ),
                  Chip(
                    avatar: const Icon(
                      Icons.percent,
                      size: 18,
                    ),
                    label: Text(
                      'Percentage: '
                      '${percentage.toStringAsFixed(0)}%',
                    ),
                  ),
                  Chip(
                    avatar: const Icon(
                      Icons.menu_book_outlined,
                      size: 18,
                    ),
                    label: Text(
                      'Total marks: '
                      '${totalMarks.toStringAsFixed(0)}',
                    ),
                  ),
                  Chip(
                    avatar: Icon(
                      passed
                          ? Icons.check_circle_outline
                          : Icons.cancel_outlined,
                      size: 18,
                    ),
                    label: Text(
                      passed ? 'Passed' : 'Not Passed',
                    ),
                  ),
                  if (timedOut)
                    const Chip(
                      avatar: Icon(
                        Icons.timer_off_outlined,
                        size: 18,
                      ),
                      label: Text('Timed Out'),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatRemainingTime(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    }

    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _confirmSubmitAttempt() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Submit quiz?'),
        content: const Text(
          'Once submitted, your answers cannot be changed. Submit this attempt now?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Continue quiz'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Submit quiz'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) await _submitAttempt();
  }

  Widget _buildSubmitButton() {
    if (_quizAttempt == null || !_quizAttempt!.isInProgress) {
      return const SizedBox.shrink();
    }

    return FilledButton.icon(
      onPressed: _isSubmitting ? null : _confirmSubmitAttempt,
      icon: _isSubmitting
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
              ),
            )
          : const Icon(
              Icons.send_rounded,
            ),
      label: Text(
        _isSubmitting ? 'Submitting...' : 'Submit Quiz',
      ),
    );
  }

  Widget _buildAttemptHistory() {
    if (_attempts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Attempt History',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            ..._attempts.map(
              (attempt) {
                final isSubmitted = !attempt.isInProgress;

                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        child: Icon(
                          isSubmitted
                              ? Icons.check_circle_outline
                              : Icons.play_arrow_rounded,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Attempt #${attempt.attemptNumber}',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              attempt.status.isEmpty
                                  ? 'IN_PROGRESS'
                                  : attempt.status,
                            ),
                            if (isSubmitted) ...[
                              const SizedBox(height: 3),
                              Text(
                                '${attempt.percentage.toStringAsFixed(0)}% • '
                                '${attempt.passed ? 'Passed' : 'Not Passed'}',
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
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
    final selectedOptionIds = _selectedAnswers[question.id] ?? <String>[];

    final isSubmitted = _quizAttempt != null && !_quizAttempt!.isInProgress;

    final supportsSingleSelection = question.questionType == 'SINGLE_CHOICE' ||
        question.questionType == 'TRUE_FALSE';

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Question ${index + 1}',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            Text(
              question.questionText,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '${question.marks} mark(s) • ${question.questionType}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            if (supportsSingleSelection)
              ...question.options.map(
                (option) {
                  final isSelected = selectedOptionIds.contains(option.id);

                  return Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.outlineVariant,
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: RadioListTile<String>(
                      value: option.id,
                      groupValue: selectedOptionIds.isEmpty
                          ? null
                          : selectedOptionIds.first,
                      onChanged: isSubmitted
                          ? null
                          : (value) {
                              if (value == null) {
                                return;
                              }

                              setState(() {
                                _selectedAnswers[question.id] = [value];
                              });
                            },
                      title: Text(option.text),
                      secondary: CircleAvatar(
                        radius: 17,
                        child: Text(
                          option.id,
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                    ),
                  );
                },
              )
            else
              const MessageWidget(
                title: 'Question type not supported yet',
                message:
                    'Answer selection for this question type will be added after the backend contract is verified.',
                type: MessageType.info,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStartSection() {
    final quiz = _quizDetail!.quiz;
    final currentAttempt = _quizAttempt;
    final attemptsUsed = _attempts.length;
    final hasAttemptsRemaining = attemptsUsed < quiz.maxAttempts;

    if (currentAttempt != null && currentAttempt.isInProgress) {
      return _buildAttemptCard();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (currentAttempt != null) ...[
          _buildAttemptCard(),
          const SizedBox(height: 12),
          Text(
            'Attempts used: $attemptsUsed/${quiz.maxAttempts}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
        ],
        if (_startAttemptError != null) ...[
          MessageWidget(
            title: 'Unable to start quiz',
            message: _startAttemptError!,
            type: MessageType.error,
          ),
          const SizedBox(height: 12),
        ],
        if (hasAttemptsRemaining)
          FilledButton.icon(
            onPressed: _isStarting ? null : _startAttempt,
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
              _isStarting
                  ? 'Starting Quiz...'
                  : currentAttempt == null
                      ? 'Start Quiz'
                      : 'Start New Attempt',
            ),
          )
        else
          const MessageWidget(
            title: 'No attempts remaining',
            message: 'You have used all available attempts for this quiz.',
            type: MessageType.info,
          ),
      ],
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
            title: 'Unable to load quiz',
            message: _errorMessage!,
            type: MessageType.error,
            actionLabel: 'Retry',
            onActionPressed: _loadQuiz,
          ),
        ),
      );
    }

    final detail = _quizDetail;

    if (detail == null) {
      return const Center(
        child: MessageWidget(
          title: 'Quiz unavailable',
          message: 'Quiz details are not available.',
          type: MessageType.info,
        ),
      );
    }

    final questions = [...detail.questions]..sort(
        (a, b) => a.order.compareTo(b.order),
      );

    final hasStarted = _quizAttempt != null;

    return RefreshIndicator(
      onRefresh: _loadQuiz,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          16,
          16,
          16,
          24,
        ),
        children: [
          _buildQuizHeader(),
          const SizedBox(height: 16),
          _buildStartSection(),
          if (hasStarted) ...[
            const SizedBox(height: 16),
            _buildAttemptHistory(),
          ],
          if (hasStarted) ...[
            const SizedBox(height: 18),
            Text(
              '${questions.length} question(s)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            if (questions.isEmpty)
              const MessageWidget(
                title: 'No questions available',
                message: 'This quiz does not have any questions yet.',
                type: MessageType.info,
              )
            else ...[
              ...questions.asMap().entries.map(
                    (entry) => _buildQuestionCard(
                      entry.value,
                      entry.key,
                    ),
                  ),
              const SizedBox(height: 8),
              _buildSubmitButton(),
            ],
          ],
        ],
      ),
    );
  }

  @override
  void dispose() {
    _stopQuizTimer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz Details'),
      ),
      body: SafeArea(
        child: _buildContent(),
      ),
    );
  }
}
