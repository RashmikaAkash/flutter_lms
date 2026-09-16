import 'package:flutter/material.dart';

import '../core/errors/api_exception.dart';
import '../core/models/profile/user_profile.dart';
import '../core/models/profile/profile_service.dart';
import '../widgets/login_text_field.dart';
import '../widgets/primary_button.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({
    super.key,
    required this.profile,
  });

  final UserProfile profile;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _bioController;

  final ProfileService _profileService = ProfileService();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    _firstNameController = TextEditingController(
      text: widget.profile.firstName,
    );

    _lastNameController = TextEditingController(
      text: widget.profile.lastName,
    );

    _bioController = TextEditingController(
      text: widget.profile.bio ?? '',
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  String? _validateFirstName(String? value) {
    final firstName = value?.trim() ?? '';

    if (firstName.isEmpty) {
      return 'Please enter your first name';
    }

    return null;
  }

  String? _validateLastName(String? value) {
    final lastName = value?.trim() ?? '';

    if (lastName.isEmpty) {
      return 'Please enter your last name';
    }

    return null;
  }

  String? _validateBio(String? value) {
    final bio = value?.trim() ?? '';

    if (bio.length > 500) {
      return 'Bio must be 500 characters or less';
    }

    return null;
  }

  Future<void> _handleSave() async {
    FocusScope.of(context).unfocus();

    final isValid = _formKey.currentState?.validate() ?? false;

    if (!isValid || _isLoading) {
      return;
    }

    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final bio = _bioController.text.trim();

    setState(() {
      _isLoading = true;
    });

    try {
      final updatedProfile = await _profileService.updateUserProfile(
        firstName: firstName,
        lastName: lastName,
        bio: bio,
      );

      if (!mounted) {
        return;
      }

      Navigator.pop(
        context,
        updatedProfile,
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
        'Unable to update profile. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
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
        title: const Text('Edit Profile'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
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
                      'Update your profile information',
                      style: theme.textTheme.titleMedium,
                    ),

                    const SizedBox(height: 24),

                    LoginTextField(
                      controller: _firstNameController,
                      label: 'First Name',
                      hint: 'Enter your first name',
                      icon: Icons.person_outline,
                      textInputAction: TextInputAction.next,
                      validator: _validateFirstName,
                    ),

                    const SizedBox(height: 18),

                    LoginTextField(
                      controller: _lastNameController,
                      label: 'Last Name',
                      hint: 'Enter your last name',
                      icon: Icons.person_outline,
                      textInputAction: TextInputAction.next,
                      validator: _validateLastName,
                    ),

                    const SizedBox(height: 18),

                    TextFormField(
                      controller: _bioController,
                      keyboardType: TextInputType.multiline,
                      textInputAction: TextInputAction.newline,
                      maxLines: 5,
                      validator: _validateBio,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      decoration: const InputDecoration(
                        labelText: 'Bio',
                        hintText: 'Tell us about yourself',
                        prefixIcon: Icon(Icons.info_outline),
                        alignLabelWithHint: true,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      'Maximum 500 characters',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),

                    const SizedBox(height: 24),

                    PrimaryButton(
                      label: _isLoading
                          ? 'Saving...'
                          : 'Save Changes',
                      icon: Icons.save_outlined,
                      onPressed: _isLoading
                          ? null
                          : _handleSave,
                    ),

                    const SizedBox(height: 12),

                    OutlinedButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                        Navigator.pop(context);
                      },
                      child: const Text('Cancel'),
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