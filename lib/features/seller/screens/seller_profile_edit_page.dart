import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:aradi/app/theme/app_theme.dart';
import 'package:aradi/core/models/seller_profile.dart';
import 'package:aradi/app/providers/data_providers.dart';

class SellerProfileEditPage extends ConsumerStatefulWidget {
  const SellerProfileEditPage({super.key});

  @override
  ConsumerState<SellerProfileEditPage> createState() => _SellerProfileEditPageState();
}

class _SellerProfileEditPageState extends ConsumerState<SellerProfileEditPage> {
  final _formKey = GlobalKey<FormBuilderState>();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final currentUserAsync = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Seller Profile'),
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
          final sellerProfileAsync = ref.watch(sellerProfileProvider(user.id));
          return sellerProfileAsync.when(
            data: (profile) {
              if (profile == null) {
                return const Center(
                  child: Text('No seller profile found. Please complete your KYC first.'),
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

  Widget _buildEditForm(SellerProfile profile) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: FormBuilder(
        key: _formKey,
        initialValue: {
          'name': profile.name,
          'phone': profile.phone,
          'email': profile.email,
          'passportOrEmiratesId': profile.passportOrEmiratesId,
          'companyTradeLicense': profile.companyTradeLicense ?? '',
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Personal Information'),
            const SizedBox(height: 16),
            FormBuilderTextField(
              name: 'name',
              decoration: const InputDecoration(
                labelText: 'Full Name',
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
              name: 'phone',
              decoration: const InputDecoration(
                labelText: 'Phone Number',
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
              name: 'email',
              decoration: const InputDecoration(
                labelText: 'Email',
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
            const SizedBox(height: 24),
            _buildSectionHeader('Identity Documents'),
            const SizedBox(height: 16),
            FormBuilderTextField(
              name: 'passportOrEmiratesId',
              decoration: const InputDecoration(
                labelText: 'Passport/Emirates ID Number',
                border: OutlineInputBorder(),
                helperText: 'Enter your passport or Emirates ID number',
              ),
              validator: (value) {
                if (value == null || value.toString().isEmpty) {
                  return 'This field is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            _buildSectionHeader('Company Information (Optional)'),
            const SizedBox(height: 16),
            FormBuilderTextField(
              name: 'companyTradeLicense',
              decoration: const InputDecoration(
                labelText: 'Company Trade License',
                border: OutlineInputBorder(),
                helperText: 'Enter your company trade license if applicable',
              ),
            ),
            const SizedBox(height: 24),
            _buildListingStatsCard(profile),
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

  Widget _buildListingStatsCard(SellerProfile profile) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Listing Statistics',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem('Total Listings', profile.totalListings.toString()),
                ),
                Expanded(
                  child: _buildStatItem('Active Listings', profile.activeListings.toString()),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem('Completed Deals', profile.completedDeals.toString()),
                ),
                Expanded(
                  child: _buildStatItem('Success Rate', 
                    profile.totalListings > 0 
                      ? '${((profile.completedDeals / profile.totalListings) * 100).toStringAsFixed(1)}%'
                      : '0%'
                  ),
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
        // Ensure we have a SellerProfile
        if (currentProfile is! SellerProfile) {
          throw Exception('Profile type mismatch. Expected SellerProfile, got ${currentProfile.runtimeType}. User role: ${currentUser.role}');
        }

        // Update profile
        final updatedProfile = currentProfile.copyWith(
          name: formData['name'],
          phone: formData['phone'],
          email: formData['email'],
          passportOrEmiratesId: formData['passportOrEmiratesId'],
          companyTradeLicense: formData['companyTradeLicense']?.toString().isNotEmpty == true 
              ? formData['companyTradeLicense'].toString() 
              : null,
          updatedAt: DateTime.now(),
        );

        await authService.updateSellerProfile(updatedProfile);

        // Invalidate the provider to refresh the profile data
        ref.invalidate(sellerProfileProvider(currentUser.id));
        
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
