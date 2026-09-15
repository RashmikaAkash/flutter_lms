import 'package:flutter/material.dart';

import '../widgets/dashboard_card.dart';
import '../widgets/dashboard_nav_card.dart';
import '../widgets/section_header.dart';

class InstructorDashboard extends StatelessWidget {
  const InstructorDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Instructor Dashboard'),
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

              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.45,
                children: [
                  DashboardCard(
                    title: 'Courses',
                    value: '6',
                    icon: Icons.menu_book_outlined,
                    onTap: () {},
                  ),
                  DashboardCard(
                    title: 'Students',
                    value: '124',
                    icon: Icons.people_outline,
                    onTap: () {},
                  ),
                  DashboardCard(
                    title: 'Assignments',
                    value: '15',
                    icon: Icons.assignment_outlined,
                    onTap: () {},
                  ),
                  DashboardCard(
                    title: 'Pending Reviews',
                    value: '7',
                    icon: Icons.rate_review_outlined,
                    onTap: () {},
                  ),
                ],
              ),

              const SizedBox(height: 24),

              const SectionHeader(
                title: 'Course Management',
                actionLabel: 'View All',
              ),

              const SizedBox(height: 10),

              DashboardNavCard(
                title: 'Create Course',
                subtitle: 'Build a new learning course',
                icon: Icons.add_circle_outline,
                onTap: () {},
              ),

              DashboardNavCard(
                title: 'Course Builder',
                subtitle: 'Manage sections and lessons',
                icon: Icons.build_outlined,
                onTap: () {},
              ),

              DashboardNavCard(
                title: 'Quizzes',
                subtitle: 'Create and manage quizzes',
                icon: Icons.quiz_outlined,
                onTap: () {},
              ),

              DashboardNavCard(
                title: 'Assignments',
                subtitle: 'Manage learner assignments',
                icon: Icons.assignment_outlined,
                onTap: () {},
              ),

              const SizedBox(height: 24),

              const SectionHeader(
                title: 'Learner Management',
                actionLabel: 'View All',
              ),

              const SizedBox(height: 10),

              DashboardNavCard(
                title: 'Enrollments',
                subtitle: 'Inspect enrolled learners',
                icon: Icons.group_outlined,
                onTap: () {},
              ),

              DashboardNavCard(
                title: 'Submissions',
                subtitle: 'Review and grade submissions',
                icon: Icons.fact_check_outlined,
                onTap: () {},
              ),

              DashboardNavCard(
                title: 'Profile',
                subtitle: 'Manage instructor profile',
                icon: Icons.person_outline,
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }
}