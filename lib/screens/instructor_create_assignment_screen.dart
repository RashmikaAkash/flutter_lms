import 'package:flutter/material.dart';

import '../core/course/course_service.dart';
import '../core/errors/api_exception.dart';
import '../core/models/course/course_section.dart';

class InstructorCreateAssignmentScreen extends StatefulWidget {
  const InstructorCreateAssignmentScreen({
    super.key,
    required this.courseId,
  });

  final String courseId;

  @override
  State<InstructorCreateAssignmentScreen> createState() =>
      _InstructorCreateAssignmentScreenState();
}

class _InstructorCreateAssignmentScreenState
    extends State<InstructorCreateAssignmentScreen> {
  final CourseService _courseService = CourseService();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _instructionsController = TextEditingController();
  final TextEditingController _maximumMarksController =
      TextEditingController(text: '100');

  List<CourseSection> _sections = const [];

  String? _selectedSectionId;
  DateTime? _selectedDueDate;

  bool _isLoadingSections = true;
  bool _isCreating = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSections();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _instructionsController.dispose();
    _maximumMarksController.dispose();
    super.dispose();
  }

  Future<void> _loadSections() async {
    setState(() {
      _isLoadingSections = true;
      _errorMessage = null;
    });

    try {
      final sections = await _courseService.getCourseSections(
        widget.courseId,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _sections = sections;
        _selectedSectionId = sections.isNotEmpty ? sections.first.id : null;
        _isLoadingSections = false;
      });
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoadingSections = false;
        _errorMessage = error.message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoadingSections = false;
        _errorMessage = 'Unable to load course sections. Please try again.';
      });
    }
  }

  Future<void> _selectDueDate() async {
    final now = DateTime.now();

    final initialDate =
        _selectedDueDate != null && !_selectedDueDate!.isBefore(now)
            ? _selectedDueDate!
            : now;

    final date = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: DateTime(now.year + 5),
      initialDate: initialDate,
    );

    if (date == null || !mounted) {
      return;
    }

    final initialTime = _selectedDueDate != null &&
            _selectedDueDate!.year == date.year &&
            _selectedDueDate!.month == date.month &&
            _selectedDueDate!.day == date.day
        ? TimeOfDay.fromDateTime(_selectedDueDate!)
        : TimeOfDay.fromDateTime(
            now.add(
              const Duration(hours: 1),
            ),
          );

    final time = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (time == null || !mounted) {
      return;
    }

    final selectedDateTime = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    if (!selectedDateTime.isAfter(now)) {
      _showMessage(
        'Due date and time must be in the future.',
      );
      return;
    }

    setState(() {
      _selectedDueDate = selectedDateTime;
    });
  }

  Future<void> _createAssignment() async {
    FocusScope.of(context).unfocus();

    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    final instructions = _instructionsController.text.trim();

    final maximumMarks = int.tryParse(
      _maximumMarksController.text.trim(),
    );

    if (_selectedSectionId == null || _selectedSectionId!.isEmpty) {
      _showMessage('Please select a section.');
      return;
    }

    if (title.isEmpty) {
      _showMessage('Please enter an assignment title.');
      return;
    }

    if (description.isEmpty) {
      _showMessage('Please enter a description.');
      return;
    }

    if (instructions.isEmpty) {
      _showMessage('Please enter assignment instructions.');
      return;
    }

    if (_selectedDueDate == null) {
      _showMessage('Please select a due date and time.');
      return;
    }

    if (!_selectedDueDate!.isAfter(DateTime.now())) {
      _showMessage(
        'Due date and time must be in the future.',
      );
      return;
    }

    if (maximumMarks == null || maximumMarks <= 0) {
      _showMessage(
        'Maximum marks must be greater than 0.',
      );
      return;
    }

    setState(() {
      _isCreating = true;
    });

    try {
      await _courseService.createInstructorAssignment(
        courseId: widget.courseId,
        sectionId: _selectedSectionId!,
        title: title,
        description: description,
        instructions: instructions,
        dueDate: _selectedDueDate!,
        maximumMarks: maximumMarks,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Assignment created successfully.',
          ),
        ),
      );

      Navigator.pop(context, true);
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isCreating = false;
      });

      _showMessage(error.message);
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isCreating = false;
      });

      _showMessage(
        'Unable to create assignment. Please try again.',
      );
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  String _formatDueDate(DateTime dateTime) {
    final local = dateTime.toLocal();

    final date = '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/'
        '${local.year}';

    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;

    final minute = local.minute.toString().padLeft(2, '0');

    final period = local.hour >= 12 ? 'PM' : 'AM';

    return '$date $hour:$minute $period';
  }

  Widget _buildSectionField() {
    if (_isLoadingSections) {
      return const InputDecorator(
        decoration: InputDecoration(
          labelText: 'Section',
          border: OutlineInputBorder(),
          prefixIcon: Icon(
            Icons.folder_outlined,
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
              ),
            ),
            SizedBox(width: 12),
            Text('Loading sections...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Section',
              border: OutlineInputBorder(),
              prefixIcon: Icon(
                Icons.folder_outlined,
              ),
            ),
            child: Text(
              _errorMessage!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _loadSections,
              icon: const Icon(
                Icons.refresh,
              ),
              label: const Text('Retry'),
            ),
          ),
        ],
      );
    }

    if (_sections.isEmpty) {
      return const InputDecorator(
        decoration: InputDecoration(
          labelText: 'Section',
          border: OutlineInputBorder(),
          prefixIcon: Icon(
            Icons.folder_outlined,
          ),
        ),
        child: Text(
          'No sections available for this course.',
        ),
      );
    }

    return DropdownButtonFormField<String>(
      value: _selectedSectionId,
      decoration: const InputDecoration(
        labelText: 'Section',
        border: OutlineInputBorder(),
        prefixIcon: Icon(
          Icons.folder_outlined,
        ),
      ),
      items: _sections.map((section) {
        return DropdownMenuItem<String>(
          value: section.id,
          child: Text(
            section.title.isEmpty ? 'Section ${section.order}' : section.title,
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: _isCreating
          ? null
          : (value) {
              setState(() {
                _selectedSectionId = value;
              });
            },
    );
  }

  Widget _buildDueDateField() {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: _isCreating ? null : _selectDueDate,
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Due Date & Time',
          border: OutlineInputBorder(),
          prefixIcon: Icon(
            Icons.event_outlined,
          ),
          suffixIcon: Icon(
            Icons.calendar_month_outlined,
          ),
        ),
        child: Text(
          _selectedDueDate == null
              ? 'Select due date and time'
              : _formatDueDate(_selectedDueDate!),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Create Assignment',
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            16,
            16,
            16,
            24,
          ),
          children: [
            Text(
              'Assignment Details',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 16),
            _buildSectionField(),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              enabled: !_isCreating,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Assignment Title',
                hintText: 'Enter assignment title',
                border: OutlineInputBorder(),
                prefixIcon: Icon(
                  Icons.assignment_outlined,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              enabled: !_isCreating,
              minLines: 3,
              maxLines: 5,
              textInputAction: TextInputAction.newline,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Enter assignment description',
                border: OutlineInputBorder(),
                prefixIcon: Icon(
                  Icons.description_outlined,
                ),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _instructionsController,
              enabled: !_isCreating,
              minLines: 4,
              maxLines: 7,
              textInputAction: TextInputAction.newline,
              decoration: const InputDecoration(
                labelText: 'Instructions',
                hintText: 'Enter assignment instructions',
                border: OutlineInputBorder(),
                prefixIcon: Icon(
                  Icons.list_alt_outlined,
                ),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 16),
            _buildDueDateField(),
            const SizedBox(height: 16),
            TextField(
              controller: _maximumMarksController,
              enabled: !_isCreating,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Maximum Marks',
                hintText: 'Example: 100',
                border: OutlineInputBorder(),
                prefixIcon: Icon(
                  Icons.star_outline,
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 50,
              child: FilledButton.icon(
                onPressed: _isCreating ? null : _createAssignment,
                icon: _isCreating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(
                        Icons.add_circle_outline,
                      ),
                label: Text(
                  _isCreating ? 'Creating...' : 'Create Assignment',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
