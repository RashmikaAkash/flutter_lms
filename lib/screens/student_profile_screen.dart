import 'package:flutter/material.dart';

import '../core/errors/api_exception.dart';
import '../core/models/profile/student_profile.dart';
import '../core/models/profile/profile_service.dart';
import '../widgets/login_text_field.dart';
import '../widgets/primary_button.dart';

class StudentProfileScreen extends StatefulWidget {
  const StudentProfileScreen({super.key});

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  final ProfileService _profileService = ProfileService();

  StudentProfile? _profile;

  bool _isLoading = true;
  // bool _isSaving = false;

  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadStudentProfile();
  }

  Future<void> _loadStudentProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final profile = await _profileService.getStudentProfile();

      if (!mounted) {
        return;
      }

      setState(() {
        _profile = profile;
        _isLoading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = error.message;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage =
        'Unable to load student profile. Please try again.';
        _isLoading = false;
      });
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) {
      return 'Not available';
    }

    final localDate = date.toLocal();

    return '${localDate.day.toString().padLeft(2, '0')}/'
        '${localDate.month.toString().padLeft(2, '0')}/'
        '${localDate.year}';
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildErrorState() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Unable to load student profile.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _loadStudentProfile,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 22,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  value.isEmpty ? 'Not available' : value,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileContent() {
    final profile = _profile!;

    return RefreshIndicator(
      onRefresh: _loadStudentProfile,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Student Information',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 18),
                  _buildInfoRow(
                    icon: Icons.cake_outlined,
                    label: 'Date of Birth',
                    value: _formatDate(profile.dateOfBirth),
                  ),
                  _buildInfoRow(
                    icon: Icons.school_outlined,
                    label: 'Education Level',
                    value: profile.educationLevel,
                  ),
                  _buildInfoRow(
                    icon: Icons.flag_outlined,
                    label: 'Learning Goals',
                    value: profile.learningGoals.isEmpty
                        ? 'No learning goals added'
                        : profile.learningGoals.join(', '),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          OutlinedButton.icon(
            onPressed: () async {
              final updatedProfile =
              await Navigator.push<StudentProfile>(
                context,
                MaterialPageRoute(
                  builder: (_) => EditStudentProfileScreen(
                    profile: profile,
                  ),
                ),
              );

              if (updatedProfile == null || !mounted) {
                return;
              }

              setState(() {
                _profile = updatedProfile;
              });
            },
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Edit Student Profile'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Profile'),
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _errorMessage != null
          ? _buildErrorState()
          : _profile == null
          ? const Center(
        child: Text(
          'Student profile data is unavailable.',
        ),
      )
          : _buildProfileContent(),
    );
  }
}

class EditStudentProfileScreen extends StatefulWidget {
  const EditStudentProfileScreen({
    super.key,
    required this.profile,
  });

  final StudentProfile profile;

  @override
  State<EditStudentProfileScreen> createState() =>
      _EditStudentProfileScreenState();
}

class _EditStudentProfileScreenState
    extends State<EditStudentProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _educationLevelController;
  late final TextEditingController _learningGoalsController;

  final ProfileService _profileService = ProfileService();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    _educationLevelController = TextEditingController(
      text: widget.profile.educationLevel,
    );

    _learningGoalsController = TextEditingController(
      text: widget.profile.learningGoals.join(', '),
    );
  }

  @override
  void dispose() {
    _educationLevelController.dispose();
    _learningGoalsController.dispose();
    super.dispose();
  }

  String? _validateEducationLevel(String? value) {
    if ((value?.trim() ?? '').isEmpty) {
      return 'Please enter your education level';
    }

    return null;
  }

  String? _validateLearningGoals(String? value) {
    if ((value?.trim() ?? '').isEmpty) {
      return 'Please enter at least one learning goal';
    }

    return null;
  }

  Future<void> _handleSave() async {
    FocusScope.of(context).unfocus();

    final isValid = _formKey.currentState?.validate() ?? false;

    if (!isValid || _isLoading) {
      return;
    }

    final educationLevel =
    _educationLevelController.text.trim();

    final learningGoals = _learningGoalsController.text
        .split(',')
        .map((goal) => goal.trim())
        .where((goal) => goal.isNotEmpty)
        .toList();

    if (learningGoals.isEmpty) {
      _showMessage('Please enter at least one learning goal.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final updatedProfile =
      await _profileService.updateStudentProfile(
        educationLevel: educationLevel,
        learningGoals: learningGoals,
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
        'Unable to update student profile. Please try again.',
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
        title: const Text('Edit Student Profile'),
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
                      'Student Profile',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      'Update your education and learning goals.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),

                    const SizedBox(height: 28),

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
                      autovalidateMode:
                      AutovalidateMode.onUserInteraction,
                      decoration: const InputDecoration(
                        labelText: 'Learning Goals',
                        hintText:
                        'Enter goals separated by commas',
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