import 'package:flutter/material.dart';

import 'student_dashboard.dart';

class InstructorDashboard extends StatelessWidget {
  const InstructorDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return const RoleDashboardScreen(
      title: 'Instructor Dashboard',
      role: 'INSTRUCTOR',
      icon: Icons.co_present_rounded,
    );
  }
}