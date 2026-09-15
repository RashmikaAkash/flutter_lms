import 'package:flutter/material.dart';

import '../widgets/dashboard_card.dart';
import '../widgets/dashboard_nav_card.dart';
import '../widgets/section_header.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
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

              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.45,
                children: [
                  DashboardCard(
                    title: 'Users',
                    value: '450',
                    icon: Icons.people_outline,
                    onTap: () {},
                  ),
                  DashboardCard(
                    title: 'Courses',
                    value: '32',
                    icon: Icons.menu_book_outlined,
                    onTap: () {},
                  ),
                  DashboardCard(
                    title: 'Enrollments',
                    value: '780',
                    icon: Icons.how_to_reg_outlined,
                    onTap: () {},
                  ),
                  DashboardCard(
                    title: 'Reviews',
                    value: '96',
                    icon: Icons.reviews_outlined,
                    onTap: () {},
                  ),
                ],
              ),

              const SizedBox(height: 24),

              const SectionHeader(
                title: 'Platform Management',
                actionLabel: 'View All',
              ),

              const SizedBox(height: 10),

              DashboardNavCard(
                title: 'Users',
                subtitle: 'Manage students and instructors',
                icon: Icons.people_outline,
                onTap: () {},
              ),

              DashboardNavCard(
                title: 'Categories',
                subtitle: 'Manage course categories',
                icon: Icons.category_outlined,
                onTap: () {},
              ),

              DashboardNavCard(
                title: 'Courses',
                subtitle: 'Inspect and manage platform courses',
                icon: Icons.library_books_outlined,
                onTap: () {},
              ),

              DashboardNavCard(
                title: 'Enrollments',
                subtitle: 'Inspect platform enrollments',
                icon: Icons.how_to_reg_outlined,
                onTap: () {},
              ),

              DashboardNavCard(
                title: 'Reviews',
                subtitle: 'Moderate learner reviews',
                icon: Icons.rate_review_outlined,
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }
}