import 'package:flutter/material.dart';
import '../widgets/dashboard_card.dart';
import '../widgets/dashboard_nav_card.dart';
import '../widgets/section_header.dart';
import '../core/auth/auth_service.dart';
import '../core/errors/api_exception.dart';

class StudentDashboard extends StatelessWidget {
  const StudentDashboard({super.key});

  Future<void> _handleLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text(
            'Are you sure you want to logout?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context, true);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Dashboard'),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_outlined),
            tooltip: 'Notifications',
          ),
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome back, Student!',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                'Continue your learning journey.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.45,
                children: [
                  DashboardCard(
                    title: 'Enrolled Courses',
                    value: '8',
                    icon: Icons.menu_book_outlined,
                    onTap: () {},
                  ),
                  DashboardCard(
                    title: 'Completed',
                    value: '3',
                    icon: Icons.check_circle_outline,
                    onTap: () {},
                  ),
                  DashboardCard(
                    title: 'Quizzes',
                    value: '12',
                    icon: Icons.quiz_outlined,
                    onTap: () {},
                  ),
                  DashboardCard(
                    title: 'Assignments',
                    value: '5',
                    icon: Icons.assignment_outlined,
                    onTap: () {},
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const SectionHeader(
                title: 'Continue Learning',
                actionLabel: 'View All',
              ),
              const SizedBox(height: 10),
              DashboardNavCard(
                title: 'Flutter Mobile Development',
                subtitle: 'Continue from Lesson 6',
                icon: Icons.phone_android,
                onTap: () {},
              ),
              const SizedBox(height: 10),
              DashboardNavCard(
                title: 'Dart Programming',
                subtitle: 'Continue from Module 3',
                icon: Icons.code,
                onTap: () {},
              ),
              const SizedBox(height: 24),
              const SectionHeader(
                title: 'Quick Access',
                actionLabel: 'View All',
              ),
              const SizedBox(height: 10),
              DashboardNavCard(
                title: 'My Courses',
                subtitle: 'View enrolled courses',
                icon: Icons.library_books_outlined,
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/my-courses',
                  );
                },
              ),
              const SectionHeader(
                title: 'Quick Access',
                actionLabel: 'View All',
              ),
              const SizedBox(height: 10),
              DashboardNavCard(
                title: 'Browse Courses',
                subtitle: 'Explore published courses',
                icon: Icons.explore_outlined,
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/course-browse',
                  );
                },
              ),
              DashboardNavCard(
                title: 'My Courses',
                subtitle: 'View enrolled courses',
                icon: Icons.library_books_outlined,
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/my-courses',
                  );
                },
              ),
              DashboardNavCard(
                title: 'Quizzes',
                subtitle: 'View available quizzes',
                icon: Icons.quiz_outlined,
                onTap: () {},
              ),
              DashboardNavCard(
                title: 'Assignments',
                subtitle: 'View and submit assignments',
                icon: Icons.assignment_outlined,
                onTap: () {},
              ),
              DashboardNavCard(
                title: 'Notifications',
                subtitle: 'Check recent notifications',
                icon: Icons.notifications_outlined,
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }
}
