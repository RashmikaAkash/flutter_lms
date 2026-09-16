import 'dart:async';

import 'package:flutter/material.dart';

import '../core/auth/auth_service.dart';
import '../core/errors/api_exception.dart';
import '../widgets/login_text_field.dart';
import '../widgets/primary_button.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({
    super.key,
    required this.email,
  });

  final String email;

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState
    extends State<EmailVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();

  final AuthService _authService = AuthService();

  bool _isVerifying = false;
  bool _isResending = false;

  Timer? _resendTimer;
  int _remainingSeconds = 60;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  void _startResendTimer() {
    _resendTimer?.cancel();

    setState(() {
      _remainingSeconds = 60;
    });

    _resendTimer = Timer.periodic(
      const Duration(seconds: 1),
          (timer) {
        if (_remainingSeconds <= 1) {
          timer.cancel();

          if (mounted) {
            setState(() {
              _remainingSeconds = 0;
            });
          }

          return;
        }

        if (mounted) {
          setState(() {
            _remainingSeconds--;
          });
        }
      },
    );
  }

  String? _validateOtp(String? value) {
    final otp = value?.trim() ?? '';

    if (otp.isEmpty) {
      return 'Please enter the verification OTP';
    }

    if (otp.length != 6) {
      return 'OTP must be 6 digits';
    }

    if (int.tryParse(otp) == null) {
      return 'OTP must contain numbers only';
    }

    return null;
  }

  Future<void> _handleVerify() async {
    FocusScope.of(context).unfocus();

    if (_isVerifying || _isResending) {
      return;
    }

    final isValid = _formKey.currentState?.validate() ?? false;

    if (!isValid) {
      return;
    }

    setState(() {
      _isVerifying = true;
    });

    try {
      final message = await _authService.verifyEmail(
        email: widget.email,
        otp: _otpController.text.trim(),
      );

      if (!mounted) {
        return;
      }

      await _showVerificationSuccess(message);
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
        'Email verification failed. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isVerifying = false;
        });
      }
    }
  }

  Future<void> _handleResendOtp() async {
    if (_remainingSeconds > 0 ||
        _isResending ||
        _isVerifying) {
      return;
    }

    setState(() {
      _isResending = true;
    });

    try {
      final message = await _authService.resendVerificationOtp(
        email: widget.email,
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        message.isNotEmpty
            ? message
            : 'A new verification OTP has been sent to your email.',
      );

      _startResendTimer();
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

  Future<void> _showVerificationSuccess(String message) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Email Verified'),
          content: Text(
            message.isNotEmpty
                ? message
                : 'Your email has been verified successfully.',
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                      (route) => false,
                );
              },
              child: const Text('Go to Login'),
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

  String _formatTimer() {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;

    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Email'),
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
                    Icon(
                      Icons.mark_email_read_outlined,
                      size: 72,
                      color: colorScheme.primary,
                    ),

                    const SizedBox(height: 24),

                    Text(
                      'Verify Your Email',
                      style: theme.textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 12),

                    Text(
                      'We sent a verification OTP to',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 6),

                    Text(
                      widget.email,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colorScheme.primary,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 32),

                    LoginTextField(
                      controller: _otpController,
                      label: 'Verification OTP',
                      hint: 'Enter 6-digit OTP',
                      icon: Icons.password_outlined,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      validator: _validateOtp,
                      onFieldSubmitted: (_) => _handleVerify(),
                    ),

                    const SizedBox(height: 24),

                    PrimaryButton(
                      label: _isVerifying
                          ? 'Verifying...'
                          : 'Verify Email',
                      icon: Icons.verified_outlined,
                      onPressed:
                      _isVerifying ? null : _handleVerify,
                    ),

                    const SizedBox(height: 20),

                    Text(
                      _remainingSeconds > 0
                          ? 'Resend OTP available in ${_formatTimer()}'
                          : 'Didn’t receive the OTP?',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),

                    const SizedBox(height: 8),

                    TextButton(
                      onPressed: (_remainingSeconds > 0 ||
                          _isResending ||
                          _isVerifying)
                          ? null
                          : _handleResendOtp,
                      child: Text(
                        _isResending
                            ? 'Sending...'
                            : 'Resend OTP',
                      ),
                    ),

                    const SizedBox(height: 16),

                    TextButton(
                      onPressed: (_isVerifying || _isResending)
                          ? null
                          : () => Navigator.pop(context),
                      child: const Text(
                        'Back to Registration',
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