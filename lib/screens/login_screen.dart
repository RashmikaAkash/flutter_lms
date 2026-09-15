import 'package:flutter/material.dart';
import '../widgets/login_header.dart';
import '../widgets/login_text_field.dart';
import '../widgets/primary_button.dart';
// import 'home_screen.dart';
// import 'api_test_screen.dart';
import '../core/auth/auth_service.dart';
import '../core/errors/api_exception.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final AuthService _authService = AuthService();

  bool _isLoading = false;

  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

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

  Future<void> _handleLogin() async {
    FocusScope.of(context).unfocus();

    final isValid = _formKey.currentState?.validate() ?? false;

    if (!isValid || _isLoading) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final role = await _authService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) {
        return;
      }

      switch (role) {
        case 'STUDENT':
          Navigator.pushReplacementNamed(
            context,
            '/student-dashboard',
          );
          break;

        case 'INSTRUCTOR':
          Navigator.pushReplacementNamed(
            context,
            '/instructor-dashboard',
          );
          break;

        case 'ADMIN':
          Navigator.pushReplacementNamed(
            context,
            '/admin-dashboard',
          );
          break;

        default:
          _showMessage('Unknown user role: $role');
      }
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(error.message);
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showMessage('Login failed. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _handleForgotPassword() {
    _showMessage('Password recovery will be added later');
  }

  void _handleGuestContinue() {
    _showMessage('Guest access will be added later');
  }

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
                    const LoginHeader(),

                    const SizedBox(height: 36),

                    LoginTextField(
                      controller: _emailController,
                      label: 'Email',
                      hint: 'Enter your email',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: _validateEmail,
                      onFieldSubmitted: (_) {
                        FocusScope.of(context).nextFocus();
                      },
                    ),

                    const SizedBox(height: 18),

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

                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _handleForgotPassword,
                        child: const Text('Forgot Password?'),
                      ),
                    ),

                    const SizedBox(height: 8),

                    PrimaryButton(
                      label: _isLoading ? 'Signing in...' : 'Login',
                      icon: Icons.arrow_forward_rounded,
                      onPressed: _isLoading ? null : _handleLogin,
                    ),

                    const SizedBox(height: 24),

                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: colorScheme.outlineVariant,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                          ),
                          child: Text(
                            'OR',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: colorScheme.outlineVariant,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    OutlinedButton(
                      onPressed: _handleGuestContinue,
                      child: const Text('Continue as Guest'),
                    ),

                    const SizedBox(height: 12),

                    const SizedBox(height: 32),

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
}