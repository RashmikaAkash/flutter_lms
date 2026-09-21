import 'package:flutter/material.dart';

import '../core/errors/api_exception.dart';
import '../core/models/profile/instructor_profile.dart';
import '../core/models/profile/student_profile.dart';
import '../core/models/profile/user_profile.dart';
import '../core/models/profile/profile_service.dart';
import '../widgets/login_text_field.dart';
import '../widgets/primary_button.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({
    super.key,
    required this.profile,
    this.studentProfile,
    this.instructorProfile,
  });

  final UserProfile profile;
  final StudentProfile? studentProfile;
  final InstructorProfile? instructorProfile;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _bioController;

  late final TextEditingController _educationLevelController;
  late final TextEditingController _learningGoalsController;

  late final TextEditingController _headlineController;
  late final TextEditingController _qualificationController;
  late final TextEditingController _experienceYearsController;
  late final TextEditingController _expertiseController;
  late final TextEditingController _biographyController;

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

    _educationLevelController = TextEditingController(
      text: widget.studentProfile?.educationLevel ?? '',
    );

    _learningGoalsController = TextEditingController(
      text: widget.studentProfile?.learningGoals.join(', ') ?? '',
    );

    _headlineController = TextEditingController(
      text: widget.instructorProfile?.headline ?? '',
    );

    _qualificationController = TextEditingController(
      text: widget.instructorProfile?.qualification ?? '',
    );

    _experienceYearsController = TextEditingController(
      text: widget.instructorProfile?.experienceYears.toString() ?? '',
    );

    _expertiseController = TextEditingController(
      text: widget.instructorProfile?.expertise.join(', ') ?? '',
    );

    _biographyController = TextEditingController(
      text: widget.instructorProfile?.biography ?? '',
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _bioController.dispose();

    _educationLevelController.dispose();
    _learningGoalsController.dispose();

    _headlineController.dispose();
    _qualificationController.dispose();
    _experienceYearsController.dispose();
    _expertiseController.dispose();
    _biographyController.dispose();

    super.dispose();
  }

  String? _validateFirstName(String? value) {
    if ((value?.trim() ?? '').isEmpty) {
      return 'Please enter your first name';
    }

    return null;
  }

  String? _validateLastName(String? value) {
    if ((value?.trim() ?? '').isEmpty) {
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

  String? _validateEducationLevel(String? value) {
    if (widget.studentProfile == null) {
      return null;
    }

    if ((value?.trim() ?? '').isEmpty) {
      return 'Please enter your education level';
    }

    return null;
  }

  String? _validateLearningGoals(String? value) {
    if (widget.studentProfile == null) {
      return null;
    }

    if ((value?.trim() ?? '').isEmpty) {
      return 'Please enter at least one learning goal';
    }

    return null;
  }

  String? _validateExperienceYears(String? value) {
    if (widget.instructorProfile == null) {
      return null;
    }

    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return 'Please enter experience years';
    }

    if (int.tryParse(text) == null) {
      return 'Please enter a valid number';
    }

    return null;
  }

  List<String> _getLearningGoals() {
    return _learningGoalsController.text
        .split(',')
        .map((goal) => goal.trim())
        .where((goal) => goal.isNotEmpty)
        .toList();
  }

  List<String> _getExpertise() {
    return _expertiseController.text
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
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
      // ----------------------------------------------------------
      // UPDATE SHARED USER PROFILE
      // ----------------------------------------------------------

      final updatedUser = await _profileService.updateUserProfile(
        firstName: firstName,
        lastName: lastName,
        bio: bio,
      );

      // ----------------------------------------------------------
      // UPDATE STUDENT PROFILE
      // ----------------------------------------------------------

      StudentProfile? updatedStudentProfile;

      if (widget.studentProfile != null) {
        final learningGoals = _getLearningGoals();

        if (learningGoals.isEmpty) {
          throw const ApiException(
            message: 'Please enter at least one learning goal',
          );
        }

        updatedStudentProfile = await _profileService.updateStudentProfile(
          educationLevel: _educationLevelController.text.trim(),
          learningGoals: learningGoals,
        );
      }

      // ----------------------------------------------------------
      // UPDATE INSTRUCTOR PROFILE
      // ----------------------------------------------------------

      InstructorProfile? updatedInstructorProfile;

      if (widget.instructorProfile != null) {
        final experienceYears = int.tryParse(
          _experienceYearsController.text.trim(),
        );

        if (experienceYears == null) {
          throw const ApiException(
            message: 'Please enter a valid number for experience years',
          );
        }

        updatedInstructorProfile =
            await _profileService.updateInstructorProfile(
          headline: _headlineController.text.trim(),
          qualification: _qualificationController.text.trim(),
          experienceYears: experienceYears,
          expertise: _getExpertise(),
          biography: _biographyController.text.trim(),
        );
      }

      if (!mounted) {
        return;
      }

      Navigator.pop(
        context,
        EditProfileResult(
          userProfile: updatedUser,
          studentProfile: updatedStudentProfile,
          instructorProfile: updatedInstructorProfile,
        ),
      );
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }

      if (error.isUnauthorized) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/login',
          (route) => false,
        );
        return;
      }

      if (error.isForbidden) {
        _showMessage(
          'You do not have permission to update your profile.',
        );
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

    final isStudent = widget.studentProfile != null;
    final isInstructor = widget.instructorProfile != null;

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
                      'Personal Information',
                      style: theme.textTheme.titleLarge,
                    ),

                    const SizedBox(height: 20),

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

                    // ==================================================
                    // STUDENT INFORMATION
                    // ==================================================

                    if (isStudent) ...[
                      const SizedBox(height: 32),
                      Text(
                        'Student Information',
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 20),
                      LoginTextField(
                        controller: _educationLevelController,
                        label: 'Education Level',
                        hint: 'e.g. Undergraduate',
                        icon: Icons.school_outlined,
                        textInputAction: TextInputAction.next,
                        validator: _validateEducationLevel,
                      ),
                      const SizedBox(height: 18),
                      TextFormField(
                        controller: _learningGoalsController,
                        keyboardType: TextInputType.multiline,
                        textInputAction: TextInputAction.newline,
                        maxLines: 5,
                        validator: _validateLearningGoals,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        decoration: const InputDecoration(
                          labelText: 'Learning Goals',
                          hintText: 'Enter goals separated by commas',
                          prefixIcon: Icon(Icons.flag_outlined),
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Example: Learn Flutter, Improve mobile development skills',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],

                    // ==================================================
                    // INSTRUCTOR INFORMATION
                    // ==================================================

                    if (isInstructor) ...[
                      const SizedBox(height: 32),
                      Text(
                        'Instructor Information',
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 20),
                      LoginTextField(
                        controller: _headlineController,
                        label: 'Headline',
                        hint: 'e.g. Senior Mobile Application Instructor',
                        icon: Icons.title_outlined,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 18),
                      LoginTextField(
                        controller: _qualificationController,
                        label: 'Qualification',
                        hint: 'e.g. Bsc.IT',
                        icon: Icons.school_outlined,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 18),
                      TextFormField(
                        controller: _experienceYearsController,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        validator: _validateExperienceYears,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        decoration: const InputDecoration(
                          labelText: 'Experience Years',
                          hintText: 'e.g. 5',
                          prefixIcon: Icon(Icons.work_history_outlined),
                        ),
                      ),
                      const SizedBox(height: 18),
                      TextFormField(
                        controller: _expertiseController,
                        keyboardType: TextInputType.multiline,
                        textInputAction: TextInputAction.newline,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Expertise',
                          hintText: 'Enter expertise separated by commas',
                          prefixIcon: Icon(Icons.code_outlined),
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Example: Flutter, Dart, Firebase, Node.js',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 18),
                      TextFormField(
                        controller: _biographyController,
                        keyboardType: TextInputType.multiline,
                        textInputAction: TextInputAction.newline,
                        maxLines: 6,
                        decoration: const InputDecoration(
                          labelText: 'Biography',
                          hintText:
                              'Tell learners about your experience and expertise',
                          prefixIcon: Icon(Icons.description_outlined),
                          alignLabelWithHint: true,
                        ),
                      ),
                    ],

                    const SizedBox(height: 28),

                    PrimaryButton(
                      label: _isLoading ? 'Saving...' : 'Save Changes',
                      icon: Icons.save_outlined,
                      onPressed: _isLoading ? null : _handleSave,
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

class EditProfileResult {
  const EditProfileResult({
    required this.userProfile,
    this.studentProfile,
    this.instructorProfile,
  });

  final UserProfile userProfile;
  final StudentProfile? studentProfile;
  final InstructorProfile? instructorProfile;
}
