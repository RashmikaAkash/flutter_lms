import 'package:flutter/material.dart';

import '../widgets/dashboard_card.dart';
import '../widgets/dashboard_nav_card.dart';
import '../widgets/section_header.dart';

class StudentDashboard extends StatelessWidget {
  const StudentDashboard({super.key});

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
            onPressed: () {},
            icon: const Icon(Icons.account_circle_outlined),
            tooltip: 'Profile',
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
                onTap: () {},
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