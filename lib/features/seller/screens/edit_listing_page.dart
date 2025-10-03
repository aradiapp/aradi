import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aradi/app/theme/app_theme.dart';
import 'package:aradi/core/models/land_listing.dart';
import 'package:aradi/core/services/land_listing_service.dart';
import 'package:aradi/core/services/photo_upload_service.dart';
import 'package:aradi/app/providers/data_providers.dart';
import 'package:aradi/features/shared/widgets/fullscreen_image_viewer.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class EditListingPage extends ConsumerStatefulWidget {
  final String listingId;

  const EditListingPage({super.key, required this.listingId});

  @override
  ConsumerState<EditListingPage> createState() => _EditListingPageState();
}

class _EditListingPageState extends ConsumerState<EditListingPage> {
  final _formKey = GlobalKey<FormState>();
  
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _areaController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _landSizeController = TextEditingController();
  final _gfaController = TextEditingController();
  final _askingPriceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _notesController = TextEditingController();

  LandListing? _originalListing;
  bool _isLoading = true;
  bool _isSubmitting = false;
  OwnershipType _selectedOwnershipType = OwnershipType.freehold;
  ListingType _selectedListingType = ListingType.both;
  List<PermissionType> _selectedPermissions = [];

  // Photo-related variables
  List<File> _selectedImages = [];
  List<String> _existingPhotoUrls = [];
  final ImagePicker _imagePicker = ImagePicker();

  final LandListingService _landListingService = LandListingService();
  final PhotoUploadService _photoUploadService = PhotoUploadService();

