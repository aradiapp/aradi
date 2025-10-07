import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:aradi/app/theme/app_theme.dart';
import 'package:aradi/core/models/land_listing.dart';
import 'package:aradi/core/services/land_listing_service.dart';
import 'package:aradi/core/services/auth_service.dart';
import 'package:aradi/core/services/photo_upload_service.dart';
import 'package:aradi/core/services/location_service.dart';
import 'package:aradi/core/services/notification_service.dart';
import 'package:aradi/app/providers/data_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';

class LandFormPage extends ConsumerStatefulWidget {
  const LandFormPage({super.key});

  @override
  ConsumerState<LandFormPage> createState() => _LandFormPageState();
}

class _LandFormPageState extends ConsumerState<LandFormPage> {
  final _formKey = GlobalKey<FormState>();
  String _selectedEmirate = '';
  String _selectedCity = '';
  String _selectedArea = '';
  final _landSizeController = TextEditingController();
  final _gfaController = TextEditingController();
  final _priceController = TextEditingController();
  final _buildingSpecsController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String _selectedOwnership = 'freehold';
  ListingType _selectedListingType = ListingType.both;
  List<String> _selectedPermissions = [];
  List<String> _selectedPreferredDevelopers = [];
  bool _isSubmitting = false;
  
  // Document upload variables
  File? _titleDeedDocument;
  File? _dcrDocument;
  String _tempListingId = '';
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
    _landSizeController.dispose();
    _gfaController.dispose();
    _priceController.dispose();
    _buildingSpecsController.dispose();
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

