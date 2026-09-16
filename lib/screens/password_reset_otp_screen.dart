import 'package:flutter/material.dart';

import '../core/auth/auth_service.dart';
import '../core/errors/api_exception.dart';
import '../widgets/login_header.dart';
import '../widgets/login_text_field.dart';
import '../widgets/primary_button.dart';

class PasswordResetOtpScreen extends StatefulWidget {
  const PasswordResetOtpScreen({
    super.key,
    required this.email,
  });

  final String email;

  @override
  State<PasswordResetOtpScreen> createState() =>
      _PasswordResetOtpScreenState();
}

class _PasswordResetOtpScreenState extends State<PasswordResetOtpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();

  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool _isResending = false;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  String? _validateOtp(String? value) {
    final otp = value?.trim() ?? '';

    if (otp.isEmpty) {
      return 'Please enter the OTP';
    }

    if (!RegExp(r'^\d{6}$').hasMatch(otp)) {
      return 'OTP must be exactly 6 digits';
    }

    return null;
  }

  Future<void> _handleVerifyOtp() async {
    FocusScope.of(context).unfocus();

    final isValid = _formKey.currentState?.validate() ?? false;

    if (!isValid || _isLoading) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final resetToken = await _authService.verifyPasswordResetOtp(
        email: widget.email,
        otp: _otpController.text.trim(),
      );

      if (!mounted) {
        return;
      }

      Navigator.pushNamed(
        context,
        '/reset-password',
        arguments: {
          'resetToken': resetToken,
          'email': widget.email,
        },
      );
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
        'Unable to verify OTP. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleResendOtp() async {
    if (_isLoading || _isResending) {
      return;
    }

    setState(() {
      _isResending = true;
    });

    try {
      final message = await _authService.forgotPassword(
        email: widget.email,
      );

      if (!mounted) {
        return;
      }

      _showMessage(message);
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
        'Unable to resend OTP. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isResending = false;
        });
      }
    }
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
        title: const Text('Verify OTP'),
      ),
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

                    const SizedBox(height: 32),

                    Text(
                      'Verify Reset Code',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Text(
                      'Enter the 6-digit OTP sent to',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      widget.email,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 32),

                    LoginTextField(
                      controller: _otpController,
                      label: 'OTP',
                      hint: 'Enter 6-digit OTP',
                      icon: Icons.pin_outlined,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      validator: _validateOtp,
                      onFieldSubmitted: (_) {
                        _handleVerifyOtp();
                      },
                    ),

                    const SizedBox(height: 24),

                    PrimaryButton(
                      label: _isLoading
                          ? 'Verifying...'
                          : 'Verify OTP',
                      icon: Icons.verified_outlined,
                      onPressed: _isLoading
                          ? null
                          : _handleVerifyOtp,
                    ),

                    const SizedBox(height: 12),

                    OutlinedButton.icon(
                      onPressed: _isLoading || _isResending
                          ? null
                          : _handleResendOtp,
                      icon: const Icon(Icons.refresh),
                      label: Text(
                        _isResending
                            ? 'Resending...'
                            : 'Resend OTP',
                      ),
                    ),

                    const SizedBox(height: 12),

                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                        Navigator.pop(context);
                      },
                      child: const Text('Back'),
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