  @override
  void initState() {
    super.initState();
    print('EditListingPage initialized with id: ${widget.listingId}');
    _loadListing();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _areaController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _landSizeController.dispose();
    _gfaController.dispose();
    _askingPriceController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadListing() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final listing = await _landListingService.getListingById(widget.listingId);
      
      if (listing == null) {
        throw Exception('Listing not found');
      }
      
      if (mounted) {
        setState(() {
          _originalListing = listing;
          _populateForm(listing);
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading listing: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading listing: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
        context.go('/seller');
      }
    }
  }

  void _populateForm(LandListing listing) {
    _titleController.text = listing.title;
    _locationController.text = listing.location;
    _areaController.text = listing.area;
    _cityController.text = listing.city;
    _stateController.text = listing.state;
    _landSizeController.text = listing.landSize.toString();
    _gfaController.text = listing.gfa.toString();
    _askingPriceController.text = listing.askingPrice.toString();
    _descriptionController.text = listing.description;
    _notesController.text = listing.notes;
    _selectedOwnershipType = listing.ownershipType;
    _selectedListingType = listing.listingType;
    _selectedPermissions = listing.developmentPermissions.map((permission) {
      final stringValue = permission.toLowerCase();
      return PermissionType.values.firstWhere(
        (p) => p.toString().split('.').last.toLowerCase() == stringValue,
        orElse: () => PermissionType.residential,
      );
    }).toList();
    
    // Load existing photos - we'll display Firebase Storage URLs as network images
    // and only load local files for editing
    _selectedImages = [...listing.photos, ...listing.photoUrls]
        .where((path) => !path.startsWith('http')) // Only local files for editing
        .map((path) => File(path))
        .toList();
    
    // Store Firebase Storage URLs separately for display
    _existingPhotoUrls = [...listing.photos, ...listing.photoUrls]
        .where((path) => path.startsWith('http'))
        .toList();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Prevent duplicate submissions
    if (_isSubmitting) {
      print('Form already submitting, ignoring duplicate submission');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final authService = ref.read(authServiceProvider);
      final currentUser = await authService.getCurrentUser();
      
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      if (_originalListing == null) {
        throw Exception('Original listing not found');
      }

      // Upload new photos to Firebase Storage (only local files)
      List<String> newPhotoUrls = [];
      final localFiles = _selectedImages.where((file) => !file.path.startsWith('http')).toList();
      if (localFiles.isNotEmpty) {
        print('Uploading ${localFiles.length} new photos...');
        // Check if we already have Firebase URLs for these files
        final hasFirebaseUrls = _selectedImages.any((file) => file.path.startsWith('http'));
        if (!hasFirebaseUrls) {
          newPhotoUrls = await _photoUploadService.uploadPhotos(localFiles, widget.listingId);
          print('New photos uploaded: ${newPhotoUrls.length}');
        } else {
          print('Photos already uploaded to Firebase, skipping upload');
          newPhotoUrls = _selectedImages.map((file) => file.path).toList();
        }
      } else {
        print('No new local files to upload');
      }

      // Combine existing photos (that weren't removed) with new photos
      final allPhotoUrls = [..._existingPhotoUrls, ...newPhotoUrls];
      print('Total photos after update: ${allPhotoUrls.length}');

      // Create updated listing
      final updatedListing = _originalListing!.copyWith(
        title: _titleController.text.trim(),
        location: _locationController.text.trim(),
        area: _areaController.text.trim(),
        city: _cityController.text.trim(),
        state: _stateController.text.trim(),
        landSize: double.tryParse(_landSizeController.text) ?? 0.0,
        gfa: double.tryParse(_gfaController.text) ?? 0.0,
        askingPrice: double.tryParse(_askingPriceController.text) ?? 0.0,
        description: _descriptionController.text.trim(),
        notes: _notesController.text.trim(),
        ownershipType: _selectedOwnershipType,
        listingType: _selectedListingType,
        developmentPermissions: _selectedPermissions.map((p) => p.toString().split('.').last).toList(),
        photoUrls: allPhotoUrls,
        photos: [], // Keep photos empty, only use photoUrls for Firebase Storage URLs
        status: ListingStatus.pending_verification, // Reset to pending after update
        isActive: false, // Reset to inactive after update
        isVerified: false, // Reset verification status
        updatedAt: DateTime.now(),
      );

      // Update listing in database
      await _landListingService.updateListing(_originalListing!.id, updatedListing);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Listing updated successfully!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        context.go('/seller/listing/${_originalListing!.id}');
      }
    } catch (e) {
      print('Error updating listing: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating listing: $e'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Edit Listing'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          onPressed: () => context.go('/seller/listing/${widget.listingId}'),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _originalListing == null
              ? const Center(child: Text('Listing not found'))
              : _buildForm(),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Basic Information
            _buildSectionCard(
              'Basic Information',
              [
                _buildTextField(
                  controller: _titleController,
                  label: 'Property Title',
                  hint: 'Enter property title',
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a property title';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _locationController,
                  label: 'Location',
                  hint: 'Enter property location',
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a location';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _areaController,
                        label: 'Area',
                        hint: 'Enter area',
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter an area';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextField(
                        controller: _cityController,
                        label: 'City',
                        hint: 'Enter city',
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a city';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _stateController,
                  label: 'State',
                  hint: 'Enter state',
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a state';
                    }
                    return null;
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Property Details
            _buildSectionCard(
              'Property Details',
              [
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _landSizeController,
                        label: 'Land Size (sqm)',
                        hint: 'Enter land size',
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter land size';
                          }
                          if (double.tryParse(value) == null || double.parse(value) <= 0) {
                            return 'Please enter a valid land size';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextField(
                        controller: _gfaController,
                        label: 'GFA (sqm)',
                        hint: 'Enter GFA',
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter GFA';
                          }
                          if (double.tryParse(value) == null || double.parse(value) <= 0) {
                            return 'Please enter a valid GFA';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _askingPriceController,
                  label: 'Asking Price (AED)',
                  hint: 'Enter asking price',
                  keyboardType: TextInputType.number,
                  prefixText: 'AED ',
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter asking price';
                    }
                    if (double.tryParse(value) == null || double.parse(value) <= 0) {
                      return 'Please enter a valid asking price';
                    }
                    return null;
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Property Type
            _buildSectionCard(
              'Property Type',
              [
                _buildOwnershipSelector(),
                const SizedBox(height: 16),
                _buildListingTypeSelector(),
              ],
            ),
            const SizedBox(height: 24),

            // Photos
            _buildSectionCard(
              'Photos',
              [
                _buildPhotoSelector(),
              ],
            ),
            const SizedBox(height: 24),

            // Development Permissions
            _buildSectionCard(
              'Development Permissions',
              [
                _buildPermissionSelector(),
              ],
            ),
            const SizedBox(height: 24),

            // Additional Information
            _buildSectionCard(
              'Additional Information',
              [
                _buildTextField(
                  controller: _descriptionController,
                  label: 'Description',
                  hint: 'Enter property description',
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _notesController,
                  label: 'Notes',
                  hint: 'Enter any additional notes',
                  maxLines: 3,
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
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
                    : const Text(
                        'Update Listing',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(String title, List<Widget> children) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType? keyboardType,
    String? prefixText,
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
        prefixText: prefixText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.primaryColor),
        ),
      ),
    );
  }

  Widget _buildOwnershipSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ownership Type',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w500,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: OwnershipType.values.map((type) {
            final isSelected = _selectedOwnershipType == type;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedOwnershipType = type;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primaryColor : Colors.grey[200],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? AppTheme.primaryColor : Colors.grey[300]!,
                  ),
                ),
                child: Text(
                  type.toString().split('.').last.replaceAll('_', ' ').toUpperCase(),
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppTheme.textPrimary,
                    fontWeight: FontWeight.w500,
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
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w500,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ListingType.values.map((type) {
            final isSelected = _selectedListingType == type;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedListingType = type;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primaryColor : Colors.grey[200],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? AppTheme.primaryColor : Colors.grey[300]!,
                  ),
                ),
                child: Text(
                  type.toString().split('.').last.replaceAll('_', ' ').toUpperCase(),
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppTheme.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPermissionSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Development Permissions',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w500,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: PermissionType.values.map((permission) {
            final isSelected = _selectedPermissions.contains(permission);
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedPermissions.remove(permission);
                  } else {
                    _selectedPermissions.add(permission);
                  }
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primaryColor : Colors.grey[200],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? AppTheme.primaryColor : Colors.grey[300]!,
                  ),
                ),
                child: Text(
                  permission.toString().split('.').last.replaceAll('_', ' ').toUpperCase(),
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppTheme.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            );
          }).toList(),
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
        // Show existing photos (Firebase Storage URLs)
        if (_existingPhotoUrls.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'Existing Photos',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _existingPhotoUrls.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: Stack(
                    children: [
                      GestureDetector(
                        onTap: () => _showFullscreenImage(_existingPhotoUrls, index),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            _existingPhotoUrls[index],
                            width: 120,
                            height: 120,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 120,
                                height: 120,
                                color: Colors.grey[200],
                                child: const Icon(Icons.broken_image),
                              );
                            },
                          ),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => _removeExistingPhoto(index),
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
        
        // Show new photos (local files)
        if (_selectedImages.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'New Photos',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
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
                      GestureDetector(
                        onTap: () => _showFullscreenImage(_selectedImages.map((file) => file.path).toList(), index),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            _selectedImages[index],
                            width: 120,
                            height: 120,
                            fit: BoxFit.cover,
                          ),
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

  void _removeExistingPhoto(int index) async {
    final photoUrl = _existingPhotoUrls[index];
    
    // Delete from Firebase Storage
    try {
      await _photoUploadService.deletePhoto(photoUrl);
      print('Photo deleted from Firebase Storage: $photoUrl');
    } catch (e) {
      print('Error deleting photo from Firebase Storage: $e');
    }
    
    // Remove from local state
    setState(() {
      _existingPhotoUrls.removeAt(index);
    });
  }

  void _showFullscreenImage(List<String> imageUrls, int initialIndex) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FullscreenImageViewer(
          imageUrls: imageUrls,
          initialIndex: initialIndex,
        ),
      ),
    );
    
    // If user deleted an image, handle it
    if (result != null && result is int) {
      final deletedIndex = result;
      if (deletedIndex < _existingPhotoUrls.length) {
        _removeExistingPhoto(deletedIndex);
      } else {
        final newPhotoIndex = deletedIndex - _existingPhotoUrls.length;
        if (newPhotoIndex < _selectedImages.length) {
          _removeImage(newPhotoIndex);
        }
      }
    }
  }
}