              // Emirate Dropdown
              DropdownButtonFormField<String>(
                value: () {
                  final value = _selectedEmirate.isEmpty ? null : _selectedEmirate;
                  print('Emirate dropdown value: $value (from _selectedEmirate: $_selectedEmirate)');
                  return value;
                }(),
                decoration: InputDecoration(
                  labelText: 'Emirate',
                  hintText: 'Select Emirate',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                items: LocationService.getEmirates().map((emirate) {
                  return DropdownMenuItem<String>(
                    value: emirate,
                    child: Text(emirate),
                  );
                }).toList(),
                onChanged: (String? emirate) {
                  print('=== DROPDOWN DEBUG ===');
                  print('Emirate changed to: $emirate');
                  print('Before setState - _selectedEmirate: $_selectedEmirate, _selectedCity: $_selectedCity, _selectedArea: $_selectedArea');
                  setState(() {
                    _selectedEmirate = emirate ?? '';
                    _selectedCity = '';
                    _selectedArea = '';
                  });
                  print('After setState - _selectedEmirate: $_selectedEmirate, _selectedCity: $_selectedCity, _selectedArea: $_selectedArea');
                  print('========================');
                },
                // validator: (value) {
                //   if (value == null || value.isEmpty) {
                //     return 'Please select an Emirate';
                //   }
                //   return null;
                // },
              ),
              const SizedBox(height: 16),

              // City Dropdown
              DropdownButtonFormField<String>(
                value: () {
                  final value = _selectedCity.isEmpty ? null : _selectedCity;
                  print('City dropdown value: $value (from _selectedCity: $_selectedCity)');
                  return value;
                }(),
                decoration: InputDecoration(
                  labelText: 'City',
                  hintText: 'Select City',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                items: _selectedEmirate.isNotEmpty
                    ? LocationService.getCities(_selectedEmirate).map((city) {
                        return DropdownMenuItem<String>(
                          value: city,
                          child: Text(city),
                        );
                      }).toList()
                    : [],
                onChanged: _selectedEmirate.isNotEmpty
                    ? (String? city) {
                        print('=== DROPDOWN DEBUG ===');
                        print('City changed to: $city');
                        print('Before setState - _selectedEmirate: $_selectedEmirate, _selectedCity: $_selectedCity, _selectedArea: $_selectedArea');
                        setState(() {
                          _selectedCity = city ?? '';
                          _selectedArea = '';
                        });
                        print('After setState - _selectedEmirate: $_selectedEmirate, _selectedCity: $_selectedCity, _selectedArea: $_selectedArea');
                        print('========================');
                      }
                    : null,
                // validator: (value) {
                //   if (_selectedEmirate.isNotEmpty && (value == null || value.isEmpty)) {
                //     return 'Please select a City';
                //   }
                //   return null;
                // },
              ),
              const SizedBox(height: 16),

              // Area Dropdown
              DropdownButtonFormField<String>(
                value: () {
                  final value = _selectedArea.isEmpty ? null : _selectedArea;
                  print('Area dropdown value: $value (from _selectedArea: $_selectedArea)');
                  return value;
                }(),
                decoration: InputDecoration(
                  labelText: 'Area',
                  hintText: 'Select Area',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                items: (_selectedEmirate.isNotEmpty && _selectedCity.isNotEmpty)
                    ? LocationService.getAreas(_selectedEmirate, _selectedCity).map((area) {
                        return DropdownMenuItem<String>(
                          value: area,
                          child: Text(area),
                        );
                      }).toList()
                    : [],
                onChanged: (_selectedEmirate.isNotEmpty && _selectedCity.isNotEmpty)
                    ? (String? area) {
                        print('=== DROPDOWN DEBUG ===');
                        print('Area changed to: $area');
                        print('Before setState - _selectedEmirate: $_selectedEmirate, _selectedCity: $_selectedCity, _selectedArea: $_selectedArea');
                        setState(() {
                          _selectedArea = area ?? '';
                        });
                        print('After setState - _selectedEmirate: $_selectedEmirate, _selectedCity: $_selectedCity, _selectedArea: $_selectedArea');
                        print('========================');
                      }
                    : null,
                // validator: (value) {
                //   if (_selectedEmirate.isNotEmpty && _selectedCity.isNotEmpty && (value == null || value.isEmpty)) {
                //     return 'Please select an Area';
                //   }
                //   return null;
                // },
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

              // Description
              _buildTextField(
                controller: _descriptionController,
                label: 'Description',
                hint: 'Describe the property and its features...',
                icon: Icons.description,
                maxLines: 3,
                validator: (value) => value?.isEmpty == true ? 'Description is required' : null,
              ),
              const SizedBox(height: 16),

              // Ownership Type
              _buildOwnershipSelector(),
              const SizedBox(height: 16),

              // Listing Type
              _buildListingTypeSelector(),
              const SizedBox(height: 16),

              // Title Deed Document (Required)
              _buildDocumentUpload(
                title: 'Title Deed Document *',
                subtitle: 'Upload title deed or DCR document',
                file: _titleDeedDocument,
                onFileSelected: (file) => setState(() => _titleDeedDocument = file),
                isRequired: true,
              ),
              const SizedBox(height: 16),

              // Building Specifications
              _buildTextField(
                controller: _buildingSpecsController,
                label: 'Building Specifications',
                hint: 'Enter building specifications...',
                icon: Icons.architecture,
                maxLines: 3,
              ),
              const SizedBox(height: 16),


              // Preferred Developers (for JV/Both)
              if (_selectedListingType == ListingType.jv || _selectedListingType == ListingType.both)
                _buildPreferredDevelopersSelector(),
              if (_selectedListingType == ListingType.jv || _selectedListingType == ListingType.both)
                const SizedBox(height: 16),

              // Photos
              _buildPhotoSelector(),
              const SizedBox(height: 16),

              // Permissions
              _buildPermissionSelector(),
              const SizedBox(height: 16),

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
                    _selectedListingType = ListingType.jv;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: _selectedListingType == ListingType.jv
                        ? AppTheme.primaryColor
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _selectedListingType == ListingType.jv
                          ? AppTheme.primaryColor
                          : Colors.grey[300]!,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.handshake,
                        color: _selectedListingType == ListingType.jv
                            ? Colors.white
                            : Colors.grey[600],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'JV Only',
                        style: TextStyle(
                          color: _selectedListingType == ListingType.jv
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
          _tempListingId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
          print('Attempting to upload ${_selectedImages.length} photos...');
          print('Photo files: ${_selectedImages.map((f) => f.path).toList()}');
          
          // Skip connection test to avoid double uploads
          print('Skipping connection test to avoid double uploads');
          
          photoUrls = await _photoUploadService.uploadPhotos(_selectedImages, _tempListingId);
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
        area: _selectedArea,
        emirate: _selectedEmirate,
        city: _selectedCity,
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
        description: _descriptionController.text.trim(),
        developmentPermissions: _selectedPermissions,
        // Override defaults to ensure correct values
        listingType: _selectedListingType,
        isActive: false,
        isVerified: false,
        photos: [], // Keep photos empty, only use photoUrls for Firebase Storage URLs
        // New fields
        buildingSpecs: _buildingSpecsController.text.trim(),
        preferredDeveloperIds: _selectedPreferredDevelopers,
      );

      // Upload documents if provided
      String? titleDeedUrl;
      String? dcrUrl;
      
      if (_titleDeedDocument != null) {
        try {
          print('Uploading title deed document...');
          titleDeedUrl = await _photoUploadService.uploadDocument(
            _titleDeedDocument!,
            'title_deeds',
            _tempListingId,
          );
          print('Title deed uploaded: $titleDeedUrl');
        } catch (e) {
          print('Title deed upload failed: $e');
        }
      }

      if (_dcrDocument != null) {
        try {
          print('Uploading DCR document...');
          dcrUrl = await _photoUploadService.uploadDocument(
            _dcrDocument!,
            'dcr_documents',
            _tempListingId,
          );
          print('DCR document uploaded: $dcrUrl');
        } catch (e) {
          print('DCR document upload failed: $e');
        }
      }

      // Update listing with document URLs
      final updatedListing = listing.copyWith(
        titleDeedDocumentUrl: titleDeedUrl,
        dcrDocumentUrl: dcrUrl,
      );

      // Save to Firebase
      print('Saving listing to Firestore...');
      await _landListingService.createListing(updatedListing);
      print('Listing saved successfully!');

      // Note: Preferred developer notifications will be sent when admin approves the listing

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

  // New method for document upload
  Widget _buildDocumentUpload({
    required String title,
    required String subtitle,
    required File? file,
    required Function(File?) onFileSelected,
    bool isRequired = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: file != null ? AppTheme.primaryColor : Colors.grey.shade300,
          width: file != null ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.description,
                color: file != null ? AppTheme.primaryColor : Colors.grey.shade600,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: file != null ? AppTheme.primaryColor : Colors.grey.shade800,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              if (file != null)
                Icon(
                  Icons.check_circle,
                  color: AppTheme.successColor,
                  size: 20,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _pickDocument(onFileSelected),
                  icon: const Icon(Icons.upload_file, size: 18),
                  label: Text(file != null ? 'Change Document' : 'Upload Document'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: file != null ? AppTheme.primaryColor : Colors.grey.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              if (file != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => onFileSelected(null),
                  icon: const Icon(Icons.delete, color: AppTheme.errorColor),
                  tooltip: 'Remove document',
                ),
              ],
            ],
          ),
          if (file != null) ...[
            const SizedBox(height: 8),
            Text(
              'Selected: ${file.path.split('/').last}',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Method to pick document
  Future<void> _pickDocument(Function(File?) onFileSelected) async {
    try {
      final result = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      
      if (result != null) {
        onFileSelected(File(result.path));
      }
    } catch (e) {
      print('Error picking document: $e');
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

  // Method for preferred developers selector
  Widget _buildPreferredDevelopersSelector() {
    return Consumer(
      builder: (context, ref, child) {
        return FutureBuilder<List<Map<String, dynamic>>>(
          future: _getVerifiedDevelopers(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (snapshot.hasError) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Text(
                  'Error loading developers: ${snapshot.error}',
                  style: const TextStyle(color: AppTheme.errorColor),
                ),
              );
            }

            final developers = snapshot.data ?? [];

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.business, color: AppTheme.primaryColor, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Preferred Developers',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Select developers you would like to work with for this listing',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (developers.isEmpty)
                    Text(
                      'No verified developers available',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: developers.map((dev) {
                        final isSelected = _selectedPreferredDevelopers.contains(dev['id']);
                        return FilterChip(
                          label: Text(dev['companyName'] ?? 'Unknown Company'),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedPreferredDevelopers.add(dev['id']);
                              } else {
                                _selectedPreferredDevelopers.remove(dev['id']);
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
            );
          },
        );
      },
    );
  }

  // Method to get verified developers
  Future<List<Map<String, dynamic>>> _getVerifiedDevelopers() async {
    try {
      print('Fetching verified developers...');
      
      // Get all developers from Firestore (we'll filter by isVerified in the app)
      final developers = await FirebaseFirestore.instance
          .collection('developerProfiles')
          .get();

      print('Found ${developers.docs.length} developer profiles');
      
      // Debug: Print all documents to see what's in the collection
      for (var doc in developers.docs) {
        print('Developer doc ${doc.id}: ${doc.data()}');
      }
      
      // Get all users with developer role to check KYC status
      final users = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'developer')
          .get();
      
      print('Found ${users.docs.length} users with developer role');
      
      // Create a map of userId -> isKycVerified
      final Map<String, bool> userKycStatus = {};
      for (var userDoc in users.docs) {
        final userData = userDoc.data();
        final userId = userDoc.id;
        final isKycVerified = userData['isKycVerified'] == true;
        userKycStatus[userId] = isKycVerified;
        print('User ${userData['email']}: isKycVerified = $isKycVerified');
      }

      final verifiedDevelopers = developers.docs.where((doc) {
        final data = doc.data();
        final userId = data['userId'] ?? doc.id;
        final isKycVerified = userKycStatus[userId] ?? false;
        print('Developer ${data['companyName']}: isKycVerified = $isKycVerified');
        return isKycVerified;
      }).map((doc) {
        final data = doc.data();
        final developer = {
          'id': doc.id,
          'companyName': data['companyName'] ?? 'Unknown Company',
          'companyEmail': data['companyEmail'] ?? '',
          'userId': data['userId'] ?? doc.id,
        };
        print('Added verified developer: ${developer['companyName']}');
        return developer;
      }).toList();

      print('Returning ${verifiedDevelopers.length} verified developers');
      return verifiedDevelopers;
    } catch (e) {
      print('Error fetching developers: $e');
      return [];
    }
  }

}
