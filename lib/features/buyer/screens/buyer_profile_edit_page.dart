import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:aradi/app/theme/app_theme.dart';
import 'package:aradi/core/models/buyer_profile.dart';
import 'package:aradi/app/providers/data_providers.dart';

class BuyerProfileEditPage extends ConsumerStatefulWidget {
  const BuyerProfileEditPage({super.key});

  @override
  ConsumerState<BuyerProfileEditPage> createState() => _BuyerProfileEditPageState();
}

class _BuyerProfileEditPageState extends ConsumerState<BuyerProfileEditPage> {
  final _formKey = GlobalKey<FormBuilderState>();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final currentUserAsync = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Buyer Profile'),
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
          final buyerProfileAsync = ref.watch(buyerProfileProvider(user.id));
          return buyerProfileAsync.when(
            data: (profile) {
              if (profile == null) {
                return const Center(
                  child: Text('No buyer profile found. Please complete your KYC first.'),
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

  Widget _buildEditForm(BuyerProfile profile) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: FormBuilder(
        key: _formKey,
        initialValue: {
          'name': profile.name,
          'email': profile.email,
          'phone': profile.phone,
          'areasInterested': profile.areasInterested.join(', '),
          'minGfa': profile.gfaRange?['min']?.toString() ?? '',
          'maxGfa': profile.gfaRange?['max']?.toString() ?? '',
          'minBudget': profile.budgetRange?['min']?.toString() ?? '',
          'maxBudget': profile.budgetRange?['max']?.toString() ?? '',
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
            const SizedBox(height: 24),
            _buildSectionHeader('Preferences'),
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
            _buildSectionHeader('GFA Range (sqft)'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FormBuilderTextField(
                    name: 'minGfa',
                    decoration: const InputDecoration(
                      labelText: 'Minimum GFA',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FormBuilderTextField(
                    name: 'maxGfa',
                    decoration: const InputDecoration(
                      labelText: 'Maximum GFA',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSectionHeader('Budget Range (USD)'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FormBuilderTextField(
                    name: 'minBudget',
                    decoration: const InputDecoration(
                      labelText: 'Minimum Budget',
                      border: OutlineInputBorder(),
                      prefixText: '\$',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FormBuilderTextField(
                    name: 'maxBudget',
                    decoration: const InputDecoration(
                      labelText: 'Maximum Budget',
                      border: OutlineInputBorder(),
                      prefixText: '\$',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSubscriptionCard(profile),
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

  Widget _buildSubscriptionCard(BuyerProfile profile) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Subscription Status',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  profile.hasActiveSubscription ? Icons.check_circle : Icons.cancel,
                  color: profile.hasActiveSubscription ? AppTheme.successColor : AppTheme.errorColor,
                ),
                const SizedBox(width: 8),
                Text(
                  profile.hasActiveSubscription ? 'Active Subscription' : 'No Active Subscription',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: profile.hasActiveSubscription ? AppTheme.successColor : AppTheme.errorColor,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
            if (profile.hasActiveSubscription) ...[
              const SizedBox(height: 8),
              Text(
                'Subscription Active',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
              ),
              if (profile.subscriptionExpiry != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Expires: ${profile.subscriptionExpiry!.toLocal().toString().split(' ')[0]}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                ),
              ],
            ],
          ],
        ),
      ),
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
        // Ensure we have a BuyerProfile
        if (currentProfile is! BuyerProfile) {
          throw Exception('Profile type mismatch. Expected BuyerProfile, got ${currentProfile.runtimeType}. User role: ${currentUser.role}');
        }

        // Prepare GFA and budget ranges
        Map<String, double>? gfaRange;
        if (formData['minGfa'] != null && formData['minGfa'].toString().isNotEmpty &&
            formData['maxGfa'] != null && formData['maxGfa'].toString().isNotEmpty) {
          gfaRange = {
            'min': double.tryParse(formData['minGfa'].toString()) ?? 0.0,
            'max': double.tryParse(formData['maxGfa'].toString()) ?? 0.0,
          };
        }

        Map<String, double>? budgetRange;
        if (formData['minBudget'] != null && formData['minBudget'].toString().isNotEmpty &&
            formData['maxBudget'] != null && formData['maxBudget'].toString().isNotEmpty) {
          budgetRange = {
            'min': double.tryParse(formData['minBudget'].toString()) ?? 0.0,
            'max': double.tryParse(formData['maxBudget'].toString()) ?? 0.0,
          };
        }

        // Update profile
        final updatedProfile = currentProfile.copyWith(
          name: formData['name'],
          email: formData['email'],
          phone: formData['phone'],
          areasInterested: (formData['areasInterested'] as String)
              .split(',')
              .map((e) => e.trim())
              .toList(),
          gfaRange: gfaRange,
          budgetRange: budgetRange,
          updatedAt: DateTime.now(),
        );

        await authService.updateBuyerProfile(updatedProfile);

        // Invalidate the provider to refresh the profile data
        ref.invalidate(buyerProfileProvider(currentUser.id));
        
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
