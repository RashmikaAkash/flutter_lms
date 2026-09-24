import 'package:flutter/material.dart';

import '../core/course/course_service.dart';
import '../core/errors/api_exception.dart';
import '../core/models/course/course_category.dart';
import '../widgets/message_widget.dart';
import '../widgets/primary_button.dart';

class InstructorCreateCourseScreen extends StatefulWidget {
  const InstructorCreateCourseScreen({super.key});

  @override
  State<InstructorCreateCourseScreen> createState() =>
      _InstructorCreateCourseScreenState();
}

class _InstructorCreateCourseScreenState
    extends State<InstructorCreateCourseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _courseService = CourseService();
  final _titleController = TextEditingController();
  final _shortDescriptionController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _languageController = TextEditingController();
  final _requirementController = TextEditingController();
  final _outcomeController = TextEditingController();
  final _audienceController = TextEditingController();

  final List<CourseCategory> _categories = [];
  final List<String> _requirements = [];
  final List<String> _learningOutcomes = [];
  final List<String> _targetAudience = [];

  String? _categoryId;
  String? _categoryError;
  String? _level;
  bool _isLoadingCategories = true;
  bool _isSubmitting = false;
  final Map<String, String> _serverFieldErrors = {};

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _shortDescriptionController.dispose();
    _descriptionController.dispose();
    _languageController.dispose();
    _requirementController.dispose();
    _outcomeController.dispose();
    _audienceController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoadingCategories = true;
      _categoryError = null;
    });

    try {
      var page = 1;
      var hasNextPage = true;
      final categories = <CourseCategory>[];

      while (hasNextPage) {
        final result = await _courseService.getActiveCategories(page: page);
        categories.addAll(result.categories);
        hasNextPage = result.pagination.hasNextPage;
        page++;
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _categories
          ..clear()
          ..addAll(categories);
        _isLoadingCategories = false;
      });
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _categoryError = error.message;
        _isLoadingCategories = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _categoryError = 'Unable to load course categories. Please try again.';
        _isLoadingCategories = false;
      });
    }
  }

  void _addListItem(TextEditingController controller, List<String> items) {
    final value = controller.text.trim();
    if (value.isEmpty) {
      return;
    }

    setState(() {
      items.add(value);
      controller.clear();
    });
  }

  Future<void> _createCourse() async {
    FocusScope.of(context).unfocus();
    _serverFieldErrors.clear();
    if (_isSubmitting || !(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final categoryId = _categoryId;
    final level = _level;
    if (categoryId == null || level == null) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await _courseService.createInstructorCourse(
        categoryId: categoryId,
        title: _titleController.text,
        shortDescription: _shortDescriptionController.text,
        description: _descriptionController.text,
        level: level,
        language: _languageController.text,
        requirements: _requirements,
        learningOutcomes: _learningOutcomes,
        targetAudience: _targetAudience,
      );

      if (!mounted) {
        return;
      }

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          icon: const Icon(Icons.check_circle_outline),
          title: const Text('Course created'),
          content: const Text('Your course was created successfully.'),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Done'),
            ),
          ],
        ),
      );
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _serverFieldErrors
          ..clear()
          ..addAll(_extractFieldErrors(error.responseBody));
      });
      _formKey.currentState?.validate();
      if (_serverFieldErrors.isEmpty) {
        _showMessage(error.diagnosticDetails);
      }
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showMessage('Unable to create the course. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Map<String, String> _extractFieldErrors(dynamic responseBody) {
    final result = <String, String>{};
    if (responseBody is! Map) return result;
    final body = Map<String, dynamic>.from(responseBody);
    final rawErrors = body['errors'] ??
        body['validationErrors'] ??
        body['details'] ??
        body['error'];

    void add(String key, dynamic value) {
      final rawField = key.split('.').last.replaceAll(RegExp(r'\[\d+\]'), '');
      final field = switch (rawField.toLowerCase().replaceAll('_', '')) {
        'categoryid' => 'categoryId',
        'shortdescription' => 'shortDescription',
        'learningoutcomes' => 'learningOutcomes',
        'targetaudience' => 'targetAudience',
        _ => rawField,
      };
      final message = value is List
          ? value.map((item) => item.toString()).join('\n')
          : value is Map
              ? value.values.map((item) => item.toString()).join('\n')
              : value.toString();
      if (message.trim().isNotEmpty) result[field] = message;
    }

    if (rawErrors is Map) {
      rawErrors.forEach((key, value) => add(key.toString(), value));
    } else if (rawErrors is List) {
      for (final item in rawErrors) {
        if (item is Map) {
          final field = item['field'] ?? item['path'] ?? item['property'];
          final message = item['message'] ?? item['messages'] ?? item['error'];
          if (field != null && message != null) add(field.toString(), message);
        }
      }
    }

    return result;
  }

  String? _fieldError(String field, String? value, String label) {
    final serverError = _serverFieldErrors[field];
    if (serverError != null) return serverError;
    return _required(value, label);
  }

  String? _dropdownError(String field, String? value, String message) {
    return _serverFieldErrors[field] ?? (value == null ? message : null);
  }

  String? _required(String? value, String label) {
    if (value == null || value.trim().isEmpty) {
      return '$label is required';
    }
    return null;
  }

  Widget _sectionHeader(BuildContext context, String title, IconData icon) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Icon(icon, size: 20, color: colorScheme.primary),
        const SizedBox(width: 10),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryField() {
    if (_isLoadingCategories) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: LinearProgressIndicator(),
      );
    }

    if (_categoryError != null) {
      return MessageWidget(
        title: 'Categories unavailable',
        message: _categoryError!,
        type: MessageType.error,
        actionLabel: 'Retry',
        onActionPressed: _loadCategories,
      );
    }

    if (_categories.isEmpty) {
      return const MessageWidget(
        title: 'No active categories',
        message: 'A course category is needed before you can create a course.',
        type: MessageType.info,
      );
    }

    return DropdownButtonFormField<String>(
      value: _categoryId,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Category',
        prefixIcon: Icon(Icons.category_outlined),
      ),
      items: _categories
          .map(
            (category) => DropdownMenuItem<String>(
              value: category.id,
              child: Text(category.name, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged:
          _isSubmitting ? null : (value) => setState(() => _categoryId = value),
      validator: (value) => _dropdownError('categoryId', value, 'Select a category'),
    );
  }

  Widget _buildListEditor({
    required String title,
    required String field,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    required List<String> items,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                enabled: !_isSubmitting,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _addListItem(controller, items),
                decoration: InputDecoration(
                  hintText: hint,
                  prefixIcon: Icon(icon),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 56,
              child: IconButton.filledTonal(
                tooltip: 'Add $title',
                onPressed: _isSubmitting
                    ? null
                    : () => _addListItem(controller, items),
                icon: const Icon(Icons.add),
              ),
            ),
          ],
        ),
        if (items.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (var index = 0; index < items.length; index++)
                InputChip(
                  label: Text(items[index]),
                  deleteButtonTooltipMessage: 'Remove item',
                  onDeleted: _isSubmitting
                      ? null
                      : () => setState(() => items.removeAt(index)),
                  side: BorderSide(color: colorScheme.outlineVariant),
                ),
            ],
          ),
        ],
        if (_serverFieldErrors[field] != null) ...[
          const SizedBox(height: 6),
          Text(
            _serverFieldErrors[field]!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
      ],
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _sectionHeader(context, title, icon),
            const SizedBox(height: 18),
            ...children,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Create Course')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Build your course',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Add the details learners need to understand what they will learn.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 22),
                    _buildSectionCard(
                      title: 'Basic information',
                      icon: Icons.menu_book_outlined,
                      children: [
                        _buildCategoryField(),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _titleController,
                          enabled: !_isSubmitting,
                          textCapitalization: TextCapitalization.sentences,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Course title',
                            hintText: 'Give your course a clear title',
                            prefixIcon: Icon(Icons.title_outlined),
                          ),
                          validator: (value) => _fieldError('title', value, 'Title'),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _shortDescriptionController,
                          enabled: !_isSubmitting,
                          textCapitalization: TextCapitalization.sentences,
                          textInputAction: TextInputAction.next,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'Short description',
                            hintText: 'A concise introduction to the course',
                            alignLabelWithHint: true,
                          ),
                          validator: (value) => _fieldError(
                            'shortDescription', value, 'Short description',
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _descriptionController,
                          enabled: !_isSubmitting,
                          textCapitalization: TextCapitalization.sentences,
                          textInputAction: TextInputAction.newline,
                          minLines: 4,
                          maxLines: 8,
                          decoration: const InputDecoration(
                            labelText: 'Full description',
                            hintText: 'Describe the course in more detail',
                            alignLabelWithHint: true,
                          ),
                          validator: (value) => _fieldError('description', value, 'Description'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildSectionCard(
                      title: 'Course details',
                      icon: Icons.tune_outlined,
                      children: [
                        DropdownButtonFormField<String>(
                          value: _level,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Level',
                            prefixIcon: Icon(Icons.signal_cellular_alt),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'BEGINNER',
                              child: Text('Beginner'),
                            ),
                            DropdownMenuItem(
                              value: 'INTERMEDIATE',
                              child: Text('Intermediate'),
                            ),
                            DropdownMenuItem(
                              value: 'ADVANCED',
                              child: Text('Advanced'),
                            ),
                          ],
                          onChanged: _isSubmitting
                              ? null
                              : (value) => setState(() => _level = value),
                          validator: (value) => _dropdownError('level', value, 'Select a course level'),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _languageController,
                          enabled: !_isSubmitting,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.done,
                          decoration: const InputDecoration(
                            labelText: 'Language',
                            hintText: 'Enter the course language',
                            prefixIcon: Icon(Icons.language_outlined),
                          ),
                          validator: (value) => _fieldError('language', value, 'Language'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildSectionCard(
                      title: 'Requirements',
                      icon: Icons.checklist_outlined,
                      children: [
                        _buildListEditor(
                          title: 'Add requirements',
                          field: 'requirements',
                          hint: 'One requirement at a time',
                          icon: Icons.playlist_add_check_outlined,
                          controller: _requirementController,
                          items: _requirements,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildSectionCard(
                      title: 'Learning outcomes',
                      icon: Icons.flag_outlined,
                      children: [
                        _buildListEditor(
                          title: 'Add learning outcomes',
                          field: 'learningOutcomes',
                          hint: 'What will learners be able to do?',
                          icon: Icons.check_circle_outline,
                          controller: _outcomeController,
                          items: _learningOutcomes,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildSectionCard(
                      title: 'Target audience',
                      icon: Icons.groups_outlined,
                      children: [
                        _buildListEditor(
                          title: 'Add audience groups',
                          field: 'targetAudience',
                          hint: 'Who is this course for?',
                          icon: Icons.person_add_alt_outlined,
                          controller: _audienceController,
                          items: _targetAudience,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    PrimaryButton(
                      label: _isSubmitting
                          ? 'Creating course...'
                          : 'Create course',
                      icon: Icons.add_circle_outline,
                      isLoading: _isSubmitting,
                      onPressed: _isSubmitting ||
                              _isLoadingCategories ||
                              _categories.isEmpty
                          ? null
                          : _createCourse,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
