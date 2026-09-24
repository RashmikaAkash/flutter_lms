import 'package:flutter/material.dart';

import '../core/auth/auth_service.dart';
import '../core/course/course_service.dart';
import '../core/errors/api_exception.dart';
import '../core/models/course/course_enrollment.dart';
import '../widgets/dashboard_card.dart';
import '../widgets/dashboard_nav_card.dart';
import '../widgets/message_widget.dart';
import '../widgets/section_header.dart';
import 'notifications_screen.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  final CourseService _courseService = CourseService();

  List<CourseEnrollment> _enrollments = [];

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      const limit = 20;
      var page = 1;
      final allEnrollments = <CourseEnrollment>[];

      while (true) {
        final result = await _courseService.getMyEnrollments(
          page: page,
          limit: limit,
        );

        allEnrollments.addAll(result.enrollments);

        if (!result.pagination.hasNextPage) {
          break;
        }

        page++;
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _enrollments = allEnrollments;
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
        _errorMessage = 'Unable to load dashboard data. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
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

    if (confirmed != true || !context.mounted) {
      return;
    }

    try {
      await AuthService().logout();

      if (!context.mounted) {
        return;
      }

      Navigator.of(context).pushNamedAndRemoveUntil(
        '/login',
        (route) => false,
      );
    } on ApiException catch (error) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
        ),
      );
    } catch (_) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Logout failed. Please try again.'),
        ),
      );
    }
  }

  Future<void> _handleLogoutAll(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Logout from all devices'),
          content: const Text(
            'This will sign you out from all active sessions. '
            'Do you want to continue?',
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
              child: const Text('Logout All'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    try {
      await AuthService().logoutAll();

      if (!context.mounted) {
        return;
      }

      Navigator.of(context).pushNamedAndRemoveUntil(
        '/login',
        (route) => false,
      );
    } on ApiException catch (error) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
        ),
      );
    } catch (_) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to logout from all devices. Please try again.',
          ),
        ),
      );
    }
  }

  List<CourseEnrollment> get _activeEnrollments {
    return _enrollments
        .where(
          (enrollment) => enrollment.progressPercentage < 100,
        )
        .toList();
  }

  int get _completedCount {
    return _enrollments
        .where(
          (enrollment) => enrollment.progressPercentage >= 100,
        )
        .length;
  }

  Future<void> _openAndRefresh(
    String route, {
    Object? arguments,
  }) async {
    await Navigator.pushNamed(
      context,
      route,
      arguments: arguments,
    );

    if (!mounted) {
      return;
    }

    await _loadDashboardData();
  }

  Widget _buildContinueLearning() {
    final courses = _activeEnrollments.take(2).toList();

    if (courses.isEmpty) {
      final colors = Theme.of(context).colorScheme;
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: colors.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.auto_stories_outlined, color: colors.primary, size: 28),
            const SizedBox(height: 12),
            Text('No active courses', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text('Browse courses and enroll to begin learning.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant)),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _openAndRefresh('/course-browse'),
              icon: const Icon(Icons.explore_outlined),
              label: const Text('Browse courses'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: courses.map(
        (enrollment) {
          final progress = enrollment.progressPercentage.clamp(
            0,
            100,
          );

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: DashboardNavCard(
              title: enrollment.courseTitle.isEmpty
                  ? 'Course'
                  : enrollment.courseTitle,
              subtitle: '${progress.toStringAsFixed(0)}% completed',
              icon: Icons.menu_book_outlined,
              onTap: () => _openAndRefresh(
                '/course-details',
                arguments: {
                  'courseId': enrollment.courseId,
                  'showEnrollButton': false,
                  'enrollmentId': enrollment.id,
                },
              ),
            ),
          );
        },
      ).toList(),
    );
  }

  Widget _buildDashboardContent() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text('Loading your learning space',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    )),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: MessageWidget(
            title: 'Unable to load dashboard',
            message: _errorMessage!,
            type: MessageType.error,
            actionLabel: 'Retry',
            onActionPressed: _loadDashboardData,
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 880),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.48),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('YOUR LEARNING SPACE',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            letterSpacing: 1.1,
                            fontWeight: FontWeight.w600,
                          )),
                  const SizedBox(height: 8),
                  Text('Welcome back, Student',
                      style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 4),
                  Text('Continue your learning journey.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          )),
                ],
              ),
            ),
            const SizedBox(height: 24),
            LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 350;
                return GridView.count(
                  crossAxisCount: compact ? 1 : 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  // Keep enough vertical room for the icon, wrapped title, and
                  // value inside DashboardCard on short and narrow screens.
                  childAspectRatio: compact ? 1.8 : 1.05,
                  children: [
                    DashboardCard(
                      title: 'Enrolled Courses',
                      value: _enrollments.length.toString(),
                      icon: Icons.menu_book_outlined,
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          '/my-courses',
                        );
                      },
                    ),
                    DashboardCard(
                      title: 'Completed',
                      value: _completedCount.toString(),
                      icon: Icons.check_circle_outline,
                      onTap: () => _openAndRefresh('/completed-courses'),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            const SectionHeader(
              title: 'Continue Learning',
            ),
            const SizedBox(height: 10),
            _buildContinueLearning(),
            const SizedBox(height: 24),
            const SectionHeader(
              title: 'Quick Access',
            ),
            const SizedBox(height: 10),
            DashboardNavCard(
              title: 'Browse Courses',
              subtitle: 'Explore published courses',
              icon: Icons.explore_outlined,
              onTap: () => _openAndRefresh('/course-browse'),
            ),
            const SizedBox(height: 10),
            DashboardNavCard(
              title: 'My Courses',
              subtitle: 'View enrolled courses',
              icon: Icons.library_books_outlined,
              onTap: () => _openAndRefresh('/my-courses'),
            ),
            const SizedBox(height: 10),
            DashboardNavCard(
              title: 'Quizzes',
              subtitle: 'Choose a course to view its quizzes',
              icon: Icons.quiz_outlined,
              onTap: () => _openAndRefresh('/my-courses'),
            ),
            const SizedBox(height: 10),
            DashboardNavCard(
              title: 'Assignments',
              subtitle: 'Choose a course to view its assignments',
              icon: Icons.assignment_outlined,
              onTap: () => _openAndRefresh('/my-courses'),
            ),
            const SizedBox(height: 10),
            DashboardNavCard(
              title: 'Notifications',
              subtitle: 'Check recent notifications',
              icon: Icons.notifications_outlined,
              onTap: () => _openAndRefresh('/notifications'),
            ),
              ],
            ),
          ),
        ),
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
              Navigator.pushNamed(
                context,
                '/profile',
              );
            },
            icon: const Icon(Icons.account_circle_outlined),
            tooltip: 'Profile',
          ),
          PopupMenuButton<String>(
            tooltip: 'Account actions',
            onSelected: (value) {
              if (value == 'logout_all') {
                _handleLogoutAll(context);
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem<String>(
                value: 'logout_all',
                child: Row(
                  children: [
                    Icon(Icons.logout_outlined),
                    SizedBox(width: 12),
                    Text('Logout from all devices'),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            onPressed: () => _handleLogout(context),
            icon: const Icon(Icons.logout_outlined),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: SafeArea(
        child: _buildDashboardContent(),
      ),
    );
  }
}
