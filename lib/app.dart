import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'screens/student_dashboard.dart';
import 'screens/instructor_dashboard.dart';
import 'screens/admin_dashboard.dart';

class FlutterLmsApp extends StatelessWidget {
  const FlutterLmsApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: Colors.indigo,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter LMS',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Poppins',
        colorScheme: colorScheme,
        scaffoldBackgroundColor: colorScheme.surface,

        // ----------------------------------------------------------
        // Text styles
        // ----------------------------------------------------------
        textTheme: const TextTheme(
          displaySmall: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
          ),
          headlineSmall: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
          ),
          titleLarge: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
          ),
          titleMedium: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
          ),
          bodyLarge: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w400,
          ),
          bodyMedium: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w400,
          ),
          bodySmall: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w400,
          ),
          labelLarge: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
          ),
        ),

        // ----------------------------------------------------------
        // Input fields
        // ----------------------------------------------------------
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.3),

          labelStyle: TextStyle(
            fontFamily: 'Poppins',
            color: colorScheme.onSurfaceVariant,
          ),

          hintStyle: TextStyle(
            fontFamily: 'Poppins',
            color: colorScheme.onSurfaceVariant,
          ),

          prefixIconColor: colorScheme.onSurfaceVariant,
          suffixIconColor: colorScheme.onSurfaceVariant,

          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),

          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),

          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: colorScheme.primary,
              width: 1.6,
            ),
          ),

          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: colorScheme.error,
              width: 1.2,
            ),
          ),

          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: colorScheme.error,
              width: 1.6,
            ),
          ),

          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),

        // ----------------------------------------------------------
        // Elevated buttons
        // ----------------------------------------------------------
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        // ----------------------------------------------------------
        // Outlined buttons
        // ----------------------------------------------------------
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            foregroundColor: colorScheme.primary,
            side: BorderSide(
              color: colorScheme.outlineVariant,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        // ----------------------------------------------------------
        // Text buttons
        // ----------------------------------------------------------
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: colorScheme.primary,
            textStyle: const TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        // ----------------------------------------------------------
        // Cards
        // ----------------------------------------------------------
        cardTheme: CardTheme(
          elevation: 0,
          color: colorScheme.surfaceContainerLow,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: colorScheme.outlineVariant,
            ),
          ),
        ),

        // ----------------------------------------------------------
        // AppBar
        // ----------------------------------------------------------
        appBarTheme: AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: colorScheme.surface,
          foregroundColor: colorScheme.onSurface,
          titleTextStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),

        dividerTheme: DividerThemeData(
          color: colorScheme.outlineVariant,
          thickness: 1,
        ),
      ),
      routes: {
        '/student-dashboard': (context) => const StudentDashboard(),
        '/instructor-dashboard': (context) => const InstructorDashboard(),
        '/admin-dashboard': (context) => const AdminDashboard(),
      },
      home: const SplashScreen(),
    );
  }
}