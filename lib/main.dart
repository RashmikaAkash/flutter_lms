import 'package:flutter/material.dart';

void main() {
  runApp(const FlutterLmsApp());
}

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

        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.3),

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

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 0,
          ),
        ),

        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            side: BorderSide(
              color: colorScheme.outlineVariant,
            ),
          ),
        ),
      ),

      home: const LoginScreen(),
    );
  }
}

// ============================================================
// LOGIN SCREEN
// ============================================================

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Form key
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Password visibility state
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------
  // Email validation
  // ------------------------------------------------------------

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';

    if (email.isEmpty) {
      return 'Please enter your email';
    }

    final emailPattern = RegExp(
      r'^[\w.-]+@[\w-]+(\.[\w-]+)+$',
    );

    if (!emailPattern.hasMatch(email)) {
      return 'Enter a valid email address';
    }

    return null;
  }

  // ------------------------------------------------------------
  // Password validation
  // ------------------------------------------------------------

  String? _validatePassword(String? value) {
    final password = value ?? '';

    if (password.isEmpty) {
      return 'Please enter your password';
    }

    if (password.length < 6) {
      return 'Password must be at least 6 characters';
    }

    return null;
  }

  // ------------------------------------------------------------
  // Login button
  // ------------------------------------------------------------

  void _handleLogin() {
    // Hide keyboard
    FocusScope.of(context).unfocus();

    // Validate the form
    final isValid = _formKey.currentState?.validate() ?? false;

    if (!isValid) {
      return;
    }

    // Temporary local login flow.
    // Real API authentication will be implemented later.
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const HomeScreen(),
      ),
    );
  }

  // ------------------------------------------------------------
  // Forgot Password
  // ------------------------------------------------------------

  void _handleForgotPassword() {
    _showMessage('Password recovery will be added later');
  }

  // ------------------------------------------------------------
  // Guest access
  // ------------------------------------------------------------

  void _handleGuestContinue() {
    _showMessage('Guest access will be added later');
  }

  // ------------------------------------------------------------
  // SnackBar helper
  // ------------------------------------------------------------

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 32,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 420,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    const LoginHeader(),

                    const SizedBox(height: 36),

                    // --------------------------------------------------
                    // Email
                    // --------------------------------------------------

                    LoginTextField(
                      controller: _emailController,
                      label: 'Email',
                      hint: 'Enter your email',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: _validateEmail,

                      // Move to password field when pressing next
                      onFieldSubmitted: (_) {
                        FocusScope.of(context).nextFocus();
                      },
                    ),

                    const SizedBox(height: 18),

                    // --------------------------------------------------
                    // Password
                    // --------------------------------------------------

                    LoginTextField(
                      controller: _passwordController,
                      label: 'Password',
                      hint: 'Enter your password',
                      icon: Icons.lock_outline,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      validator: _validatePassword,

                      suffixIcon: IconButton(
                        tooltip: _obscurePassword
                            ? 'Show password'
                            : 'Hide password',
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),

                      onFieldSubmitted: (_) {
                        _handleLogin();
                      },
                    ),

                    // --------------------------------------------------
                    // Forgot Password
                    // --------------------------------------------------

                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _handleForgotPassword,
                        child: const Text(
                          'Forgot Password?',
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // --------------------------------------------------
                    // Login Button
                    // --------------------------------------------------

                    PrimaryButton(
                      label: 'Login',
                      icon: Icons.arrow_forward_rounded,
                      onPressed: _handleLogin,
                    ),

                    const SizedBox(height: 24),

                    // --------------------------------------------------
                    // OR divider
                    // --------------------------------------------------

                    _buildOrDivider(context),

                    const SizedBox(height: 20),

                    // --------------------------------------------------
                    // Guest button
                    // --------------------------------------------------

                    OutlinedButton(
                      onPressed: _handleGuestContinue,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                        ),
                      ),
                      child: const Text(
                        'Continue as Guest',
                      ),
                    ),

                    const SizedBox(height: 32),

                    // --------------------------------------------------
                    // Supported roles
                    // --------------------------------------------------

                    Text(
                      'Student  •  Instructor  •  Admin',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrDivider(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.outlineVariant;

    return Row(
      children: [
        Expanded(
          child: Divider(
            color: color,
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
          ),
          child: Text(
            'OR',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),

        Expanded(
          child: Divider(
            color: color,
          ),
        ),
      ],
    );
  }
}

// ============================================================
// LOGIN HEADER
// ============================================================

class LoginHeader extends StatelessWidget {
  const LoginHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        Container(
          width: 84,
          height: 84,
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Image.asset(
            'assets/images/logo.png',
            width: 84,
            height: 84,
          ),
        ),

        const SizedBox(height: 20),

        Text(
          'Flutter LMS',
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 6),

        Text(
          'Learn. Grow. Achieve.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

// ============================================================
// REUSABLE LOGIN TEXT FIELD
// ============================================================

class LoginTextField extends StatelessWidget {
  const LoginTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.suffixIcon,
    this.onFieldSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final Widget? suffixIcon;
  final ValueChanged<String>? onFieldSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,

      obscureText: obscureText,

      keyboardType: keyboardType,

      textInputAction: textInputAction,

      validator: validator,

      autovalidateMode: AutovalidateMode.onUserInteraction,

      onFieldSubmitted: onFieldSubmitted,

      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        suffixIcon: suffixIcon,
      ),
    );
  }
}

// ============================================================
// PRIMARY BUTTON
// ============================================================

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),

            if (icon != null) ...[
              const SizedBox(width: 8),
              Icon(
                icon,
                size: 20,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ============================================================
// TEMPORARY HOME SCREEN
// ============================================================

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Flutter LMS',
        ),
      ),

      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.home_rounded,
                size: 64,
              ),

              const SizedBox(height: 16),

              Text(
                'Welcome to Flutter LMS',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Login validation successful',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),

              const SizedBox(height: 24),

              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(
                  Icons.arrow_back,
                ),
                label: const Text(
                  'Back to Login',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}