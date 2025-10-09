import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aradi/app/theme/app_theme.dart';
import 'package:aradi/core/models/user.dart';
import 'package:aradi/core/models/land_listing.dart';
import 'package:aradi/core/services/auth_service.dart';
import 'package:aradi/core/services/land_listing_service.dart';
import 'package:aradi/app/providers/data_providers.dart';
import 'package:aradi/features/shared/widgets/fullscreen_image_viewer.dart';
import 'package:aradi/features/admin/widgets/listing_rejection_dialog.dart';
import 'package:aradi/core/services/notification_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';

class AdminVerificationPage extends ConsumerStatefulWidget {
  const AdminVerificationPage({super.key});

  @override
  ConsumerState<AdminVerificationPage> createState() => _AdminVerificationPageState();
}

class _AdminVerificationPageState extends ConsumerState<AdminVerificationPage> {
  List<LandListing> _pendingListings = [];
  List<LandListing> _filteredListings = [];
  bool _isLoading = true;
  ListingStatus? _selectedFilter;
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final landListingService = LandListingService();
      final listings = await landListingService.getPendingListings();
      
      setState(() {
        _pendingListings = listings;
        _isLoading = false;
      });
      _applyFilter();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }



  Future<void> _approveListing(LandListing listing) async {
    try {
      final landListingService = LandListingService();
      await landListingService.verifyListing(listing.id, true);

      if (mounted) {
        setState(() {
          _pendingListings.remove(listing);
        });
        _applyFilter();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${listing.emirate}, ${listing.city} has been approved!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error approving listing: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _rejectListing(LandListing listing) async {
    showDialog(
      context: context,
      builder: (context) => ListingRejectionDialog(
        listingTitle: '${listing.emirate}, ${listing.city}',
        sellerName: listing.sellerName,
        onReject: (rejectionReason) async {
          try {
            final landListingService = LandListingService();
            await landListingService.rejectListing(listing.id, rejectionReason: rejectionReason);
            
            // Send rejection notification
            try {
              final notificationService = NotificationService();
              await notificationService.notifyListingRejection(
                recipientId: listing.sellerId,
                listingTitle: '${listing.emirate}, ${listing.city}',
                rejectionReason: rejectionReason,
              );
            } catch (e) {
              print('Error sending rejection notification: $e');
              // Don't fail the rejection if notification fails
            }
            
            if (mounted) {
              setState(() {
                _pendingListings.remove(listing);
              });
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Listing rejected'),
                  backgroundColor: AppTheme.warningColor,
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error rejecting listing: $e'),
                  backgroundColor: AppTheme.errorColor,
                ),
              );
            }
            rethrow;
          }
        },
      ),
    );
  }

  void _applyFilter() {
    setState(() {
      if (_selectedFilter == null) {
        _filteredListings = _pendingListings;
      } else {
        _filteredListings = _pendingListings.where((listing) => listing.status == _selectedFilter).toList();
      }
    });
  }

  void _onFilterChanged(ListingStatus? filter) {
    setState(() {
      _selectedFilter = filter;
    });
    _applyFilter();
  }

  void _toggleFilters() {
    setState(() {
      _showFilters = !_showFilters;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Listings Review'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _toggleFilters,
            icon: Icon(_showFilters ? Icons.filter_list_off : Icons.filter_list),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_showFilters) _buildFilters(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildListingsTab(),
          ),
        ],
      ),
    );
  }


  Widget _buildListingsTab() {
    if (_filteredListings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _selectedFilter == null ? Icons.check_circle_outline : Icons.filter_list_off,
              size: 64,
              color: _selectedFilter == null ? Colors.green : AppTheme.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              _selectedFilter == null 
                  ? 'No pending listings'
                  : 'No ${_selectedFilter!.toString().split('.').last} listings found',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _selectedFilter == null 
                  ? 'All listings have been processed'
                  : 'Try selecting a different filter',
              style: const TextStyle(
                color: Colors.grey,
              ),
            ),
            if (_selectedFilter != null) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => _onFilterChanged(null),
                child: const Text('Show All'),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: _filteredListings.length,
      itemBuilder: (context, index) {
        final listing = _filteredListings[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with basic info
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppTheme.primaryColor,
                      child: const Icon(
                        Icons.home,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${listing.emirate}, ${listing.city}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${listing.area} • ${listing.landSize} sqm',
                            style: TextStyle(
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            'AED ${(listing.askingPrice / 1000000).toStringAsFixed(2)}M',
                            style: TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Detailed information
                _buildListingDetails(listing),
                
                const SizedBox(height: 16),
                
                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _approveListing(listing),
                        icon: const Icon(Icons.check),
                        label: const Text('Approve'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.successColor,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _rejectListing(listing),
                        icon: const Icon(Icons.close),
                        label: const Text('Reject'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.errorColor,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildListingDetails(LandListing listing) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Listing Details',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 12),
          
          // Location Details (exactly what seller inputted)
          _buildDetailRow('Emirate', listing.emirate),
          _buildDetailRow('City', listing.city),
          _buildDetailRow('Area', listing.area),
          
          const SizedBox(height: 8),
          
          // Photos
          _buildPhotosSection(listing),
          
          const SizedBox(height: 8),
          
          // Property Details
          _buildDetailRow('Land Size', '${listing.landSize} sqm'),
          _buildDetailRow('GFA', '${listing.gfa} sqm'),
          _buildDetailRow('Asking Price', 'AED ${(listing.askingPrice / 1000000).toStringAsFixed(2)}M'),
          _buildDetailRow('Ownership Type', listing.ownershipType.toString().split('.').last.toUpperCase()),
          
          // New fields from current form
          if (listing.description?.isNotEmpty == true) 
            _buildDetailRow('Description', listing.description!),
          if (listing.buildingSpecs?.isNotEmpty == true) 
            _buildDetailRow('Building Specifications', listing.buildingSpecs!),
          
          const SizedBox(height: 8),
          
          // Development Permissions
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 120,
                child: Text(
                  'Development Permissions:',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
              ),
              Expanded(
                child: Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: listing.developmentPermissions.map((permission) {
                    return Chip(
                      label: Text(
                        permission.toString().split('.').last.toUpperCase(),
                        style: const TextStyle(fontSize: 12),
                      ),
                      backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                      labelStyle: TextStyle(color: AppTheme.primaryColor),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Listing Type
          _buildDetailRow('Listing Type', listing.listingType.toString().split('.').last.toUpperCase()),
          
          // Documents
          if (listing.titleDeedDocumentUrl?.isNotEmpty == true) 
            _buildDocumentRow('Title Deed Document', listing.titleDeedDocumentUrl!),
          if (listing.dcrDocumentUrl?.isNotEmpty == true) 
            _buildDocumentRow('DCR Document', listing.dcrDocumentUrl!),
          
          // Preferred Developers (if any)
          if (listing.preferredDeveloperIds.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 120,
                  child: Text(
                    'Preferred Developers:',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
                Expanded(
                  child: FutureBuilder<List<String>>(
                    future: _getDeveloperNames(listing.preferredDeveloperIds),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Text('Loading...', style: TextStyle(fontSize: 14));
                      }
                      if (snapshot.hasError) {
                        return Text('Error: ${snapshot.error}', style: const TextStyle(fontSize: 14));
                      }
                      final developerNames = snapshot.data ?? [];
                      return Text(
                        developerNames.isEmpty 
                          ? 'No developers found'
                          : developerNames.join(', '),
                        style: const TextStyle(fontSize: 14),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
          
          
          const SizedBox(height: 8),
          
          // Seller Information
          _buildDetailRow('Seller', listing.sellerName),
          _buildDetailRow('Created', _formatDate(listing.createdAt)),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildPhotosSection(LandListing listing) {
    final photos = listing.photos;
    final photoUrls = listing.photoUrls;
    final allPhotos = [...photos, ...photoUrls];
    
    if (allPhotos.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Photos',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: const Row(
              children: [
                Icon(Icons.image, color: Colors.grey, size: 20),
                SizedBox(width: 8),
                Text(
                  'No photos available',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Photos (${allPhotos.length})',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: allPhotos.length,
            itemBuilder: (context, index) {
              return Container(
                margin: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => _showFullscreenImage(allPhotos, index),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _buildImageWidget(allPhotos[index]),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildImageWidget(String imagePath) {
    // Check if it's a local file path or network URL
    if (imagePath.startsWith('http')) {
      return Image.network(
        imagePath,
        width: 120,
        height: 120,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 120,
            height: 120,
            color: Colors.grey[200],
            child: const Icon(
              Icons.broken_image,
              color: Colors.grey,
              size: 32,
            ),
          );
        },
      );
    } else {
      // Local file
      return Image.file(
        File(imagePath),
        width: 120,
        height: 120,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 120,
            height: 120,
            color: Colors.grey[200],
            child: const Icon(
              Icons.broken_image,
              color: Colors.grey,
              size: 32,
            ),
          );
        },
      );
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _showFullscreenImage(List<String> imageUrls, int initialIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FullscreenImageViewer(
          imageUrls: imageUrls,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  Future<void> _viewUserDetails(User user) async {
    try {
      print('=== VIEW USER DETAILS DEBUG ===');
      print('User: ${user.name}');
      print('Profile Picture URL: ${user.profilePictureUrl}');
      print('Profile Picture URL is null: ${user.profilePictureUrl == null}');
      print('Profile Picture URL is empty: ${user.profilePictureUrl?.isEmpty}');
      print('================================');
      
      // Load detailed profile information based on user role
      Map<String, dynamic>? profileData;
      
      if (user.role == UserRole.developer) {
        final authService = ref.read(authServiceProvider);
        final developerProfile = await authService.getDeveloperProfile(user.id);
        if (developerProfile != null) {
          profileData = {
            'type': 'developer',
            'companyName': developerProfile.companyName,
            'companyEmail': developerProfile.companyEmail,
            'companyPhone': developerProfile.companyPhone,
            'businessModel': developerProfile.businessModel.toString().split('.').last,
            'areasInterested': developerProfile.areasInterested,
            'tradeLicense': developerProfile.tradeLicense,
            'signatoryPassport': developerProfile.signatoryPassport,
            'logoUrl': developerProfile.logoUrl,
            'catalogDocumentUrl': developerProfile.catalogDocumentUrl,
            'deliveredProjects': developerProfile.deliveredProjects,
            'underConstruction': developerProfile.underConstruction,
            // 'landsInPipeline': developerProfile.landsInPipeline, // Removed field
            'teamSize': developerProfile.teamSize,
          };
        }
      } else if (user.role == UserRole.seller) {
        final authService = ref.read(authServiceProvider);
        final sellerProfile = await authService.getSellerProfile(user.id);
        if (sellerProfile != null) {
          profileData = {
            'type': 'seller',
            'name': sellerProfile.name,
            'email': sellerProfile.email,
            'phone': sellerProfile.phone,
            'passport': sellerProfile.passportOrEmiratesId,
            'tradeLicense': sellerProfile.tradeLicense,
            'tradeLicenseDocumentUrl': sellerProfile.tradeLicenseDocumentUrl,
          };
        }
      } else if (user.role == UserRole.buyer) {
        final authService = ref.read(authServiceProvider);
        final buyerProfile = await authService.getBuyerProfile(user.id);
        if (buyerProfile != null) {
          profileData = {
            'type': 'buyer',
            'name': buyerProfile.name,
            'email': buyerProfile.email,
            'phone': buyerProfile.phone,
            'passport': buyerProfile.passport,
            'areasInterested': buyerProfile.areasInterested,
            'gfaRange': buyerProfile.gfaRange,
            'budgetRange': buyerProfile.budgetRange,
          };
        }
      }

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => _buildUserDetailsDialog(user, profileData),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading user details: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Widget _buildUserDetailsDialog(User user, Map<String, dynamic>? profileData) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    if (user.profilePictureUrl != null && user.profilePictureUrl!.isNotEmpty) {
                      _showFullscreenImage([user.profilePictureUrl!], 0);
                    }
                  },
                  child: CircleAvatar(
                    radius: 30,
                    backgroundColor: AppTheme.primaryColor,
                    backgroundImage: user.profilePictureUrl != null && user.profilePictureUrl!.isNotEmpty
                        ? NetworkImage(user.profilePictureUrl!)
                        : null,
                    child: user.profilePictureUrl == null || user.profilePictureUrl!.isEmpty
                        ? Text(
                            user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        user.email,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Role: ${user.role.toString().split('.').last.toUpperCase()}',
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: profileData != null ? _buildProfileDetails(profileData) : const Text('No profile data available'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileDetails(Map<String, dynamic> profileData) {
    final type = profileData['type'] as String;
    
    if (type == 'developer') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailSection('Company Information', [
            _buildDetailRow('Company Name', profileData['companyName']),
            _buildDetailRow('Email', profileData['companyEmail']),
            _buildDetailRow('Phone', profileData['companyPhone']),
            _buildDetailRow('Business Model', profileData['businessModel']),
          ]),
          const SizedBox(height: 16),
          _buildDetailSection('Areas of Interest', [
            _buildDetailRow('Areas', (profileData['areasInterested'] as List<String>).join(', ')),
          ]),
          const SizedBox(height: 16),
          _buildDetailSection('Company Stats', [
            _buildDetailRow('Delivered Projects', profileData['deliveredProjects'].toString()),
            _buildDetailRow('Under Construction', profileData['underConstruction'].toString()),
            _buildDetailRow('Lands in Pipeline', profileData['landsInPipeline'].toString()),
            _buildDetailRow('Team Size', profileData['teamSize'].toString()),
          ]),
          const SizedBox(height: 16),
          _buildDetailSection('Documents', [
            if (profileData['tradeLicense'] != null)
              _buildDocumentRow('Trade License', profileData['tradeLicense']),
            if (profileData['signatoryPassport'] != null)
              _buildDocumentRow('Signatory Passport', profileData['signatoryPassport']),
            if (profileData['catalogDocumentUrl'] != null)
              _buildDocumentRow('Company Catalog', profileData['catalogDocumentUrl']),
            if (profileData['logoUrl'] != null)
              _buildDocumentRow('Company Logo', profileData['logoUrl']),
          ]),
        ],
      );
    } else if (type == 'seller') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailSection('Personal Information', [
            _buildDetailRow('Name', profileData['name']),
            _buildDetailRow('Email', profileData['email']),
            _buildDetailRow('Phone', profileData['phone']),
            _buildDetailRow('Passport', profileData['passport']),
          ]),
          const SizedBox(height: 16),
          _buildDetailSection('Documents', [
            if (profileData['tradeLicense'] != null)
              _buildDetailRow('Trade License Number', profileData['tradeLicense']),
            if (profileData['tradeLicenseDocumentUrl'] != null)
              _buildDocumentRow('Trade License Document', profileData['tradeLicenseDocumentUrl']),
          ]),
        ],
      );
    } else if (type == 'buyer') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailSection('Personal Information', [
            _buildDetailRow('Name', profileData['name']),
            _buildDetailRow('Email', profileData['email']),
            _buildDetailRow('Phone', profileData['phone']),
            _buildDetailRow('Passport', profileData['passport']),
          ]),
          const SizedBox(height: 16),
          _buildDetailSection('Investment Preferences', [
            _buildDetailRow('Areas of Interest', (profileData['areasInterested'] as List<String>).join(', ')),
            if (profileData['gfaRange'] != null)
              _buildDetailRow('GFA Range', '${profileData['gfaRange']['min']} - ${profileData['gfaRange']['max']} sq ft'),
            if (profileData['budgetRange'] != null)
              _buildDetailRow('Budget Range', '${profileData['budgetRange']['min']} - ${profileData['budgetRange']['max']} AED'),
          ]),
        ],
      );
    }
    
    return const Text('Unknown profile type');
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }


  Widget _buildDocumentRow(String label, String url) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => _showFullscreenImage([url], 0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppTheme.primaryColor),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.visibility, size: 16, color: AppTheme.primaryColor),
                    const SizedBox(width: 4),
                    const Text(
                      'View Document',
                      style: TextStyle(
                        color: AppTheme.primaryColor,
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
    );
  }

  Future<List<String>> _getDeveloperNames(List<String> developerIds) async {
    try {
      final developers = await FirebaseFirestore.instance
          .collection('developerProfiles')
          .where(FieldPath.documentId, whereIn: developerIds)
          .get();
      
      return developers.docs
          .map((doc) => doc.data()['companyName'] as String? ?? 'Unknown Company')
          .toList();
    } catch (e) {
      print('Error fetching developer names: $e');
      return [];
    }
  }

  String _getEmirateFromLocation(String location) {
    if (location.contains(',')) {
      return location.split(',')[0].trim();
    }
    return location;
  }

  String _getCityFromLocation(String location) {
    if (location.contains(',')) {
      return location.split(',')[1].trim();
    }
    return location;
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filter by Status:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              FilterChip(
                label: const Text('All'),
                selected: _selectedFilter == null,
                onSelected: (selected) {
                  if (selected) {
                    _onFilterChanged(null);
                  }
                },
                selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                checkmarkColor: AppTheme.primaryColor,
              ),
              FilterChip(
                label: const Text('Pending'),
                selected: _selectedFilter == ListingStatus.pending_verification,
                onSelected: (selected) {
                  if (selected) {
                    _onFilterChanged(ListingStatus.pending_verification);
                  }
                },
                selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                checkmarkColor: AppTheme.primaryColor,
              ),
              FilterChip(
                label: const Text('Active'),
                selected: _selectedFilter == ListingStatus.active,
                onSelected: (selected) {
                  if (selected) {
                    _onFilterChanged(ListingStatus.active);
                  }
                },
                selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                checkmarkColor: AppTheme.primaryColor,
              ),
              FilterChip(
                label: const Text('Rejected'),
                selected: _selectedFilter == ListingStatus.rejected,
                onSelected: (selected) {
                  if (selected) {
                    _onFilterChanged(ListingStatus.rejected);
                  }
                },
                selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                checkmarkColor: AppTheme.primaryColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

}