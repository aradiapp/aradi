import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:aradi/app/theme/app_theme.dart';
import 'package:aradi/core/models/land_listing.dart';
import 'package:aradi/core/services/land_listing_service.dart';
import 'package:aradi/core/services/auth_service.dart';
import 'package:aradi/core/services/photo_upload_service.dart';
import 'package:aradi/app/providers/data_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class LandFormPage extends ConsumerStatefulWidget {
  const LandFormPage({super.key});

  @override
  ConsumerState<LandFormPage> createState() => _LandFormPageState();
}

class _LandFormPageState extends ConsumerState<LandFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _locationController = TextEditingController();
  final _areaController = TextEditingController();
  final _landSizeController = TextEditingController();
  final _gfaController = TextEditingController();
  final _priceController = TextEditingController();
  final _notesController = TextEditingController();
  
  String _selectedOwnership = 'freehold';
  ListingType _selectedListingType = ListingType.both;
  List<String> _selectedPermissions = [];
  bool _isSubmitting = false;
  final LandListingService _landListingService = LandListingService();
  final PhotoUploadService _photoUploadService = PhotoUploadService();
  final FirebaseStorage _storage = FirebaseStorage.instance;
  
  // Photo-related variables
  List<File> _selectedImages = [];
  final ImagePicker _imagePicker = ImagePicker();
  final List<String> _ownershipTypes = ['freehold', 'leasehold', 'gcc'];
  final List<String> _permissionTypes = ['residential', 'commercial', 'hotel', 'mix'];

  @override
  void dispose() {
    _locationController.dispose();
    _areaController.dispose();
    _landSizeController.dispose();
    _gfaController.dispose();
    _priceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'Create New Listing',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Provide details about your land to attract developers',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 24),

              // Location
              _buildTextField(
                controller: _locationController,
                label: 'Location',
                hint: 'e.g., Dubai Marina',
                icon: Icons.location_on,
                validator: (value) => value?.isEmpty == true ? 'Location is required' : null,
              ),
              const SizedBox(height: 16),

              // Area
              _buildTextField(
                controller: _areaController,
                label: 'Area',
                hint: 'e.g., Dubai Marina',
                icon: Icons.map,
                validator: (value) => value?.isEmpty == true ? 'Area is required' : null,
              ),
              const SizedBox(height: 16),

              // Land Size
              _buildTextField(
                controller: _landSizeController,
                label: 'Land Size (sqm)',
                hint: 'e.g., 5000',
                icon: Icons.square_foot,
                keyboardType: TextInputType.number,
                validator: (value) => value?.isEmpty == true ? 'Land size is required' : null,
              ),
              const SizedBox(height: 16),

              // GFA
              _buildTextField(
                controller: _gfaController,
                label: 'Gross Floor Area (sqm)',
                hint: 'e.g., 15000',
                icon: Icons.business,
                keyboardType: TextInputType.number,
                validator: (value) => value?.isEmpty == true ? 'GFA is required' : null,
              ),
              const SizedBox(height: 16),

              // Asking Price
              _buildTextField(
                controller: _priceController,
                label: 'Asking Price (AED)',
                hint: 'e.g., 25000000',
                icon: Icons.attach_money,
                keyboardType: TextInputType.number,
                validator: (value) => value?.isEmpty == true ? 'Asking price is required' : null,
              ),
              const SizedBox(height: 16),

              // Ownership Type
              _buildOwnershipSelector(),
              const SizedBox(height: 16),

              // Listing Type
              _buildListingTypeSelector(),
              const SizedBox(height: 16),

              // Photos
              _buildPhotoSelector(),
              const SizedBox(height: 16),

              // Permissions
              _buildPermissionSelector(),
              const SizedBox(height: 16),

              // Notes
              _buildTextField(
                controller: _notesController,
                label: 'Additional Notes (Optional)',
                hint: 'Any additional information about the land...',
                icon: Icons.note,
                maxLines: 3,
              ),
              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          'Submit Listing',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required IconData icon,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      items: items.map((item) {
        return DropdownMenuItem(
          value: item,
          child: Text(item.toUpperCase()),
        );
      }).toList(),
    );
  }

  Widget _buildOwnershipSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ownership Type',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Select the ownership type',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: _ownershipTypes.map((ownership) {
            final isSelected = _selectedOwnership == ownership;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _selectedOwnership = ownership;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isSelected 
                        ? AppTheme.primaryColor 
                        : Colors.grey[200],
                    foregroundColor: isSelected 
                        ? Colors.white 
                        : AppTheme.textPrimary,
                    elevation: isSelected ? 2 : 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    ownership.toUpperCase(),
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildListingTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Listing Type',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Select the type of listing',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedListingType = ListingType.buy;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: _selectedListingType == ListingType.buy
                        ? AppTheme.primaryColor
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _selectedListingType == ListingType.buy
                          ? AppTheme.primaryColor
                          : Colors.grey[300]!,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.sell,
                        color: _selectedListingType == ListingType.buy
                            ? Colors.white
                            : Colors.grey[600],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Buy',
                        style: TextStyle(
                          color: _selectedListingType == ListingType.buy
                              ? Colors.white
                              : Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedListingType = ListingType.jvOnly;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: _selectedListingType == ListingType.jvOnly
                        ? AppTheme.primaryColor
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _selectedListingType == ListingType.jvOnly
                          ? AppTheme.primaryColor
                          : Colors.grey[300]!,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.handshake,
                        color: _selectedListingType == ListingType.jvOnly
                            ? Colors.white
                            : Colors.grey[600],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'JV Only',
                        style: TextStyle(
                          color: _selectedListingType == ListingType.jvOnly
                              ? Colors.white
                              : Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedListingType = ListingType.both;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: _selectedListingType == ListingType.both
                        ? AppTheme.primaryColor
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _selectedListingType == ListingType.both
                          ? AppTheme.primaryColor
                          : Colors.grey[300]!,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.business,
                        color: _selectedListingType == ListingType.both
                            ? Colors.white
                            : Colors.grey[600],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Both',
                        style: TextStyle(
                          color: _selectedListingType == ListingType.both
                              ? Colors.white
                              : Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPhotoSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Photos (Optional)',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Add photos to showcase your land listing',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _pickImages,
                icon: const Icon(Icons.add_a_photo),
                label: const Text('Add Photos'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            if (_selectedImages.isNotEmpty)
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _clearImages,
                  icon: const Icon(Icons.clear),
                  label: const Text('Clear All'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
          ],
        ),
        if (_selectedImages.isNotEmpty) ...[
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedImages.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          _selectedImages[index],
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => _removeImage(index),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPermissionSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Development Permissions',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Select all applicable permissions',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _permissionTypes.map((permission) {
            final isSelected = _selectedPermissions.contains(permission);
            return FilterChip(
              label: Text(permission.toUpperCase()),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedPermissions.add(permission);
                  } else {
                    _selectedPermissions.remove(permission);
                  }
                });
              },
              selectedColor: AppTheme.primaryColor.withOpacity(0.2),
              checkmarkColor: AppTheme.primaryColor,
            );
          }).toList(),
        ),
        if (_selectedPermissions.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Please select at least one permission',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.errorColor,
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(images.map((image) => File(image.path)));
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking images: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  void _clearImages() {
    setState(() {
      _selectedImages.clear();
    });
  }

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPermissions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one development permission'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      print('Starting form submission...');
      // Get current user
      final authService = ref.read(authServiceProvider);
      final currentUser = await authService.getCurrentUser();
      
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Upload photos to Firebase Storage first
      List<String> photoUrls = [];
      if (_selectedImages.isNotEmpty) {
        try {
          // Create a temporary listing ID for photo uploads
          final tempListingId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
          print('Attempting to upload ${_selectedImages.length} photos...');
          print('Photo files: ${_selectedImages.map((f) => f.path).toList()}');
          
          // Skip connection test to avoid double uploads
          print('Skipping connection test to avoid double uploads');
          
          photoUrls = await _photoUploadService.uploadPhotos(_selectedImages, tempListingId);
          print('Photo upload completed: ${photoUrls.length} URLs received');
        } catch (e) {
          print('Photo upload failed: $e');
          // Continue without photos rather than failing the entire listing
          photoUrls = [];
        }
      }

      // Create the land listing with only essential fields
      final listing = LandListing(
        id: '', // Will be set by Firestore
        sellerId: currentUser.id,
        sellerName: currentUser.name,
        location: _locationController.text.trim(),
        area: _areaController.text.trim(),
        landSize: double.parse(_landSizeController.text.trim()),
        gfa: double.parse(_gfaController.text.trim()),
        askingPrice: double.parse(_priceController.text.trim()),
        ownershipType: OwnershipType.values.firstWhere(
          (e) => e.toString().split('.').last == _selectedOwnership,
          orElse: () => OwnershipType.freehold,
        ),
        permissions: _selectedPermissions.map((p) {
          final stringValue = p.toLowerCase();
          return PermissionType.values.firstWhere(
            (e) => e.toString().split('.').last.toLowerCase() == stringValue,
            orElse: () => PermissionType.residential,
          );
        }).toList(),
        photoUrls: photoUrls, // Now using Firebase Storage URLs
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        title: _locationController.text.trim(),
        description: _notesController.text.trim(),
        city: _areaController.text.trim(),
        state: _areaController.text.trim(),
        zipCode: '',
        zoning: '',
        developmentPermissions: _selectedPermissions,
        // Override defaults to ensure correct values
        listingType: _selectedListingType,
        isActive: false,
        isVerified: false,
        photos: [], // Keep photos empty, only use photoUrls for Firebase Storage URLs
        notes: _notesController.text.trim(),
      );

      // Save to Firebase
      print('Saving listing to Firestore...');
      await _landListingService.createListing(listing);
      print('Listing saved successfully!');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Land listing submitted successfully! ${photoUrls.isNotEmpty ? 'Photos uploaded.' : 'No photos uploaded.'}'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        context.go('/seller');
      }
    } catch (e) {
      print('Error creating listing: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating listing: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
}
