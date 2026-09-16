import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_lms/core/storage/token_storage.dart';
import 'package:flutter_lms/screens/onboarding_screen.dart';
import 'package:flutter_lms/screens/splash_screen.dart';

class FakeTokenStorage extends TokenStorage {
  FakeTokenStorage();

  @override
  Future<String?> getAccessToken() async {
    return null;
  }

  @override
  Future<String?> getRefreshToken() async {
    return null;
  }

  @override
  Future<String?> getRole() async {
    return null;
  }

  @override
  Future<bool> isOnboardingCompleted() async {
    return false;
  }
}

void main() {
  testWidgets(
    'Flutter LMS starts with splash screen',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SplashScreen(
            tokenStorage: FakeTokenStorage(),
          ),
        ),
      );

      // Splash screen should appear first.
      expect(find.byType(SplashScreen), findsOneWidget);
      expect(find.text('Flutter LMS'), findsOneWidget);
      expect(find.text('Learning Management System'), findsOneWidget);

      // Wait for the splash delay.
      await tester.pump(const Duration(seconds: 2));

      // Allow the async session check and navigation transition to complete.
      await tester.pump();

      // Onboarding screen should appear.
      expect(find.byType(OnboardingScreen), findsOneWidget);
    },
  );
}