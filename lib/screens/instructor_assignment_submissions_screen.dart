import 'package:flutter/material.dart';

import '../core/course/course_service.dart';
import '../core/errors/api_exception.dart';
import '../core/models/assignment/instructor_assignment_submission.dart';
import '../core/models/assignment/instructor_assignment_submission_page.dart';
import '../widgets/message_widget.dart';

class InstructorAssignmentSubmissionsScreen extends StatefulWidget {
  const InstructorAssignmentSubmissionsScreen({
    super.key,
    required this.assignmentId,
  });

  final String assignmentId;

  @override
  State<InstructorAssignmentSubmissionsScreen> createState() =>
      _InstructorAssignmentSubmissionsScreenState();
}

class _InstructorAssignmentSubmissionsScreenState
    extends State<InstructorAssignmentSubmissionsScreen> {
  final CourseService _courseService = CourseService();

  InstructorAssignmentSubmissionPage? _submissionPage;

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSubmissions();
  }

  Future<void> _loadSubmissions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _courseService.getInstructorAssignmentSubmissions(
        assignmentId: widget.assignmentId,
        page: 1,
        limit: 20,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _submissionPage = result;
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
        _errorMessage =
            'Unable to load assignment submissions. Please try again.';
      });
    }
  }

  String _formatDate(DateTime dateTime) {
    final localDate = dateTime.toLocal();

    final day = localDate.day.toString().padLeft(2, '0');
    final month = localDate.month.toString().padLeft(2, '0');
    final year = localDate.year.toString();

    final hour = localDate.hour.toString().padLeft(2, '0');
    final minute = localDate.minute.toString().padLeft(2, '0');

    return '$year-$month-$day $hour:$minute';
  }

  Widget _buildSubmissionCard(
    InstructorAssignmentSubmission submission,
  ) {
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
                    submission.student.firstName.isNotEmpty
                        ? submission.student.firstName[0].toUpperCase()
                        : '?',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        submission.student.fullName,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        submission.student.email,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
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
                  avatar: Icon(
                    submission.isGraded
                        ? Icons.check_circle_outline
                        : Icons.pending_outlined,
                    size: 18,
                  ),
                  label: Text(
                    submission.status.isEmpty ? 'SUBMITTED' : submission.status,
                  ),
                ),
                Chip(
                  avatar: const Icon(
                    Icons.schedule_outlined,
                    size: 18,
                  ),
                  label: Text(
                    _formatDate(submission.submittedAt),
                  ),
                ),
              ],
            ),
            if (submission.textAnswer.trim().isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Text Answer',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  submission.textAnswer,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
            if (submission.fileName != null &&
                submission.fileName!.trim().isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Submitted File',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.insert_drive_file_outlined,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        submission.fileName!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (submission.fileUrl != null &&
                submission.fileUrl!.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              SelectableText(
                submission.fileUrl!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
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
            title: 'Unable to load submissions',
            message: _errorMessage!,
            type: MessageType.error,
            actionLabel: 'Retry',
            onActionPressed: _loadSubmissions,
          ),
        ),
      );
    }

    final page = _submissionPage;

    if (page == null || page.submissions.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadSubmissions,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          children: const [
            SizedBox(height: 80),
            MessageWidget(
              title: 'No submissions yet',
              message: 'No students have submitted this assignment yet.',
              type: MessageType.info,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadSubmissions,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          16,
          16,
          16,
          24,
        ),
        itemCount: page.submissions.length,
        separatorBuilder: (context, index) {
          return const SizedBox(height: 12);
        },
        itemBuilder: (context, index) {
          return _buildSubmissionCard(
            page.submissions[index],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assignment Submissions'),
      ),
      body: SafeArea(
        child: _buildContent(),
      ),
    );
  }
}
