import 'package:flutter/material.dart';

import 'student_dashboard.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return const RoleDashboardScreen(
      title: 'Admin Dashboard',
      role: 'ADMIN',
      icon: Icons.admin_panel_settings_rounded,
    );
  }
}