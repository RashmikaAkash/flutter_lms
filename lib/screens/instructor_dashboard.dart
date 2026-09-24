import 'package:flutter/material.dart';

import '../core/auth/auth_service.dart';
import '../core/course/course_service.dart';
import '../core/errors/api_exception.dart';
import '../core/models/course/course.dart';
import '../widgets/dashboard_nav_card.dart';
import '../widgets/message_widget.dart';
import '../widgets/section_header.dart';
import 'notifications_screen.dart';

class InstructorDashboard extends StatefulWidget {
  const InstructorDashboard({super.key});

  @override
  State<InstructorDashboard> createState() => _InstructorDashboardState();
}

class _InstructorDashboardState extends State<InstructorDashboard> {
  final AuthService _authService = AuthService();
  final CourseService _courseService = CourseService();

  bool _isLoggingOut = false;
  bool _isLoadingStats = true;
  String? _statsError;
  int _courseCount = 0;
  int _assignmentCount = 0;
  int _quizCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadDashboardStats();
    });
  }

  Future<void> _loadDashboardStats() async {
    setState(() {
      _isLoadingStats = true;
      _statsError = null;
    });
    try {
      var page = 1;
      var hasNextPage = true;
      final courses = <Course>[];
      while (hasNextPage) {
        final result = await _courseService.getInstructorCourses(
          page: page++,
          limit: 100,
        );
        courses.addAll(result.courses);
        hasNextPage = result.pagination.hasNextPage;
      }

      final contentCounts = await Future.wait(
        courses.map((course) async {
          final counts = await Future.wait([
            _courseService.getInstructorAssignments(course.id),
            _courseService.getInstructorQuizzes(course.id),
          ]);
          return [
            (counts[0] as List).length,
            (counts[1] as List).length,
          ];
        }),
      );
      if (!mounted) return;
      setState(() {
        _courseCount = courses.length;
        _assignmentCount = contentCounts.fold<int>(
          0, (total, counts) => total + counts[0],
        );
        _quizCount = contentCounts.fold<int>(
          0, (total, counts) => total + counts[1],
        );
        _isLoadingStats = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _statsError = error.message;
        _isLoadingStats = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _statsError = 'Unable to load dashboard counts. Pull to retry.';
        _isLoadingStats = false;
      });
    }
  }

  Future<void> _openCreateCourse() async {
    final created = await Navigator.pushNamed(
      context,
      '/instructor-create-course',
    );
    if (created == true) await _loadDashboardStats();
  }

  Widget _buildStatCard({
    required String title,
    required int count,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 160,
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: theme.colorScheme.primary),
                const SizedBox(height: 12),
                Text(
                  _isLoadingStats ? '—' : '$count',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(title, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogout() async {
    if (_isLoggingOut) {
      return;
    }

    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text(
            'Are you sure you want to logout?',
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
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (shouldLogout != true || !mounted) {
      return;
    }

    setState(() {
      _isLoggingOut = true;
    });

    try {
      await _authService.logout();

      if (!mounted) {
        return;
      }

      Navigator.pushNamedAndRemoveUntil(
        context,
        '/login',
        (route) => false,
      );
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(error.message);
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'Logout failed. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoggingOut = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          const NotificationsAction(),
          IconButton(
            onPressed: () {
              Navigator.pushNamed(context, '/profile');
            },
            icon: const Icon(Icons.account_circle_outlined),
            tooltip: 'Profile',
          ),
          IconButton(
            onPressed: _isLoggingOut ? null : _handleLogout,
            icon: _isLoggingOut
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.logout_outlined),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome back, Instructor!',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                'Manage your courses and learners.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: SectionHeader(title: 'Overview'),
                  ),
                  IconButton(
                    tooltip: 'Refresh counts',
                    onPressed: _isLoadingStats ? null : _loadDashboardStats,
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
              if (_statsError != null)
                MessageWidget(
                  title: 'Some counts could not be loaded',
                  message: _statsError!,
                  type: MessageType.error,
                  actionLabel: 'Retry',
                  onActionPressed: _loadDashboardStats,
                ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildStatCard(
                    title: 'Courses',
                    count: _courseCount,
                    icon: Icons.menu_book_outlined,
                    onTap: () => Navigator.pushNamed(context, '/instructor-courses'),
                  ),
                  _buildStatCard(
                    title: 'Assignments',
                    count: _assignmentCount,
                    icon: Icons.assignment_outlined,
                    onTap: () => Navigator.pushNamed(context, '/instructor-courses'),
                  ),
                  _buildStatCard(
                    title: 'Quizzes',
                    count: _quizCount,
                    icon: Icons.quiz_outlined,
                    onTap: () => Navigator.pushNamed(context, '/instructor-courses'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const SectionHeader(
                title: 'Course Management',
              ),
              const SizedBox(height: 10),
              DashboardNavCard(
                title: 'My Courses',
                subtitle: 'Choose a course to manage its content',
                icon: Icons.menu_book_outlined,
                onTap: () =>
                    Navigator.pushNamed(context, '/instructor-courses'),
              ),
              DashboardNavCard(
                title: 'Create Course',
                subtitle: 'Add a course to your teaching catalogue',
                icon: Icons.add_circle_outline,
                onTap: _openCreateCourse,
              ),
              const DashboardNavCard(
                title: 'Course Builder',
                subtitle: 'Course building is not available yet',
                icon: Icons.tune_outlined,
                unavailableLabel: 'Coming soon',
              ),
              DashboardNavCard(
                title: 'Quizzes',
                subtitle: 'Choose a course to manage its quizzes',
                icon: Icons.quiz_outlined,
                onTap: () =>
                    Navigator.pushNamed(context, '/instructor-courses'),
              ),
              DashboardNavCard(
                title: 'Assignments',
                subtitle: 'Choose a course to manage its assignments',
                icon: Icons.assignment_outlined,
                onTap: () =>
                    Navigator.pushNamed(context, '/instructor-courses'),
              ),
              const SizedBox(height: 24),
              const SectionHeader(
                title: 'Learner Management',
              ),
              const SizedBox(height: 10),
              const DashboardNavCard(
                title: 'Enrollments',
                subtitle: 'Enrollment management is not available yet',
                icon: Icons.group_outlined,
                unavailableLabel: 'Coming soon',
              ),
              DashboardNavCard(
                title: 'Submissions',
                subtitle: 'Review and grade submissions',
                icon: Icons.fact_check_outlined,
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/instructor-courses',
                  );
                },
              ),
              DashboardNavCard(
                title: 'Profile',
                subtitle: 'Manage instructor profile',
                icon: Icons.person_outline,
                onTap: () {
                  Navigator.pushNamed(context, '/profile');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
