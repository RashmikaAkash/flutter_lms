import 'dart:async';

import 'package:flutter/material.dart';

import '../core/storage/token_storage.dart';
import 'login_screen.dart';
import 'onboarding_screen.dart';
import 'student_dashboard.dart';
import 'instructor_dashboard.dart';
import 'admin_dashboard.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
    this.tokenStorage,
  });

  final TokenStorage? tokenStorage;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late final TokenStorage _tokenStorage;

  @override
  void initState() {
    super.initState();

    _tokenStorage = widget.tokenStorage ?? TokenStorage();

    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) {
      return;
    }

    final accessToken = await _tokenStorage.getAccessToken();
    final refreshToken = await _tokenStorage.getRefreshToken();
    final role = await _tokenStorage.getRole();
    final onboardingCompleted =
    await _tokenStorage.isOnboardingCompleted();

    if (!mounted) {
      return;
    }

    final hasValidSession =
        accessToken != null &&
            accessToken.isNotEmpty &&
            refreshToken != null &&
            refreshToken.isNotEmpty &&
            role != null &&
            role.isNotEmpty;

    if (hasValidSession) {
      switch (role) {
        case 'STUDENT':
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const StudentDashboard(),
            ),
          );
          break;

        case 'INSTRUCTOR':
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const InstructorDashboard(),
            ),
          );
          break;

        case 'ADMIN':
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const AdminDashboard(),
            ),
          );
          break;

        default:
          await _tokenStorage.clearSession();

          if (!mounted) {
            return;
          }

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const LoginScreen(),
            ),
          );
      }

      return;
    }

    if (onboardingCompleted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        ),
      );
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const OnboardingScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/logo.png',
              width: 110,
              height: 110,
            ),
            const SizedBox(height: 24),
            Text(
              'Flutter LMS',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Learning Management System',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 30),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}