import 'package:flutter/material.dart';

import '../core/course/course_page.dart';
import '../core/course/course_service.dart';
import '../core/errors/api_exception.dart';
import '../core/models/course/course.dart';
import '../widgets/message_widget.dart';

class CourseBrowseScreen extends StatefulWidget {
  const CourseBrowseScreen({super.key});

  @override
  State<CourseBrowseScreen> createState() => _CourseBrowseScreenState();
}

class _CourseBrowseScreenState extends State<CourseBrowseScreen> {
  final CourseService _courseService = CourseService();
  final TextEditingController _searchController = TextEditingController();

  CoursePage? _coursePage;

  bool _isLoading = false;
  String? _errorMessage;

  int _currentPage = 1;
  String? _selectedLevel;

  static const int _pageLimit = 10;

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCourses({
    int page = 1,
  }) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _courseService.getPublishedCourses(
        page: page,
        limit: _pageLimit,
        search: _searchController.text,
        level: _selectedLevel,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _coursePage = result;
        _currentPage = result.pagination.page;
      });
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = error.message;
        _coursePage = null;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = 'Unable to load courses. Please try again.';
        _coursePage = null;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _applyFilters() {
    _loadCourses(page: 1);
  }

  void _clearFilters() {
    _searchController.clear();

    setState(() {
      _selectedLevel = null;
    });

    _loadCourses(page: 1);
  }

  void _openCourse(Course course) {
    Navigator.pushNamed(
      context,
      '/course-details',
      arguments: {
        'courseId': course.id,
        'showEnrollButton': true,
      },
    );
  }

  Widget _buildSearchAndFilters() {
    final colorScheme = Theme.of(context).colorScheme;
    final page = _coursePage;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _searchController,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => _applyFilters(),
          decoration: InputDecoration(
            hintText: 'Search courses',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: IconButton(
              onPressed: _applyFilters,
              icon: const Icon(Icons.arrow_forward_rounded),
              tooltip: 'Search',
            ),
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _selectedLevel,
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
          onChanged: (value) {
            setState(() {
              _selectedLevel = value;
            });

            _loadCourses(page: 1);
          },
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _searchController.text.isEmpty && _selectedLevel == null
                ? null
                : _clearFilters,
            icon: const Icon(Icons.clear),
            label: const Text('Clear Filters'),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          page == null
              ? 'Published Courses'
              : '${page.pagination.totalItems} published course(s)',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }

  Widget _buildCourseCard(Course course) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openCourse(course),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (course.thumbnailUrl != null)
              SizedBox(
                height: 170,
                width: double.infinity,
                child: Image.network(
                  course.thumbnailUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) {
                    return Container(
                      color: colorScheme.surfaceContainerHighest,
                      child: const Center(
                        child: Icon(
                          Icons.image_not_supported_outlined,
                          size: 42,
                        ),
                      ),
                    );
                  },
                ),
              )
            else
              Container(
                height: 170,
                width: double.infinity,
                color: colorScheme.primaryContainer,
                child: Icon(
                  Icons.menu_book_outlined,
                  size: 52,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
              child: Text(
                course.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                course.shortDescription,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Row(
                children: [
                  Icon(
                    Icons.person_outline,
                    size: 18,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      course.instructor.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      course.level,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPagination() {
    final pagination = _coursePage?.pagination;

    if (pagination == null || pagination.totalPages <= 1) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          OutlinedButton.icon(
            onPressed: pagination.hasPreviousPage && !_isLoading
                ? () => _loadCourses(
                      page: _currentPage - 1,
                    )
                : null,
            icon: const Icon(Icons.chevron_left),
            label: const Text('Previous'),
          ),
          const SizedBox(width: 12),
          Text(
            'Page $_currentPage of ${pagination.totalPages}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: pagination.hasNextPage && !_isLoading
                ? () => _loadCourses(
                      page: _currentPage + 1,
                    )
                : null,
            icon: const Icon(Icons.chevron_right),
            label: const Text('Next'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading && _coursePage == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null && _coursePage == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: MessageWidget(
            title: 'Unable to load courses',
            message: _errorMessage!,
            type: MessageType.error,
            actionLabel: 'Retry',
            onActionPressed: () => _loadCourses(
              page: _currentPage,
            ),
          ),
        ),
      );
    }

    final courses = _coursePage?.courses ?? [];

    if (courses.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: MessageWidget(
            title: 'No courses found',
            message: 'Try another search term or level.',
            type: MessageType.info,
            actionLabel: 'Clear Filters',
            onActionPressed: _clearFilters,
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadCourses(
        page: _currentPage,
      ),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSearchAndFilters(),
          const SizedBox(height: 16),
          ...courses.map(_buildCourseCard),
          _buildPagination(),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Browse Courses'),
      ),
      body: SafeArea(
        child: _buildContent(),
      ),
    );
  }
}
