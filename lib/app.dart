import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'screens/student_dashboard.dart';
import 'screens/instructor_dashboard.dart';
import 'screens/admin_dashboard.dart';
import 'screens/login_screen.dart';
import 'screens/student_registration_screen.dart';
import 'screens/email_verification_screen.dart';
import 'screens/instructor_registration_screen.dart';
import 'screens/registration_role_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/password_reset_otp_screen.dart';
import 'screens/reset_password_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/student_profile_screen.dart';
import 'screens/course_browse_screen.dart';
import 'screens/course_details_screen.dart';
import 'screens/my_courses_screen.dart';
import 'screens/course_curriculum_screen.dart';
import 'screens/lesson_player_screen.dart';
import 'screens/completed_courses_screen.dart';
import 'screens/student_quiz_list_screen.dart';
import 'screens/student_quiz_detail_screen.dart';
import 'screens/student_assignment_list_screen.dart';
import 'screens/student_assignment_detail_screen.dart';
import 'screens/instructor_assignment_submissions_screen.dart';
import 'screens/instructor_course_list_screen.dart';
import 'screens/instructor_assignment_list_screen.dart';
import 'screens/instructor_quiz_list_screen.dart';
import 'screens/instructor_quiz_detail_screen.dart';
import 'screens/instructor_quiz_attempts_screen.dart';
import 'core/models/quiz/quiz_attempt.dart';
import 'screens/instructor_quiz_attempt_review_screen.dart';
import 'screens/instructor_create_quiz_screen.dart';
import 'screens/instructor_create_assignment_screen.dart';
import 'screens/course_reviews_screen.dart';
import 'screens/notifications_screen.dart';

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
        '/login': (context) => const LoginScreen(),
        '/registration-role': (context) => const RegistrationRoleScreen(),
        '/student-registration': (context) => const StudentRegistrationScreen(),
        '/instructor-registration': (context) =>
            const InstructorRegistrationScreen(),

        '/email-verification': (context) {
          final email = ModalRoute.of(context)?.settings.arguments as String?;

          if (email == null || email.isEmpty) {
            return const LoginScreen();
          }

          return EmailVerificationScreen(email: email);
        },

        // ------------------------------------------------------------
        // PASSWORD RECOVERY
        // ------------------------------------------------------------
        '/forgot-password': (context) => const ForgotPasswordScreen(),

        '/password-reset-otp': (context) {
          final email = ModalRoute.of(context)?.settings.arguments as String?;

          if (email == null || email.isEmpty) {
            return const LoginScreen();
          }

          return PasswordResetOtpScreen(email: email);
        },

        '/reset-password': (context) {
          final arguments = ModalRoute.of(context)?.settings.arguments;

          if (arguments is! Map<String, dynamic>) {
            return const LoginScreen();
          }

          final resetToken = arguments['resetToken'];

          if (resetToken is! String || resetToken.isEmpty) {
            return const LoginScreen();
          }

          return ResetPasswordScreen(
            resetToken: resetToken,
          );
        },

        '/profile': (context) => const ProfileScreen(),
        '/student-profile': (context) => const StudentProfileScreen(),
        '/course-browse': (context) => const CourseBrowseScreen(),
        '/course-details': (context) {
          final arguments = ModalRoute.of(context)?.settings.arguments;

          if (arguments is! Map<String, dynamic>) {
            return const CourseBrowseScreen();
          }

          final courseId = arguments['courseId'];

          if (courseId is! String || courseId.isEmpty) {
            return const CourseBrowseScreen();
          }

          final showEnrollButton =
              arguments['showEnrollButton'] as bool? ?? true;

          final enrollmentId = arguments['enrollmentId'];

          return CourseDetailsScreen(
            courseId: courseId,
            showEnrollButton: showEnrollButton,
            enrollmentId: enrollmentId is String && enrollmentId.isNotEmpty
                ? enrollmentId
                : null,
          );
        },
        '/course-reviews': (context) {
          final arguments = ModalRoute.of(context)?.settings.arguments;
          if (arguments is! Map<String, dynamic>) {
            return const CourseBrowseScreen();
          }
          final courseId = arguments['courseId'];
          final courseTitle = arguments['courseTitle'];
          final isEnrolled = arguments['isEnrolled'];
          if (courseId is! String || courseId.isEmpty) {
            return const CourseBrowseScreen();
          }
          return CourseReviewsScreen(
            courseId: courseId,
            courseTitle: courseTitle is String ? courseTitle : 'Course',
            isEnrolled: isEnrolled == true,
          );
        },
        '/notifications': (context) => const NotificationsScreen(),
        '/course-curriculum': (context) {
          final arguments = ModalRoute.of(context)?.settings.arguments;

          if (arguments is! Map<String, dynamic>) {
            return const CourseBrowseScreen();
          }

          final courseId = arguments['courseId'];

          if (courseId is! String || courseId.isEmpty) {
            return const CourseBrowseScreen();
          }

          final enrollmentId = arguments['enrollmentId'];

          return CourseCurriculumScreen(
            courseId: courseId,
            enrollmentId: enrollmentId is String && enrollmentId.isNotEmpty
                ? enrollmentId
                : null,
          );
        },
        '/lesson-player': (context) {
          final lessonId =
              ModalRoute.of(context)?.settings.arguments as String?;

          if (lessonId == null || lessonId.isEmpty) {
            return const CourseBrowseScreen();
          }

          return LessonPlayerScreen(
            lessonId: lessonId,
          );
        },
        '/student-quizzes': (context) {
          final arguments = ModalRoute.of(context)?.settings.arguments;

          if (arguments is! Map<String, dynamic>) {
            return const CourseBrowseScreen();
          }

          final courseId = arguments['courseId'];

          if (courseId is! String || courseId.isEmpty) {
            return const CourseBrowseScreen();
          }

          return StudentQuizListScreen(
            courseId: courseId,
          );
        },
        '/student-quiz-detail': (context) {
          final quizId = ModalRoute.of(context)?.settings.arguments as String?;

          if (quizId == null || quizId.isEmpty) {
            return const CourseBrowseScreen();
          }

          return StudentQuizDetailScreen(
            quizId: quizId,
          );
        },
        '/student-assignments': (context) {
          final arguments = ModalRoute.of(context)?.settings.arguments;

          if (arguments is! Map<String, dynamic>) {
            return const CourseBrowseScreen();
          }

          final courseId = arguments['courseId'];

          if (courseId is! String || courseId.isEmpty) {
            return const CourseBrowseScreen();
          }

          return StudentAssignmentListScreen(
            courseId: courseId,
          );
        },
        '/student-assignment-detail': (context) {
          final assignmentId =
              ModalRoute.of(context)?.settings.arguments as String?;

          if (assignmentId == null || assignmentId.isEmpty) {
            return const CourseBrowseScreen();
          }

          return StudentAssignmentDetailScreen(
            assignmentId: assignmentId,
          );
        },
        '/instructor-assignment-submissions': (context) {
          final assignmentId =
              ModalRoute.of(context)?.settings.arguments as String?;

          if (assignmentId == null || assignmentId.isEmpty) {
            return const InstructorDashboard();
          }

          return InstructorAssignmentSubmissionsScreen(
            assignmentId: assignmentId,
          );
        },
        '/instructor-courses': (context) {
          return const InstructorCourseListScreen();
        },
        '/instructor-assignment-list': (context) {
          final courseId =
              ModalRoute.of(context)?.settings.arguments as String?;

          if (courseId == null || courseId.isEmpty) {
            return const InstructorDashboard();
          }

          return InstructorAssignmentListScreen(
            courseId: courseId,
          );
        },
        '/instructor-create-assignment': (context) {
          final courseId =
              ModalRoute.of(context)?.settings.arguments as String?;

          if (courseId == null || courseId.isEmpty) {
            return const InstructorDashboard();
          }

          return InstructorCreateAssignmentScreen(
            courseId: courseId,
          );
        },
        '/instructor-quizzes': (context) {
          final courseId =
              ModalRoute.of(context)?.settings.arguments as String?;

          if (courseId == null || courseId.isEmpty) {
            return const InstructorDashboard();
          }

          return InstructorQuizListScreen(
            courseId: courseId,
          );
        },
        '/instructor-quiz-detail': (context) {
          final quizId = ModalRoute.of(context)?.settings.arguments as String?;

          if (quizId == null || quizId.isEmpty) {
            return const InstructorDashboard();
          }

          return InstructorQuizDetailScreen(
            quizId: quizId,
          );
        },
        '/instructor-quiz-attempts': (context) {
          final quizId = ModalRoute.of(context)?.settings.arguments as String?;

          if (quizId == null || quizId.isEmpty) {
            return const InstructorDashboard();
          }

          return InstructorQuizAttemptsScreen(
            quizId: quizId,
          );
        },
        '/instructor-quiz-attempt-review': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;

          if (args is! Map<String, dynamic>) {
            return const InstructorDashboard();
          }

          final quizId = args['quizId']?.toString() ?? '';
          final attempt = args['attempt'];

          if (quizId.isEmpty || attempt is! QuizAttempt) {
            return const InstructorDashboard();
          }

          return InstructorQuizAttemptReviewScreen(
            quizId: quizId,
            attempt: attempt,
          );
        },
        '/instructor-create-quiz': (context) {
          final courseId =
              ModalRoute.of(context)?.settings.arguments as String?;

          if (courseId == null || courseId.isEmpty) {
            return const InstructorDashboard();
          }

          return InstructorCreateQuizScreen(
            courseId: courseId,
          );
        },
        '/completed-courses': (context) => const CompletedCoursesScreen(),
        '/my-courses': (context) => const MyCoursesScreen(),
        '/student-dashboard': (context) => const StudentDashboard(),
        '/instructor-dashboard': (context) => const InstructorDashboard(),
        '/admin-dashboard': (context) => const AdminDashboard(),
      },
      home: const SplashScreen(),
    );
  }
}
