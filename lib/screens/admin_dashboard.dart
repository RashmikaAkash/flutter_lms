import 'package:flutter/material.dart';

import '../core/auth/auth_service.dart';
import '../core/errors/api_exception.dart';
import '../widgets/dashboard_nav_card.dart';
import '../widgets/message_widget.dart';
import '../widgets/section_header.dart';
import 'notifications_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
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
            onPressed: () => Navigator.pushNamed(context, '/profile'),
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
                'Welcome back, Admin!',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                'Monitor and manage the LMS platform.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              const MessageWidget(
                title: 'Admin tools unavailable',
                message: 'Platform management and live statistics are not '
                    'available yet.',
                type: MessageType.info,
              ),
              const SizedBox(height: 24),
              const SectionHeader(
                title: 'Platform Management',
              ),
              const SizedBox(height: 10),
              const DashboardNavCard(
                title: 'Users',
                subtitle: 'User management is not available yet',
                icon: Icons.people_outline,
                unavailableLabel: 'Coming soon',
              ),
              const DashboardNavCard(
                title: 'Categories',
                subtitle: 'Category management is not available yet',
                icon: Icons.category_outlined,
                unavailableLabel: 'Coming soon',
              ),
              const DashboardNavCard(
                title: 'Courses',
                subtitle: 'Course management is not available yet',
                icon: Icons.library_books_outlined,
                unavailableLabel: 'Coming soon',
              ),
              const DashboardNavCard(
                title: 'Enrollments',
                subtitle: 'Enrollment management is not available yet',
                icon: Icons.how_to_reg_outlined,
                unavailableLabel: 'Coming soon',
              ),
              const DashboardNavCard(
                title: 'Reviews',
                subtitle: 'Review moderation is not available yet',
                icon: Icons.rate_review_outlined,
                unavailableLabel: 'Coming soon',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
