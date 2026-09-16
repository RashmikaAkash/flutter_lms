import 'package:flutter/material.dart';
import '../core/errors/api_exception.dart';
import '../core/models/profile/full_user_profile.dart';
import '../core/models/profile/profile_service.dart';
import '../core/models/profile/user_profile.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileService _profileService = ProfileService();

  FullUserProfile? _profile;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final profile = await _profileService.getFullProfile();

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

    if (imageUrl != null && imageUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 48,
        backgroundImage: NetworkImage(imageUrl),
      );
    }

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
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(
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
                    final updatedProfile = await Navigator.push<UserProfile>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditProfileScreen(
                          profile: user,
                        ),
                      ),
                    );

                    if (updatedProfile == null || !mounted) {
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