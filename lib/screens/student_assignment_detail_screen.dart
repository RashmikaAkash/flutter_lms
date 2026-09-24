import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../core/course/course_service.dart';
import '../core/errors/api_exception.dart';
import '../core/models/assignment/assignment.dart';
import '../core/models/assignment/assignment_submission.dart';
import '../widgets/message_widget.dart';

class StudentAssignmentDetailScreen extends StatefulWidget {
  const StudentAssignmentDetailScreen({
    super.key,
    required this.assignmentId,
  });

  final String assignmentId;

  @override
  State<StudentAssignmentDetailScreen> createState() =>
      _StudentAssignmentDetailScreenState();
}

class _StudentAssignmentDetailScreenState
    extends State<StudentAssignmentDetailScreen> {
  final CourseService _courseService = CourseService();
  final TextEditingController _textAnswerController = TextEditingController();

  Assignment? _assignment;
  AssignmentSubmission? _submission;

  String? _selectedFilePath;
  String? _selectedFileName;

  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _isReplacingFile = false;
  String? _errorMessage;
  String? _submissionError;
  String? _replacementError;

  @override
  void initState() {
    super.initState();
    _loadAssignment();
  }

  Future<void> _loadAssignment() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final assignment = await _courseService.getStudentAssignment(
        widget.assignmentId,
      );

      final submission = await _courseService.getMyAssignmentSubmission(
        widget.assignmentId,
      );

      if (!mounted) return;

      setState(() {
        _assignment = assignment;
        _submission = submission;
        _isLoading = false;
      });

      if (submission != null) {
        _textAnswerController.text = submission.textAnswer;
      }
    } on ApiException catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = error.message;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load assignment.';
      });
    }
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        return;
      }

      final file = result.files.single;
      final path = file.path;

      if (path == null || path.isEmpty) {
        if (!mounted) {
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'The selected file could not be accessed.',
            ),
          ),
        );

        return;
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _selectedFilePath = path;
        _selectedFileName = file.name;
        _submissionError = null;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to select the file. Please try again.',
          ),
        ),
      );
    }
  }

  Future<void> _submitAssignment() async {
    final filePath = _selectedFilePath;

    if (_isSubmitting) {
      return;
    }

    if (filePath == null || filePath.isEmpty) {
      setState(() {
        _submissionError = 'Please select a file before submitting.';
      });

      return;
    }

    setState(() {
      _isSubmitting = true;
      _submissionError = null;
    });

    try {
      final submission = await _courseService.submitAssignment(
        assignmentId: widget.assignmentId,
        textAnswer: _textAnswerController.text.trim(),
        filePath: filePath,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _submission = submission;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Assignment submitted successfully.',
          ),
        ),
      );
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _submissionError = error.message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _submissionError = 'Unable to submit assignment. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _replaceSubmissionFile() async {
    final submission = _submission;

    if (submission == null || _isReplacingFile) {
      return;
    }

    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        return;
      }

      final file = result.files.single;
      final filePath = file.path;

      if (filePath == null || filePath.isEmpty) {
        if (!mounted) {
          return;
        }

        setState(() {
          _replacementError = 'The selected file could not be accessed.';
        });

        return;
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _isReplacingFile = true;
        _replacementError = null;
      });

      final updatedSubmission =
          await _courseService.replaceAssignmentSubmissionFile(
        submissionId: submission.id,
        filePath: filePath,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _submission = updatedSubmission;
        _isReplacingFile = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Submission file replaced successfully.',
          ),
        ),
      );
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isReplacingFile = false;
        _replacementError = error.message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isReplacingFile = false;
        _replacementError =
            'Unable to replace the submission file. Please try again.';
      });
    }
  }

  Widget _buildAssignmentHeader(Assignment assignment) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              assignment.title.isEmpty ? 'Assignment' : assignment.title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
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
                    'Maximum marks: '
                    '${assignment.maximumMarks.toStringAsFixed(0)}',
                  ),
                ),
                if (assignment.section.title.isNotEmpty)
                  Chip(
                    avatar: const Icon(
                      Icons.menu_book_outlined,
                      size: 18,
                    ),
                    label: Text(
                      assignment.section.title,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatSubmittedAt(DateTime? date) {
    if (date == null) return 'Not available';
    final localDate = date.toLocal();
    return '${localDate.day.toString().padLeft(2, '0')}/'
        '${localDate.month.toString().padLeft(2, '0')}/'
        '${localDate.year}  '
        '${localDate.hour.toString().padLeft(2, '0')}:'
        '${localDate.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildTextSection({
    required String title,
    required String content,
  }) {
    if (content.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              content,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmissionSection() {
    final submission = _submission;

    if (submission != null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 24,
                    child: Icon(
                      Icons.check_circle_outline,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Assignment Submitted',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        const SizedBox(height: 8),
                        Chip(
                          visualDensity: VisualDensity.compact,
                          avatar: Icon(
                            submission.status == 'GRADED'
                                ? Icons.verified_outlined
                                : submission.status == 'RESUBMISSION_REQUIRED'
                                    ? Icons.replay_outlined
                                    : Icons.schedule_outlined,
                            size: 18,
                          ),
                          label: Text(
                            submission.status.isEmpty
                                ? 'SUBMITTED'
                                : submission.status.replaceAll('_', ' '),
                          ),
                          backgroundColor: submission.status == 'GRADED'
                              ? Theme.of(context).colorScheme.secondaryContainer
                              : submission.status == 'RESUBMISSION_REQUIRED'
                                  ? Theme.of(context)
                                      .colorScheme
                                      .tertiaryContainer
                                  : Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerHighest,
                        ),
                        Text(
                          'Submitted: ${_formatSubmittedAt(submission.submittedAt)}',
                        ),
                      ],
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
                Text(
                  submission.textAnswer,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
              if (submission.fileName != null &&
                  submission.fileName!.trim().isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Current File',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                Container(
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
                        Icons.description_outlined,
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
              if (_replacementError != null) ...[
                const SizedBox(height: 12),
                MessageWidget(
                  title: 'Unable to replace file',
                  message: _replacementError!,
                  type: MessageType.error,
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isReplacingFile || submission.status == 'GRADED'
                      ? null
                      : _replaceSubmissionFile,
                  icon: _isReplacingFile
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(
                          Icons.sync_outlined,
                        ),
                  label: Text(
                    _isReplacingFile
                        ? 'Replacing...'
                        : submission.status == 'GRADED'
                            ? 'Submission Graded'
                            : 'Replace File',
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Your Submission',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _textAnswerController,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Text Answer',
                hintText: 'Enter your answer or submission note',
              ),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: _isSubmitting ? null : _pickFile,
              icon: const Icon(
                Icons.attach_file,
              ),
              label: Text(
                _selectedFileName == null ? 'Choose File' : 'Change File',
              ),
            ),
            if (_selectedFileName != null) ...[
              const SizedBox(height: 10),
              Container(
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
                      Icons.description_outlined,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _selectedFileName!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (_submissionError != null) ...[
              const SizedBox(height: 12),
              MessageWidget(
                title: 'Unable to submit assignment',
                message: _submissionError!,
                type: MessageType.error,
              ),
            ],
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _isSubmitting ? null : _submitAssignment,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(
                      Icons.upload_file_outlined,
                    ),
              label: Text(
                _isSubmitting ? 'Submitting...' : 'Submit Assignment',
              ),
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
            title: 'Unable to load assignment',
            message: _errorMessage!,
            type: MessageType.error,
            actionLabel: 'Retry',
            onActionPressed: _loadAssignment,
          ),
        ),
      );
    }

    final assignment = _assignment;

    if (assignment == null) {
      return const Center(
        child: MessageWidget(
          title: 'Assignment unavailable',
          message: 'Assignment details are not available.',
          type: MessageType.info,
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAssignment,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          16,
          16,
          16,
          24,
        ),
        children: [
          _buildAssignmentHeader(assignment),
          if (assignment.description.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildTextSection(
              title: 'Description',
              content: assignment.description,
            ),
          ],
          if (assignment.instructions.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildTextSection(
              title: 'Instructions',
              content: assignment.instructions,
            ),
          ],
          const SizedBox(height: 16),
          _buildSubmissionSection(),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _textAnswerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assignment Details'),
      ),
      body: SafeArea(
        child: _buildContent(),
      ),
    );
  }
}
