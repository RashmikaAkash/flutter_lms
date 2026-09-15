// import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_lms/app.dart';
import 'package:flutter_lms/screens/onboarding_screen.dart';
import 'package:flutter_lms/screens/splash_screen.dart';

void main() {
  testWidgets(
    'Flutter LMS starts with splash screen',
        (WidgetTester tester) async {
      await tester.pumpWidget(const FlutterLmsApp());

      // Splash screen should appear first
      expect(find.byType(SplashScreen), findsOneWidget);
      expect(find.text('Flutter LMS'), findsOneWidget);
      expect(find.text('Learning Management System'), findsOneWidget);

      // Wait for splash timer
      await tester.pump(const Duration(seconds: 2));

      // Allow navigation transition to complete
      await tester.pumpAndSettle();

      // Onboarding screen should appear
      expect(find.byType(OnboardingScreen), findsOneWidget);
    },
  );
}