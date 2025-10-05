import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;
import 'package:aradi/app/theme/app_theme.dart';
import 'package:aradi/core/models/developer_profile.dart';
import 'package:aradi/core/models/user.dart';
import 'package:aradi/core/services/photo_upload_service.dart';
import 'package:aradi/app/providers/data_providers.dart';

class DevProfileEditPage extends ConsumerStatefulWidget {
  const DevProfileEditPage({super.key});

  @override
  ConsumerState<DevProfileEditPage> createState() => _DevProfileEditPageState();
}

class _DevProfileEditPageState extends ConsumerState<DevProfileEditPage> {
  final _formKey = GlobalKey<FormBuilderState>();
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();
  String? _selectedProfilePicture;
  String? _selectedCatalogDocument;
  String? _selectedTradeLicense;
  String? _selectedPassport;
  List<String> _selectedAreas = [];
  BusinessModel? _selectedBusinessModel;

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
              return _buildEditForm(profile, user);
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

  Widget _buildEditForm(DeveloperProfile profile, User user) {
    // Initialize form values
    if (_selectedAreas.isEmpty) {
      _selectedAreas = List.from(profile.areasInterested);
    }
    if (_selectedBusinessModel == null) {
      _selectedBusinessModel = profile.businessModel;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: FormBuilder(
        key: _formKey,
        initialValue: {
          'companyName': profile.companyName,
          'companyEmail': profile.companyEmail,
          'companyPhone': profile.companyPhone,
          'deliveredProjects': profile.deliveredProjects.toString(),
          'underConstruction': profile.underConstruction.toString(),
          'totalValue': profile.totalValue.toString(),
          'teamSize': profile.teamSize.toString(),
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Picture Section
            _buildSectionHeader('Profile Picture'),
            const SizedBox(height: 16),
            _buildProfilePictureSection(user),
            const SizedBox(height: 24),
            
            // Company Information
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
            
            // Business Model Section
            _buildSectionHeader('Business Model'),
            const SizedBox(height: 16),
            _buildBusinessModelSection(),
            const SizedBox(height: 24),
            
            // Areas of Interest Section
            _buildSectionHeader('Areas of Interest'),
            const SizedBox(height: 16),
            _buildAreasOfInterestSection(),
            const SizedBox(height: 24),
            
            // Developer Status Section
            _buildSectionHeader('Developer Status'),
            const SizedBox(height: 16),
            _buildDeveloperStatusSection(),
            const SizedBox(height: 24),
            
            // Documents Section
            _buildSectionHeader('Documents'),
            const SizedBox(height: 16),
            _buildDocumentsSection(profile),
            const SizedBox(height: 32),
            
            // Save Button
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

  Widget _buildProfilePictureSection(User user) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => _pickProfilePicture(),
              child: CircleAvatar(
                radius: 40,
                backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                backgroundImage: _getProfileImageProvider(_selectedProfilePicture, user.profilePictureUrl),
                child: _getProfileImageChild(_selectedProfilePicture, user.profilePictureUrl),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Profile Picture',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap to change profile picture',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessModelSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildBusinessModelButton('Joint Venture', BusinessModel.venture),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildBusinessModelButton('Land Acquisition', BusinessModel.business),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: _buildBusinessModelButton('Both', BusinessModel.both),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessModelButton(String label, BusinessModel model) {
    final isSelected = _selectedBusinessModel == model;
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _selectedBusinessModel = model;
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? AppTheme.primaryColor : Colors.grey[200],
        foregroundColor: isSelected ? Colors.white : Colors.black87,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(label),
    );
  }

  Widget _buildAreasOfInterestSection() {
    const areas = [
      'Abu Hail', 'Al Barsha', 'Al Furjan', 'Al Habtoor City', 'Al Jaddaf', 'Al Quoz', 'Al Safa', 'Al Sufouh',
      'Arabian Ranches', 'Arjan (Dubailand)', 'Barsha Heights', 'Bluewaters Island', 'Business Bay', 'City Walk',
      'Culture Village', 'Deira', 'DIFC (Dubai International Financial City)', 'Dubai Creek Harbour', 'Dubai Hills Estate',
      'Dubai International City', 'Dubai Marina', 'Dubai Media City', 'Dubai Silicon Oasis', 'Downtown Dubai',
      'Emaar Beachfront', 'Emirates Hills', 'JBR (Jumeirah Beach Residence)', 'JLT (Jumeirah Lake Towers)',
      'JVC (Jumeirah Village Circle)', 'JVT (Jumeirah Village Triangle)', 'Madinat Jumeirah Living (MJL)',
      'Meadows', 'Mina Rashid', 'Motor City', 'Mudon', 'Nad Al Sheba', 'Palm Jumeirah', 'Port de La Mer',
      'Tilal Al Ghaf', 'The Springs', 'The Views', 'The Villa', 'Victory Heights'
    ];

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Areas of Interest',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: areas.map((area) {
                final isSelected = _selectedAreas.contains(area);
                return FilterChip(
                  label: Text(area),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedAreas.add(area);
                      } else {
                        _selectedAreas.remove(area);
                      }
                    });
                  },
                  selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                  checkmarkColor: AppTheme.primaryColor,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeveloperStatusSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Developer Status',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FormBuilderTextField(
                    name: 'deliveredProjects',
                    decoration: const InputDecoration(
                      labelText: 'Delivered Projects',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FormBuilderTextField(
                    name: 'underConstruction',
                    decoration: const InputDecoration(
                      labelText: 'Under Construction',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FormBuilderTextField(
                    name: 'totalValue',
                    decoration: const InputDecoration(
                      labelText: 'Total Value (AED)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FormBuilderTextField(
                    name: 'teamSize',
                    decoration: const InputDecoration(
                      labelText: 'Team Size',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentsSection(DeveloperProfile profile) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Documents',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
            ),
            const SizedBox(height: 16),
            _buildDocumentUploadItem('Company Catalog', profile.catalogDocumentUrl, _selectedCatalogDocument, () => _pickDocument('catalog')),
            const SizedBox(height: 12),
            _buildDocumentUploadItem('Trade License', profile.tradeLicense, _selectedTradeLicense, () => _pickDocument('tradeLicense')),
            const SizedBox(height: 12),
            _buildDocumentUploadItem('Signatory Passport', profile.signatoryPassport, _selectedPassport, () => _pickDocument('passport')),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentUploadItem(String title, String? currentUrl, String? selectedUrl, VoidCallback onTap) {
    final hasDocument = (selectedUrl != null) || (currentUrl != null && currentUrl.isNotEmpty);
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.description, color: AppTheme.primaryColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  if (hasDocument)
                    Text(
                      selectedUrl != null ? 'New document selected' : 'Document uploaded',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.successColor,
                          ),
                    )
                  else
                    Text(
                      'Tap to upload document',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                    ),
                ],
              ),
            ),
            Icon(Icons.upload, color: AppTheme.primaryColor),
          ],
        ),
      ),
    );
  }

  Future<void> _pickProfilePicture() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _selectedProfilePicture = image.path;
        });
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

  Future<void> _pickDocument(String documentType) async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          switch (documentType) {
            case 'catalog':
              _selectedCatalogDocument = image.path;
              break;
            case 'tradeLicense':
              _selectedTradeLicense = image.path;
              break;
            case 'passport':
              _selectedPassport = image.path;
              break;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking document: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  ImageProvider? _getProfileImageProvider(String? selectedPath, String? userUrl) {
    if (selectedPath != null) {
      // If we have a selected local file, use FileImage
      return FileImage(File(selectedPath));
    } else if (userUrl != null && userUrl.isNotEmpty) {
      // If we have a network URL, use NetworkImage
      return NetworkImage(userUrl);
    }
    return null;
  }

  Widget? _getProfileImageChild(String? selectedPath, String? userUrl) {
    if (selectedPath == null && (userUrl == null || userUrl.isEmpty)) {
      return const Icon(Icons.business, size: 40, color: AppTheme.primaryColor);
    }
    return null;
  }

  Future<String> _uploadKycDocument(String filePath, String documentType) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('Document file does not exist');
      }
      
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(file.path)}';
      final ref = FirebaseStorage.instance.ref().child('kyc/$documentType/$fileName');
      
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'uploadedAt': DateTime.now().toIso8601String(),
          'type': documentType,
        },
      );
      
      final uploadTask = ref.putFile(file, metadata);
      final snapshot = await uploadTask.timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          throw Exception('Document upload timeout - please check your internet connection');
        },
      );
      
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading KYC document: $e');
      // Return a placeholder URL for development
      return 'https://via.placeholder.com/400x300/007bff/ffffff?text=Document+Upload+Failed';
    }
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

        // Upload new profile picture if selected
        String? newProfilePictureUrl;
        if (_selectedProfilePicture != null) {
          final photoUploadService = PhotoUploadService();
          final file = File(_selectedProfilePicture!);
          newProfilePictureUrl = await photoUploadService.uploadProfilePicture(file);
        }

        // Upload new documents if selected
        String? newCatalogUrl;
        if (_selectedCatalogDocument != null) {
          newCatalogUrl = await _uploadKycDocument(_selectedCatalogDocument!, 'catalog_documents');
        }

        String? newTradeLicenseUrl;
        if (_selectedTradeLicense != null) {
          newTradeLicenseUrl = await _uploadKycDocument(_selectedTradeLicense!, 'trade_licenses');
        }

        String? newPassportUrl;
        if (_selectedPassport != null) {
          newPassportUrl = await _uploadKycDocument(_selectedPassport!, 'signatory_passports');
        }

        // Update profile
        final updatedProfile = currentProfile.copyWith(
          companyName: formData['companyName'],
          companyEmail: formData['companyEmail'],
          companyPhone: formData['companyPhone'],
          businessModel: _selectedBusinessModel ?? currentProfile.businessModel,
          areasInterested: _selectedAreas,
          deliveredProjects: int.tryParse(formData['deliveredProjects'] ?? '0') ?? 0,
          underConstruction: int.tryParse(formData['underConstruction'] ?? '0') ?? 0,
          totalValue: int.tryParse(formData['totalValue'] ?? '0') ?? 0,
          teamSize: int.tryParse(formData['teamSize'] ?? '0') ?? 0,
          catalogDocumentUrl: newCatalogUrl ?? currentProfile.catalogDocumentUrl,
          tradeLicense: newTradeLicenseUrl ?? currentProfile.tradeLicense,
          signatoryPassport: newPassportUrl ?? currentProfile.signatoryPassport,
          updatedAt: DateTime.now(),
        );

        // Update user profile picture if changed
        if (newProfilePictureUrl != null) {
          final currentUser = await authService.getCurrentUser();
          if (currentUser != null) {
            final updatedUser = currentUser.copyWith(profilePictureUrl: newProfilePictureUrl);
            await authService.updateUserProfile(updatedUser);
          }
        }

        await authService.updateDeveloperProfile(updatedProfile);

        // Invalidate the provider to refresh the profile data
        ref.invalidate(developerProfileProvider(currentUser.id));
        
        // Also invalidate auth state to refresh user data and navigation role
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
