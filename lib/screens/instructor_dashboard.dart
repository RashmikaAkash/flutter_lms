import 'package:flutter/material.dart';

import '../core/auth/auth_service.dart';
import '../core/errors/api_exception.dart';
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

  bool _isLoggingOut = false;

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
              const MessageWidget(
                title: 'Dashboard statistics unavailable',
                message:
                    'Live course and learner counts are not connected yet. '
                    'Your course tools are available below.',
                type: MessageType.info,
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
              const DashboardNavCard(
                title: 'Create Course',
                subtitle: 'Course creation is not available yet',
                icon: Icons.build_outlined,
                unavailableLabel: 'Coming soon',
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
