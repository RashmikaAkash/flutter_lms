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
    final textTheme = Theme.of(context).textTheme;
    final page = _coursePage;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Find your next course',
          style: textTheme.headlineSmall,
        ),
        const SizedBox(height: 4),
        Text(
          'Explore courses and keep building your skills.',
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 18),
        TextField(
          controller: _searchController,
          textInputAction: TextInputAction.search,
          onChanged: (_) => setState(() {}),
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
        LayoutBuilder(
          builder: (context, constraints) {
            final clearButton = OutlinedButton.icon(
              onPressed:
                  _searchController.text.isEmpty && _selectedLevel == null
                      ? null
                      : _clearFilters,
              icon: const Icon(Icons.clear),
              label: const Text('Clear filters'),
            );
            final levelFilter = DropdownButtonFormField<String>(
              value: _selectedLevel,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Level',
                prefixIcon: Icon(Icons.signal_cellular_alt),
              ),
              items: const [
                DropdownMenuItem(value: 'BEGINNER', child: Text('Beginner')),
                DropdownMenuItem(
                  value: 'INTERMEDIATE',
                  child: Text('Intermediate'),
                ),
                DropdownMenuItem(value: 'ADVANCED', child: Text('Advanced')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedLevel = value;
                });
                _loadCourses(page: 1);
              },
            );

            if (constraints.maxWidth >= 500) {
              return Row(
                children: [
                  Expanded(child: levelFilter),
                  const SizedBox(width: 12),
                  clearButton,
                ],
              );
            }

            return Column(
              children: [
                levelFilter,
                const SizedBox(height: 10),
                SizedBox(width: double.infinity, child: clearButton),
              ],
            );
          },
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Icon(Icons.menu_book_outlined,
                  size: 19, color: colorScheme.primary),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  page == null
                      ? 'Published courses'
                      : '${page.pagination.totalItems} published course(s)',
                  style: textTheme.titleSmall?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ],
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
            AspectRatio(
              aspectRatio: 16 / 9,
              child: course.thumbnailUrl != null
                  ? Image.network(
                      course.thumbnailUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildCoursePlaceholder(
                        unavailable: true,
                      ),
                    )
                  : _buildCoursePlaceholder(),
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
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
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
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (course.category.name.isNotEmpty)
                    _buildCourseTag(
                      Icons.category_outlined,
                      course.category.name,
                    ),
                  _buildCourseTag(
                    Icons.signal_cellular_alt_outlined,
                    course.level,
                  ),
                  _buildCourseTag(
                    Icons.star_rounded,
                    course.averageRating.toStringAsFixed(1),
                  ),
                  _buildCourseTag(
                    Icons.payments_outlined,
                    course.isFree ? 'Free' : 'Price: ${course.price}',
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 8, 8),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => _openCourse(course),
                  icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                  label: const Text('View course'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoursePlaceholder({bool unavailable = false}) {
    final colors = Theme.of(context).colorScheme;
    return ColoredBox(
      color: unavailable
          ? colors.surfaceContainerHighest
          : colors.primaryContainer,
      child: Center(
        child: Icon(
          unavailable
              ? Icons.image_not_supported_outlined
              : Icons.menu_book_outlined,
          size: 44,
          color: unavailable
              ? colors.onSurfaceVariant
              : colors.onPrimaryContainer,
        ),
      ),
    );
  }

  Widget _buildCourseTag(IconData icon, String label) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      constraints: const BoxConstraints(maxWidth: 210),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: colors.primary),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ),
        ],
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
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        runSpacing: 8,
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
          Text(
            'Page $_currentPage of ${pagination.totalPages}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
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
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 14),
            Text(
              'Loading courses',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      );
    }

    final courses = _coursePage?.courses ?? [];

    return RefreshIndicator(
      onRefresh: () => _loadCourses(
        page: _currentPage,
      ),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSearchAndFilters(),
          const SizedBox(height: 16),
          if (_errorMessage != null)
            MessageWidget(
              title: 'Unable to load courses',
              message: _errorMessage!,
              type: MessageType.error,
              actionLabel: 'Retry',
              onActionPressed: () => _loadCourses(page: _currentPage),
            )
          else if (courses.isEmpty)
            MessageWidget(
              title: 'No courses found',
              message: 'Try another search term or level.',
              type: MessageType.info,
              actionLabel: 'Clear Filters',
              onActionPressed: _clearFilters,
            )
          else ...[
            if (courses.isNotEmpty)
              LayoutBuilder(
                builder: (context, constraints) {
                  final twoColumns = constraints.maxWidth >= 700;
                  final cardWidth = twoColumns
                      ? ((constraints.maxWidth - 16) / 2).clamp(0, 520).toDouble()
                      : constraints.maxWidth;
                  return Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 16,
                    runSpacing: 16,
                    children: courses
                        .map(
                          (course) => SizedBox(
                            width: cardWidth,
                            child: _buildCourseCard(course),
                          ),
                        )
                        .toList(),
                  );
                },
              ),
            _buildPagination(),
          ],
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
