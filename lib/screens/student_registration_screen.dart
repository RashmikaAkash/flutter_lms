import 'package:flutter/material.dart';

import '../core/auth/auth_service.dart';
import '../core/errors/api_exception.dart';
import '../widgets/login_text_field.dart';
import '../widgets/primary_button.dart';

class StudentRegistrationScreen extends StatefulWidget {
  const StudentRegistrationScreen({super.key});

  @override
  State<StudentRegistrationScreen> createState() =>
      _StudentRegistrationScreenState();
}

class _StudentRegistrationScreenState extends State<StudentRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _dateOfBirthController = TextEditingController();
  final _educationLevelController = TextEditingController();
  final _learningGoalsController = TextEditingController();

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
    _dateOfBirthController.dispose();
    _educationLevelController.dispose();
    _learningGoalsController.dispose();
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

  String? _validateDateOfBirth(String? value) {
    final date = value?.trim() ?? '';

    if (date.isEmpty) {
      return 'Please select your date of birth';
    }

    return null;
  }

  String? _validateEducationLevel(String? value) {
    final educationLevel = value?.trim() ?? '';

    if (educationLevel.isEmpty) {
      return 'Please enter your education level';
    }

    return null;
  }

  String? _validateLearningGoals(String? value) {
    final learningGoals = value?.trim() ?? '';

    if (learningGoals.isEmpty) {
      return 'Please enter at least one learning goal';
    }

    return null;
  }

  Future<void> _selectDateOfBirth() async {
    final now = DateTime.now();

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime(
        now.year - 18,
        now.month,
        now.day,
      ),
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: 'Select Date of Birth',
    );

    if (pickedDate == null) {
      return;
    }

    final formattedDate = '${pickedDate.year.toString().padLeft(4, '0')}-'
        '${pickedDate.month.toString().padLeft(2, '0')}-'
        '${pickedDate.day.toString().padLeft(2, '0')}';

    _dateOfBirthController.text = formattedDate;
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

    final learningGoals = _learningGoalsController.text
        .split(',')
        .map((goal) => goal.trim())
        .where((goal) => goal.isNotEmpty)
        .toList();

    if (learningGoals.isEmpty) {
      _showMessage(
        'Please enter at least one learning goal.',
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final message = await _authService.registerStudent(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        confirmPassword: _confirmPasswordController.text,
        dateOfBirth: _dateOfBirthController.text.trim(),
        educationLevel: _educationLevelController.text.trim(),
        learningGoals: learningGoals,
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
        'Registration failed. Please try again.',
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
                : 'Student registration successful.\n'
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
        title: const Text('Create Student Account'),
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
                      'Student Registration',
                      style: theme.textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create your account to start learning.',
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
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _dateOfBirthController,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Date of Birth',
                        hintText: 'YYYY-MM-DD',
                        prefixIcon: const Icon(Icons.calendar_today_outlined),
                        suffixIcon: IconButton(
                          tooltip: 'Select date',
                          icon: const Icon(Icons.calendar_month_outlined),
                          onPressed: _selectDateOfBirth,
                        ),
                      ),
                      validator: _validateDateOfBirth,
                      onTap: _selectDateOfBirth,
                    ),
                    const SizedBox(height: 16),
                    LoginTextField(
                      controller: _educationLevelController,
                      label: 'Education Level',
                      hint: 'e.g. Undergraduate',
                      icon: Icons.school_outlined,
                      textInputAction: TextInputAction.next,
                      validator: _validateEducationLevel,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _learningGoalsController,
                      maxLines: 3,
                      textInputAction: TextInputAction.newline,
                      decoration: const InputDecoration(
                        labelText: 'Learning Goals',
                        hintText: 'Flutter, Dart, Mobile Development',
                        prefixIcon: Icon(Icons.flag_outlined),
                        alignLabelWithHint: true,
                      ),
                      validator: _validateLearningGoals,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Separate multiple learning goals with commas.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 28),
                    PrimaryButton(
                      label:
                          _isLoading ? 'Creating Account...' : 'Create Account',
                      icon: Icons.person_add_alt_1,
                      onPressed: _isLoading ? null : _handleRegistration,
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed:
                          _isLoading ? null : () => Navigator.pop(context),
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
