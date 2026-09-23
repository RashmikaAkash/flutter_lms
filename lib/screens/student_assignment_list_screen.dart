import 'package:flutter/material.dart';

import '../core/course/course_service.dart';
import '../core/errors/api_exception.dart';
import '../core/models/assignment/assignment.dart';
import '../widgets/message_widget.dart';

class StudentAssignmentListScreen extends StatefulWidget {
  const StudentAssignmentListScreen({
    super.key,
    required this.courseId,
  });

  final String courseId;

  @override
  State<StudentAssignmentListScreen> createState() =>
      _StudentAssignmentListScreenState();
}

class _StudentAssignmentListScreenState
    extends State<StudentAssignmentListScreen> {
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
      final assignments = await _courseService.getStudentAssignments(
        widget.courseId,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _assignments = assignments;
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
        _errorMessage = 'Unable to load assignments. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildAssignmentCard(Assignment assignment) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: const CircleAvatar(
          child: Icon(
            Icons.assignment_outlined,
          ),
        ),
        title: Text(
          assignment.title.isEmpty ? 'Assignment' : assignment.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (assignment.description.isNotEmpty)
                Text(
                  assignment.description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              if (assignment.instructions.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Instructions: ${assignment.instructions}',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 8),
              Text(
                'Maximum marks: '
                '${assignment.maximumMarks.toStringAsFixed(0)}',
              ),
              if (assignment.section.title.isNotEmpty)
                Text(
                  'Section: ${assignment.section.title}',
                ),
            ],
          ),
        ),
        onTap: () {
          Navigator.pushNamed(
            context,
            '/student-assignment-detail',
            arguments: assignment.id,
          );
        },
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
            MessageWidget(
              title: 'No assignments available',
              message:
                  'This course does not have any published assignments yet.',
              type: MessageType.info,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAssignments,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            '${_assignments.length} assignment(s)',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 14),
          ..._assignments.map(_buildAssignmentCard),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assignments'),
      ),
      body: SafeArea(
        child: _buildContent(),
      ),
    );
  }
}
