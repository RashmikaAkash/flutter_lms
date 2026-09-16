import 'package:flutter/material.dart';

import '../core/auth/auth_service.dart';
import '../core/errors/api_exception.dart';
import '../widgets/login_text_field.dart';
import '../widgets/primary_button.dart';

class InstructorRegistrationScreen extends StatefulWidget {
  const InstructorRegistrationScreen({super.key});

  @override
  State<InstructorRegistrationScreen> createState() =>
      _InstructorRegistrationScreenState();
}

class _InstructorRegistrationScreenState
    extends State<InstructorRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _headlineController = TextEditingController();
  final _qualificationController = TextEditingController();
  final _experienceYearsController = TextEditingController();
  final _expertiseController = TextEditingController();
  final _biographyController = TextEditingController();

  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _headlineController.dispose();
    _qualificationController.dispose();
    _experienceYearsController.dispose();
    _expertiseController.dispose();
    _biographyController.dispose();
    super.dispose();
  }

  String? _validateRequired(
      String? value,
      String fieldName,
      ) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }

    return null;
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
      return 'Please enter a password';
    }

    if (password.length < 6) {
      return 'Password must be at least 6 characters';
    }

    return null;
  }

  String? _validateConfirmPassword(String? value) {
    final confirmPassword = value ?? '';

    if (confirmPassword.isEmpty) {
      return 'Please confirm your password';
    }

    if (confirmPassword != _passwordController.text) {
      return 'Passwords do not match';
    }

    return null;
  }

  String? _validateExperienceYears(String? value) {
    final experience = value?.trim() ?? '';

    if (experience.isEmpty) {
      return 'Please enter your experience years';
    }

    final years = int.tryParse(experience);

    if (years == null) {
      return 'Experience years must be a whole number';
    }

    if (years < 0) {
      return 'Experience years cannot be negative';
    }

    return null;
  }

  Future<void> _handleRegistration() async {
    FocusScope.of(context).unfocus();

    if (_isLoading) {
      return;
    }

    final isValid = _formKey.currentState?.validate() ?? false;

    if (!isValid) {
      return;
    }

    final experienceYears =
    int.tryParse(_experienceYearsController.text.trim());

    if (experienceYears == null) {
      _showMessage(
        'Please enter a valid number for experience years.',
      );
      return;
    }

    final expertise = _expertiseController.text
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();

    if (expertise.isEmpty) {
      _showMessage(
        'Please enter at least one area of expertise.',
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final message = await _authService.registerInstructor(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        confirmPassword: _confirmPasswordController.text,
        headline: _headlineController.text.trim(),
        qualification: _qualificationController.text.trim(),
        experienceYears: experienceYears,
        expertise: expertise,
        biography: _biographyController.text.trim(),
      );

      if (!mounted) {
        return;
      }

      await _showRegistrationSuccess(message);
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(error.message);
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'Instructor registration failed. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _showRegistrationSuccess(String message) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Registration Successful'),
          content: Text(
            message.isNotEmpty
                ? message
                : 'Instructor registration successful.\n'
                'Check your email for the verification OTP.',
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext);

                Navigator.pushReplacementNamed(
                  context,
                  '/email-verification',
                  arguments: _emailController.text.trim(),
                );
              },
              child: const Text('Continue'),
            ),
          ],
        );
      },
    );
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
      appBar: AppBar(
        title: const Text('Create Instructor Account'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 24,
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
                    Text(
                      'Instructor Registration',
                      style: theme.textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create your instructor account and start teaching.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 28),

                    LoginTextField(
                      controller: _firstNameController,
                      label: 'First Name',
                      hint: 'Enter your first name',
                      icon: Icons.person_outline,
                      textInputAction: TextInputAction.next,
                      validator: (value) =>
                          _validateRequired(value, 'First name'),
                    ),
                    const SizedBox(height: 16),

                    LoginTextField(
                      controller: _lastNameController,
                      label: 'Last Name',
                      hint: 'Enter your last name',
                      icon: Icons.person_outline,
                      textInputAction: TextInputAction.next,
                      validator: (value) =>
                          _validateRequired(value, 'Last name'),
                    ),
                    const SizedBox(height: 16),

                    LoginTextField(
                      controller: _emailController,
                      label: 'Email',
                      hint: 'Enter your email',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: _validateEmail,
                    ),
                    const SizedBox(height: 16),

                    LoginTextField(
                      controller: _passwordController,
                      label: 'Password',
                      hint: 'Create a password',
                      icon: Icons.lock_outline,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.next,
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
                    ),
                    const SizedBox(height: 16),

                    LoginTextField(
                      controller: _confirmPasswordController,
                      label: 'Confirm Password',
                      hint: 'Re-enter your password',
                      icon: Icons.lock_outline,
                      obscureText: _obscureConfirmPassword,
                      textInputAction: TextInputAction.next,
                      validator: _validateConfirmPassword,
                      suffixIcon: IconButton(
                        tooltip: _obscureConfirmPassword
                            ? 'Show password'
                            : 'Hide password',
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword =
                            !_obscureConfirmPassword;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    LoginTextField(
                      controller: _headlineController,
                      label: 'Headline',
                      hint: 'e.g. Senior Flutter Instructor',
                      icon: Icons.title_outlined,
                      textInputAction: TextInputAction.next,
                      validator: (value) =>
                          _validateRequired(value, 'Headline'),
                    ),
                    const SizedBox(height: 16),

                    LoginTextField(
                      controller: _qualificationController,
                      label: 'Qualification',
                      hint: 'e.g. BSc in Computer Science',
                      icon: Icons.school_outlined,
                      textInputAction: TextInputAction.next,
                      validator: (value) =>
                          _validateRequired(value, 'Qualification'),
                    ),
                    const SizedBox(height: 16),

                    LoginTextField(
                      controller: _experienceYearsController,
                      label: 'Experience Years',
                      hint: 'e.g. 5',
                      icon: Icons.work_history_outlined,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      validator: _validateExperienceYears,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _expertiseController,
                      maxLines: 3,
                      textInputAction: TextInputAction.newline,
                      decoration: const InputDecoration(
                        labelText: 'Areas of Expertise',
                        hintText:
                        'Flutter, Dart, Mobile Development',
                        prefixIcon: Icon(Icons.workspace_premium_outlined),
                        alignLabelWithHint: true,
                      ),
                      validator: (value) =>
                          _validateRequired(
                            value,
                            'Areas of expertise',
                          ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      'Separate multiple expertise areas with commas.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),

                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _biographyController,
                      maxLines: 5,
                      textInputAction: TextInputAction.newline,
                      decoration: const InputDecoration(
                        labelText: 'Biography',
                        hintText:
                        'Tell students about your background and experience.',
                        prefixIcon: Icon(Icons.description_outlined),
                        alignLabelWithHint: true,
                      ),
                      validator: (value) =>
                          _validateRequired(value, 'Biography'),
                    ),

                    const SizedBox(height: 28),

                    PrimaryButton(
                      label: _isLoading
                          ? 'Creating Account...'
                          : 'Create Account',
                      icon: Icons.person_add_alt_1,
                      onPressed:
                      _isLoading ? null : _handleRegistration,
                    ),

                    const SizedBox(height: 16),

                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.pop(context),
                      child: const Text(
                        'Already have an account? Sign in',
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