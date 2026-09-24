import 'package:flutter/material.dart';

import '../core/course/course_service.dart';
import '../core/errors/api_exception.dart';
import '../core/models/course/course_section.dart';

class InstructorCreateQuizScreen extends StatefulWidget {
  const InstructorCreateQuizScreen({
    super.key,
    required this.courseId,
  });

  final String courseId;

  @override
  State<InstructorCreateQuizScreen> createState() =>
      _InstructorCreateQuizScreenState();
}

class _InstructorCreateQuizScreenState
    extends State<InstructorCreateQuizScreen> {
  final CourseService _courseService = CourseService();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _passingScoreController =
      TextEditingController(text: '60');
  final TextEditingController _timeLimitController =
      TextEditingController(text: '10');
  final TextEditingController _maxAttemptsController =
      TextEditingController(text: '3');

  List<CourseSection> _sections = const [];
  String? _selectedSectionId;

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
    _passingScoreController.dispose();
    _timeLimitController.dispose();
    _maxAttemptsController.dispose();
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

  Future<void> _createQuiz() async {
    FocusScope.of(context).unfocus();

    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();

    final passingScore = double.tryParse(_passingScoreController.text.trim());

    final timeLimit = int.tryParse(_timeLimitController.text.trim());

    final maxAttempts = int.tryParse(_maxAttemptsController.text.trim());

    if (_selectedSectionId == null || _selectedSectionId!.isEmpty) {
      _showMessage(
        'Please select a section.',
      );
      return;
    }

    if (title.isEmpty) {
      _showMessage(
        'Please enter a quiz title.',
      );
      return;
    }

    if (passingScore == null || passingScore < 0 || passingScore > 100) {
      _showMessage(
        'Passing score must be between 0 and 100.',
      );
      return;
    }

    if (timeLimit == null || timeLimit <= 0) {
      _showMessage(
        'Time limit must be greater than 0.',
      );
      return;
    }

    if (maxAttempts == null || maxAttempts <= 0) {
      _showMessage(
        'Maximum attempts must be greater than 0.',
      );
      return;
    }

    setState(() {
      _isCreating = true;
    });

    try {
      await _courseService.createInstructorQuiz(
        courseId: widget.courseId,
        sectionId: _selectedSectionId!,
        title: title,
        description: description,
        passingScore: passingScore,
        timeLimitMinutes: timeLimit,
        maxAttempts: maxAttempts,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Quiz created successfully.'),
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
        'Unable to create quiz. Please try again.',
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

  Widget _buildSectionField() {
    if (_isLoadingSections) {
      return const InputDecorator(
        decoration: InputDecoration(
          labelText: 'Section',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.folder_outlined),
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
              prefixIcon: Icon(Icons.folder_outlined),
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
              icon: const Icon(Icons.refresh),
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
          prefixIcon: Icon(Icons.folder_outlined),
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
        prefixIcon: Icon(Icons.folder_outlined),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Quiz'),
      ),
      body: SafeArea(
        child: Form(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              16,
              16,
              16,
              24,
            ),
            children: [
              Text(
                'Quiz Details',
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
                  labelText: 'Quiz Title',
                  hintText: 'Enter quiz title',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.quiz_outlined),
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
                  hintText: 'Enter quiz description',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description_outlined),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passingScoreController,
                enabled: !_isCreating,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Passing Score',
                  hintText: '0 - 100',
                  suffixText: '%',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.percent),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _timeLimitController,
                enabled: !_isCreating,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Time Limit',
                  hintText: 'Example: 10',
                  suffixText: 'minutes',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.timer_outlined),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _maxAttemptsController,
                enabled: !_isCreating,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Maximum Attempts',
                  hintText: 'Example: 3',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.repeat),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 50,
                child: FilledButton.icon(
                  onPressed: _isCreating ? null : _createQuiz,
                  icon: _isCreating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.add_circle_outline),
                  label: Text(
                    _isCreating ? 'Creating...' : 'Create Quiz',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
