import 'package:flutter/material.dart';
import '../core/errors/api_exception.dart';
import '../core/models/profile/full_user_profile.dart';
import '../core/models/profile/profile_service.dart';
import 'edit_profile_screen.dart';
import 'package:image_picker/image_picker.dart';
import '../core/models/profile/instructor_profile.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileService _profileService = ProfileService();

  final ImagePicker _imagePicker = ImagePicker();
  bool _isImageLoading = false;

  FullUserProfile? _profile;
  InstructorProfile? _instructorProfile;

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _handlePickProfileImage() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      setState(() {
        _isImageLoading = true;
      });

      await _profileService.uploadProfileImage(
        filePath: pickedFile.path,
      );

      await _loadProfile();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile image updated successfully'),
          ),
        );
      }
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

      final message = error.isForbidden
          ? 'You do not have permission to update your profile image.'
          : error.message;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Failed to update profile image. Please try again.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isImageLoading = false;
        });
      }
    }
  }

  void _showProfileImageOptions() {
    final hasImage = _profile?.user.profileImageUrl != null &&
        _profile!.user.profileImageUrl!.isNotEmpty;

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Change profile photo'),
                onTap: () {
                  Navigator.pop(context);
                  _handlePickProfileImage();
                },
              ),
              if (hasImage)
                ListTile(
                  leading: const Icon(Icons.delete_outline),
                  title: const Text('Remove profile photo'),
                  onTap: () {
                    Navigator.pop(context);
                    _handleDeleteProfileImage();
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleDeleteProfileImage() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Remove Profile Photo'),
          content: const Text(
            'Are you sure you want to remove your profile photo?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      setState(() {
        _isImageLoading = true;
      });

      await _profileService.deleteProfileImage();

      await _loadProfile();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile image removed successfully'),
          ),
        );
      }
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

      final message = error.isForbidden
          ? 'You do not have permission to remove your profile image.'
          : error.message;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Failed to remove profile image. Please try again.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isImageLoading = false;
        });
      }
    }
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final profile = await _profileService.getFullProfile();

      InstructorProfile? instructorProfile;

      if (profile.user.role.toUpperCase() == 'INSTRUCTOR') {
        instructorProfile = await _profileService.getInstructorProfile();
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _profile = profile;
        _instructorProfile = instructorProfile;
        _isLoading = false;
      });
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

      setState(() {
        _errorMessage = error.isForbidden
            ? 'You do not have permission to view this profile.'
            : error.message;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = 'Unable to load profile. Please try again.';
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

  String _formatDateTime(DateTime? date) {
    if (date == null) {
      return 'Not available';
    }

    final localDate = date.toLocal();

    return '${localDate.day.toString().padLeft(2, '0')}/'
        '${localDate.month.toString().padLeft(2, '0')}/'
        '${localDate.year} '
        '${localDate.hour.toString().padLeft(2, '0')}:'
        '${localDate.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: CircularProgressIndicator(),
      ),
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
              _errorMessage ?? 'Unable to load profile.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _loadProfile,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileAvatar() {
    final user = _profile!.user;
    final imageUrl = user.profileImageUrl;

    return GestureDetector(
      onTap: _showProfileImageOptions,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (imageUrl != null && imageUrl.isNotEmpty)
            CircleAvatar(
              radius: 48,
              backgroundImage: NetworkImage(imageUrl),
            )
          else
            Builder(
              builder: (context) {
                final initials = user.firstName.isNotEmpty
                    ? user.firstName[0].toUpperCase()
                    : '?';

                return CircleAvatar(
                  radius: 48,
                  child: Text(
                    initials,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                );
              },
            ),
          if (_isImageLoading)
            const CircleAvatar(
              radius: 48,
              backgroundColor: Colors.black45,
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                ),
              ),
            ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).colorScheme.primary,
                border: Border.all(
                  color: Theme.of(context).colorScheme.surface,
                  width: 2,
                ),
              ),
              child: IconButton(
                onPressed: _isImageLoading ? null : _showProfileImageOptions,
                icon: const Icon(
                  Icons.camera_alt_outlined,
                  size: 18,
                ),
                color: Theme.of(context).colorScheme.onPrimary,
                tooltip: 'Change profile photo',
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 14),
            ...children,
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 22,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                const SizedBox(height: 3),
                Text(
                  value.isEmpty ? 'Not available' : value,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileContent() {
    final user = _profile!.user;
    final student = _profile!.profile;
    final isInstructor = user.role.toUpperCase() == 'INSTRUCTOR';

    return RefreshIndicator(
      onRefresh: _loadProfile,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Column(
              children: [
                _buildProfileAvatar(),
                const SizedBox(height: 14),
                Text(
                  user.fullName,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () async {
                    final result = await Navigator.push<EditProfileResult>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditProfileScreen(
                          profile: user,
                          studentProfile: user.role.toUpperCase() == 'STUDENT'
                              ? _profile!.profile
                              : null,
                          instructorProfile:
                              isInstructor ? _instructorProfile : null,
                        ),
                      ),
                    );

                    if (result == null || !mounted) {
                      return;
                    }

                    await _loadProfile();
                  },
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit Profile'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildInfoCard(
            title: 'Account Information',
            children: [
              _buildInfoRow(
                icon: Icons.person_outline,
                label: 'First Name',
                value: user.firstName,
              ),
              _buildInfoRow(
                icon: Icons.person_outline,
                label: 'Last Name',
                value: user.lastName,
              ),
              _buildInfoRow(
                icon: Icons.email_outlined,
                label: 'Email',
                value: user.email,
              ),
              _buildInfoRow(
                icon: Icons.badge_outlined,
                label: 'Role',
                value: user.role,
              ),
              _buildInfoRow(
                icon: Icons.verified_outlined,
                label: 'Email Verified',
                value: user.emailVerified ? 'Yes' : 'No',
              ),
              _buildInfoRow(
                icon: Icons.toggle_on_outlined,
                label: 'Account Status',
                value: user.status,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoCard(
            title: 'About',
            children: [
              _buildInfoRow(
                icon: Icons.info_outline,
                label: 'Bio',
                value: user.bio?.trim().isNotEmpty == true
                    ? user.bio!
                    : 'No bio added',
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (isInstructor && _instructorProfile != null)
            _buildInfoCard(
              title: 'Instructor Information',
              children: [
                _buildInfoRow(
                  icon: Icons.title_outlined,
                  label: 'Headline',
                  value: _instructorProfile!.headline,
                ),
                _buildInfoRow(
                  icon: Icons.school_outlined,
                  label: 'Qualification',
                  value: _instructorProfile!.qualification,
                ),
                _buildInfoRow(
                  icon: Icons.work_history_outlined,
                  label: 'Experience Years',
                  value: _instructorProfile!.experienceYears.toString(),
                ),
                _buildInfoRow(
                  icon: Icons.code_outlined,
                  label: 'Expertise',
                  value: _instructorProfile!.expertise.isEmpty
                      ? 'No expertise added'
                      : _instructorProfile!.expertise.join(', '),
                ),
                _buildInfoRow(
                  icon: Icons.description_outlined,
                  label: 'Biography',
                  value: _instructorProfile!.biography,
                ),
              ],
            ),
          if (isInstructor && _instructorProfile != null)
            const SizedBox(height: 16),
          if (student != null)
            _buildInfoCard(
              title: 'Student Information',
              children: [
                _buildInfoRow(
                  icon: Icons.cake_outlined,
                  label: 'Date of Birth',
                  value: _formatDate(student.dateOfBirth),
                ),
                _buildInfoRow(
                  icon: Icons.school_outlined,
                  label: 'Education Level',
                  value: student.educationLevel,
                ),
                _buildInfoRow(
                  icon: Icons.flag_outlined,
                  label: 'Learning Goals',
                  value: student.learningGoals.isEmpty
                      ? 'No learning goals added'
                      : student.learningGoals.join(', '),
                ),
              ],
            ),
          if (student != null) const SizedBox(height: 16),
          _buildInfoCard(
            title: 'Account Activity',
            children: [
              _buildInfoRow(
                icon: Icons.login_outlined,
                label: 'Last Login',
                value: _formatDateTime(user.lastLoginAt),
              ),
              _buildInfoRow(
                icon: Icons.calendar_today_outlined,
                label: 'Account Created',
                value: _formatDateTime(user.createdAt),
              ),
              _buildInfoRow(
                icon: Icons.update_outlined,
                label: 'Last Updated',
                value: _formatDateTime(user.updatedAt),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _errorMessage != null
              ? _buildErrorState()
              : _profile == null
                  ? const Center(
                      child: Text('Profile data is unavailable.'),
                    )
                  : _buildProfileContent(),
    );
  }
}
