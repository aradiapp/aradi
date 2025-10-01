import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:aradi/app/theme/app_theme.dart';
import 'package:aradi/core/models/developer_profile.dart';
import 'package:aradi/app/providers/data_providers.dart';

class DevProfileEditPage extends ConsumerStatefulWidget {
  const DevProfileEditPage({super.key});

  @override
  ConsumerState<DevProfileEditPage> createState() => _DevProfileEditPageState();
}

class _DevProfileEditPageState extends ConsumerState<DevProfileEditPage> {
  final _formKey = GlobalKey<FormBuilderState>();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final currentUserAsync = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Developer Profile'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: Text(
              'Save',
              style: TextStyle(
                color: _isLoading ? Colors.grey : Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: currentUserAsync.when(
        data: (user) {
          if (user == null) {
            return const Center(
              child: Text('User not authenticated. Please sign in.'),
            );
          }
          final developerProfileAsync = ref.watch(developerProfileProvider(user.id));
          return developerProfileAsync.when(
            data: (profile) {
              if (profile == null) {
                return const Center(
                  child: Text('No developer profile found. Please complete your KYC first.'),
                );
              }
              return _buildEditForm(profile);
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(child: Text('Error: $error')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildEditForm(DeveloperProfile profile) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: FormBuilder(
        key: _formKey,
        initialValue: {
          'companyName': profile.companyName,
          'companyEmail': profile.companyEmail,
          'companyPhone': profile.companyPhone,
          'businessModel': profile.businessModel.toString().split('.').last,
          'areasInterested': profile.areasInterested.join(', '),
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Company Information'),
            const SizedBox(height: 16),
            FormBuilderTextField(
              name: 'companyName',
              decoration: const InputDecoration(
                labelText: 'Company Name',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.toString().isEmpty) {
                  return 'This field is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            FormBuilderTextField(
              name: 'companyEmail',
              decoration: const InputDecoration(
                labelText: 'Company Email',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.toString().isEmpty) {
                  return 'This field is required';
                }
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.toString())) {
                  return 'Please enter a valid email address';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            FormBuilderTextField(
              name: 'companyPhone',
              decoration: const InputDecoration(
                labelText: 'Company Phone',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.toString().isEmpty) {
                  return 'This field is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            _buildSectionHeader('Business Details'),
            const SizedBox(height: 16),
            FormBuilderDropdown<String>(
              name: 'businessModel',
              decoration: const InputDecoration(
                labelText: 'Business Model',
                border: OutlineInputBorder(),
              ),
              items: BusinessModel.values
                  .map((model) => DropdownMenuItem(
                        value: model.toString().split('.').last,
                        child: Text(model.toString().split('.').last),
                      ))
                  .toList(),
              validator: (value) {
                if (value == null || value.toString().isEmpty) {
                  return 'This field is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            FormBuilderTextField(
              name: 'areasInterested',
              decoration: const InputDecoration(
                labelText: 'Areas Interested (comma-separated)',
                border: OutlineInputBorder(),
                helperText: 'Enter areas separated by commas',
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.toString().isEmpty) {
                  return 'This field is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            _buildSectionHeader('Statistics'),
            const SizedBox(height: 16),
            _buildStatsCard(profile),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Save Changes', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
    );
  }

  Widget _buildStatsCard(DeveloperProfile profile) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Business Statistics',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem('Delivered', profile.deliveredProjects.toString()),
                ),
                Expanded(
                  child: _buildStatItem('Under Construction', profile.underConstruction.toString()),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem('In Pipeline', profile.landsInPipeline.toString()),
                ),
                Expanded(
                  child: _buildStatItem('Team Size', profile.teamSize.toString()),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary,
              ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
        ),
      ],
    );
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      setState(() {
        _isLoading = true;
      });

      try {
        final formData = _formKey.currentState!.value;
        final authService = ref.read(authServiceProvider);
        final currentUser = await authService.getCurrentUser();
        
        if (currentUser == null) {
          throw Exception('User not authenticated');
        }

        // Get current profile
        print('Getting profile for user: ${currentUser.id}, role: ${currentUser.role}');
        final currentProfile = await authService.getUserProfile(currentUser.id, currentUser.role);
        if (currentProfile == null) {
          throw Exception('Profile not found');
        }

        print('Retrieved profile type: ${currentProfile.runtimeType}');
        // Ensure we have a DeveloperProfile
        if (currentProfile is! DeveloperProfile) {
          throw Exception('Profile type mismatch. Expected DeveloperProfile, got ${currentProfile.runtimeType}. User role: ${currentUser.role}');
        }

        // Update profile
        final updatedProfile = currentProfile.copyWith(
          companyName: formData['companyName'],
          companyEmail: formData['companyEmail'],
          companyPhone: formData['companyPhone'],
          businessModel: BusinessModel.values.firstWhere(
            (e) => e.toString().split('.').last == formData['businessModel'],
            orElse: () => BusinessModel.business,
          ),
          areasInterested: (formData['areasInterested'] as String)
              .split(',')
              .map((e) => e.trim())
              .toList(),
          updatedAt: DateTime.now(),
        );

        await authService.updateDeveloperProfile(updatedProfile);

        // Invalidate the provider to refresh the profile data
        ref.invalidate(developerProfileProvider(currentUser.id));
        
        // Also invalidate auth state to refresh navigation role
        ref.invalidate(authStateProvider);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully!'),
              backgroundColor: AppTheme.successColor,
            ),
          );
          context.pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error updating profile: $e'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }
}
