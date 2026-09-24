import 'package:flutter/material.dart';

import '../core/course/course_service.dart';
import '../core/errors/api_exception.dart';
import '../core/models/assignment/assignment.dart';
import '../widgets/message_widget.dart';

class InstructorAssignmentListScreen extends StatefulWidget {
  const InstructorAssignmentListScreen({
    super.key,
    required this.courseId,
  });

  final String courseId;

  @override
  State<InstructorAssignmentListScreen> createState() =>
      _InstructorAssignmentListScreenState();
}

class _InstructorAssignmentListScreenState
    extends State<InstructorAssignmentListScreen> {
  final CourseService _courseService = CourseService();

  List<Assignment> _assignments = [];

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAssignments();
  }

  Future<void> _loadAssignments() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final assignments = await _courseService.getInstructorAssignments(
        widget.courseId,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _assignments = assignments;
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
            'Unable to load instructor assignments. Please try again.';
      });
    }
  }

  Widget _buildAssignmentCard(Assignment assignment) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.pushNamed(
            context,
            '/instructor-assignment-submissions',
            arguments: assignment.id,
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      assignment.title.isEmpty
                          ? 'Assignment'
                          : assignment.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Chip(
                    avatar: Icon(
                      assignment.isPublished
                          ? Icons.public_outlined
                          : Icons.lock_outline,
                      size: 18,
                    ),
                    label: Text(
                      assignment.isPublished ? 'Published' : 'Draft',
                    ),
                  ),
                ],
              ),
              if (assignment.description.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  assignment.description,
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
              if (!assignment.isPublished) ...[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _publishAssignment(assignment);
                    },
                    icon: const Icon(
                      Icons.publish_outlined,
                    ),
                    label: const Text('Publish Assignment'),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      '/instructor-assignment-submissions',
                      arguments: assignment.id,
                    );
                  },
                  icon: const Icon(
                    Icons.fact_check_outlined,
                  ),
                  label: const Text('View Submissions'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _publishAssignment(
    Assignment assignment,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Publish Assignment'),
          content: Text(
            'Are you sure you want to publish "${assignment.title}"?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Publish'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    try {
      await _courseService.publishInstructorAssignment(
        assignment.id,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Assignment published successfully.',
          ),
        ),
      );

      await _loadAssignments();
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
            'Unable to publish assignment. Please try again.',
          ),
        ),
      );
    }
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
            title: 'Unable to load assignments',
            message: _errorMessage!,
            type: MessageType.error,
            actionLabel: 'Retry',
            onActionPressed: _loadAssignments,
          ),
        ),
      );
    }

    if (_assignments.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadAssignments,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          children: const [
            SizedBox(height: 80),
            MessageWidget(
              title: 'No assignments',
              message: 'This course does not have any assignments yet.',
              type: MessageType.info,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAssignments,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          16,
          16,
          16,
          24,
        ),
        itemCount: _assignments.length,
        separatorBuilder: (context, index) {
          return const SizedBox(height: 12);
        },
        itemBuilder: (context, index) {
          return _buildAssignmentCard(
            _assignments[index],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Course Assignments'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await Navigator.pushNamed(
            context,
            '/instructor-create-assignment',
            arguments: widget.courseId,
          );

          if (created == true && mounted) {
            _loadAssignments();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Create Assignment'),
      ),
      body: SafeArea(
        child: _buildContent(),
      ),
    );
  }
}
