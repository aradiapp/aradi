import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:aradi/app/theme/app_theme.dart';
import 'package:aradi/core/models/seller_profile.dart';
import 'package:aradi/app/providers/data_providers.dart';
import 'package:aradi/core/services/photo_upload_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class SellerProfileEditPage extends ConsumerStatefulWidget {
  const SellerProfileEditPage({super.key});

  @override
  ConsumerState<SellerProfileEditPage> createState() => _SellerProfileEditPageState();
}

class _SellerProfileEditPageState extends ConsumerState<SellerProfileEditPage> {
  final _formKey = GlobalKey<FormBuilderState>();
  bool _isLoading = false;
  
  // Image upload variables
  File? _passportImage;
  File? _tradeLicenseImage;
  String? _passportImageUrl;
  String? _tradeLicenseImageUrl;
  final ImagePicker _imagePicker = ImagePicker();

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
    // Initialize image URLs
    _passportImageUrl = profile.passportOrEmiratesId;
    _tradeLicenseImageUrl = profile.companyTradeLicense;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: FormBuilder(
        key: _formKey,
        initialValue: {
          'name': profile.name,
          'phone': profile.phone,
          'email': profile.email,
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
            _buildImageUploadField(
              label: 'Passport/Emirates ID',
              currentImageUrl: _passportImageUrl,
              selectedImage: _passportImage,
              onImageSelected: (File? image) {
                setState(() {
                  _passportImage = image;
                });
              },
              isRequired: true,
            ),
            const SizedBox(height: 24),
            _buildSectionHeader('Company Information (Optional)'),
            const SizedBox(height: 16),
            _buildImageUploadField(
              label: 'Trade License (Optional)',
              currentImageUrl: _tradeLicenseImageUrl,
              selectedImage: _tradeLicenseImage,
              onImageSelected: (File? image) {
                setState(() {
                  _tradeLicenseImage = image;
                });
              },
              isRequired: false,
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

        // Upload images if selected
        String? passportUrl = _passportImageUrl;
        String? tradeLicenseUrl = _tradeLicenseImageUrl;
        
        if (_passportImage != null) {
          final photoUploadService = PhotoUploadService();
          passportUrl = await photoUploadService.uploadDocument(
            _passportImage!,
            'seller_documents/${currentUser.id}',
            'passport_${DateTime.now().millisecondsSinceEpoch}',
          );
        }
        
        if (_tradeLicenseImage != null) {
          final photoUploadService = PhotoUploadService();
          tradeLicenseUrl = await photoUploadService.uploadDocument(
            _tradeLicenseImage!,
            'seller_documents/${currentUser.id}',
            'trade_license_${DateTime.now().millisecondsSinceEpoch}',
          );
        }

        // Update profile
        final updatedProfile = currentProfile.copyWith(
          name: formData['name'],
          phone: formData['phone'],
          email: formData['email'],
          passportOrEmiratesId: passportUrl ?? '',
          companyTradeLicense: tradeLicenseUrl,
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

  Widget _buildImageUploadField({
    required String label,
    String? currentImageUrl,
    File? selectedImage,
    required Function(File?) onImageSelected,
    required bool isRequired,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          height: 200,
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.borderColor),
            borderRadius: BorderRadius.circular(8),
          ),
          child: selectedImage != null
              ? Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        selectedImage,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => onImageSelected(null),
                        ),
                      ),
                    ),
                  ],
                )
              : currentImageUrl != null && currentImageUrl.isNotEmpty
                  ? Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            currentImageUrl,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              color: AppTheme.backgroundLight,
                              child: const Icon(Icons.broken_image, size: 50),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.close, color: Colors.white),
                              onPressed: () {
                                setState(() {
                                  _passportImageUrl = null;
                                  _tradeLicenseImageUrl = null;
                                });
                              },
                            ),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.cloud_upload,
                          size: 50,
                          color: AppTheme.textSecondary,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap to upload image',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _pickImage(onImageSelected),
                icon: const Icon(Icons.camera_alt),
                label: const Text('Upload Image'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            if (isRequired) ...[
              const SizedBox(width: 8),
              Text(
                '* Required',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.errorColor,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Future<void> _pickImage(Function(File?) onImageSelected) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (image != null) {
        onImageSelected(File(image.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }
}
