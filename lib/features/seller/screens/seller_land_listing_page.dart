import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aradi/app/theme/app_theme.dart';
import 'package:aradi/core/models/land_listing.dart';
import 'package:aradi/core/models/developer_profile.dart';
import 'package:aradi/core/services/land_listing_service.dart';
import 'package:aradi/core/services/auth_service.dart';
import 'package:aradi/core/services/negotiation_service.dart';
import 'package:aradi/features/shared/widgets/fullscreen_image_viewer.dart';
import 'dart:io';

class SellerLandListingPage extends ConsumerStatefulWidget {
  final String listingId;

  const SellerLandListingPage({
    Key? key,
    required this.listingId,
  }) : super(key: key);

  @override
  ConsumerState<SellerLandListingPage> createState() => _SellerLandListingPageState();
}

class _SellerLandListingPageState extends ConsumerState<SellerLandListingPage> {
  LandListing? _listing;
  bool _isLoading = true;
  bool _hasAcceptedNegotiation = false;
  final PageController _pageController = PageController();
  int _currentPhotoIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadListing();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadListing() async {
    try {
      final landListingService = LandListingService();
      final listing = await landListingService.getListingById(widget.listingId);
      
      // Check if listing has accepted negotiations
      bool hasAccepted = false;
      if (listing != null) {
        final negotiationService = NegotiationService();
        final negotiations = await negotiationService.getNegotiationsForUser(listing.sellerId, 'seller');
        hasAccepted = negotiations.any((n) => n.listingId == listing.id && n.status.toString().contains('accepted'));
      }
      
      if (mounted) {
        setState(() {
          _listing = listing;
          _hasAcceptedNegotiation = hasAccepted;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading listing: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getOwnershipTypeText(OwnershipType type) {
    switch (type) {
      case OwnershipType.freehold:
        return 'Freehold';
      case OwnershipType.leasehold:
        return 'Leasehold';
      case OwnershipType.gcc:
        return 'GCC';
    }
  }

  String _getListingTypeText(ListingType type) {
    switch (type) {
      case ListingType.buy:
        return 'Buy';
      case ListingType.jv:
        return 'JV';
      case ListingType.both:
        return 'Both';
    }
  }

  String _getStatusText(ListingStatus status) {
    return status.toString().split('.').last.replaceAll('_', ' ').toUpperCase();
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildPhotoGallery(LandListing listing) {
    final allPhotos = [...listing.photoUrls, ...listing.photos];
    if (allPhotos.isEmpty) {
      return Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.grey[100],
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.image, size: 48, color: Colors.grey),
                SizedBox(height: 8),
                Text('No photos available', style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        ),
      );
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        height: 200,
        child: PageView.builder(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() {
              _currentPhotoIndex = index;
            });
          },
          itemCount: allPhotos.length,
          itemBuilder: (context, index) {
            return GestureDetector(
              onTap: () => _showFullscreenImage(allPhotos),
              child: _buildImageWidget(allPhotos[index]),
            );
          },
        ),
      ),
    );
  }

  Widget _buildImageWidget(String imageUrl) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        image: DecorationImage(
          image: NetworkImage(imageUrl),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildHeaderCard(LandListing listing) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${listing.emirate}, ${listing.city}',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              listing.area,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem('Land Size', '${listing.landSize} sqm'),
                ),
                Expanded(
                  child: _buildInfoItem('GFA', '${listing.gfa} sqm'),
                ),
                Expanded(
                  child: _buildInfoItem('Price', '${_formatPrice(listing.askingPrice)} AED'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  String _formatPrice(double price) {
    if (price >= 1000000) {
      return '${(price / 1000000).toStringAsFixed(1)}M';
    } else if (price >= 1000) {
      return '${(price / 1000).toStringAsFixed(1)}K';
    }
    return price.toStringAsFixed(0);
  }

  Widget _buildDetailsCard(LandListing listing) {
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
              'Property Details',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Ownership Type', _getOwnershipTypeText(listing.ownershipType)),
            _buildInfoRow('Listing Type', _getListingTypeText(listing.listingType)),
            if (listing.description.isNotEmpty)
              _buildInfoRow('Description', listing.description),
            if (listing.titleDeedDocumentUrl != null && listing.titleDeedDocumentUrl!.isNotEmpty)
              _buildDocumentRow('Title Deed Document', listing.titleDeedDocumentUrl!),
            if (listing.dcrDocumentUrl != null && listing.dcrDocumentUrl!.isNotEmpty)
              _buildDocumentRow('DCR Document', listing.dcrDocumentUrl!),
            _buildInfoRow('Created', _formatDate(listing.createdAt)),
            if (listing.updatedAt != null)
              _buildInfoRow('Last Updated', _formatDate(listing.updatedAt!)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
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

  Widget _buildDocumentRow(String label, String url) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
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
            child: GestureDetector(
              onTap: () => _showFullscreenImage([url]),
              child: Text(
                'View Document',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.primaryColor,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionsCard(LandListing listing) {
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
              'Development Permissions',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: listing.permissions.map((permission) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    permission.toString().split('.').last.replaceAll('_', ' ').toUpperCase(),
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(LandListing listing) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getNegotiationStatusColor(),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _getNegotiationStatusText(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Spacer(),
                _buildInfoItem('Active', listing.isActive ? 'Yes' : 'No'),
                const SizedBox(width: 16),
                _buildInfoItem('Verified', listing.isVerified ? 'Yes' : 'No'),
              ],
            ),
            if (listing.verifiedAt != null) ...[
              const SizedBox(height: 16),
              _buildInfoItem('Verified At', _formatDate(listing.verifiedAt!)),
              if (listing.verifiedBy != null)
                _buildInfoItem('Verified By', listing.verifiedBy!),
            ],
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(ListingStatus status) {
    switch (status) {
      case ListingStatus.pending_verification:
        return Colors.orange;
      case ListingStatus.active:
        return Colors.green;
      case ListingStatus.sold:
        return Colors.blue;
      case ListingStatus.expired:
        return Colors.red;
      case ListingStatus.rejected:
        return Colors.red;
    }
  }

  Widget _buildActionButtons(LandListing listing) {
    final bool isDisabled = _hasAcceptedNegotiation || listing.status == ListingStatus.sold;
    
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: isDisabled ? null : () {
              final editUrl = '/seller/listing/${listing.id}/edit';
              context.go(editUrl);
            },
            icon: const Icon(Icons.edit),
            label: const Text('Edit Listing'),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDisabled ? Colors.grey : AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: isDisabled ? null : () => _showDeleteDialog(listing),
            icon: const Icon(Icons.delete),
            label: const Text('Delete'),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDisabled ? Colors.grey : Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  void _showDeleteDialog(LandListing listing) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Listing'),
        content: const Text('Are you sure you want to delete this listing? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _deleteListing(listing);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteListing(LandListing listing) async {
    try {
      final landListingService = LandListingService();
      await landListingService.deleteListing(listing.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Listing deleted successfully')),
        );
        context.go('/seller');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting listing: $e')),
        );
      }
    }
  }

  void _showFullscreenImage(List<String> images) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FullscreenImageViewer(
          imageUrls: images,
          initialIndex: _currentPhotoIndex,
        ),
      ),
    );
  }

  Widget _buildPreferredDevelopersCard(LandListing listing) {
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
              'Preferred Developers',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            FutureBuilder<List<String>>(
              future: _getDeveloperNames(listing.preferredDeveloperIds),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }
                if (snapshot.hasError) {
                  return Text('Error loading developers: ${snapshot.error}');
                }
                final developerNames = snapshot.data ?? [];
                
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: developerNames.map((name) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
                      ),
                      child: Text(
                        name,
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<List<String>> _getDeveloperNames(List<String> developerIds) async {
    try {
      final authService = AuthService();
      final developers = await authService.getVerifiedDevelopers();
      
      return developerIds.map((id) {
        final developer = developers.firstWhere(
          (dev) => dev.id == id,
          orElse: () => DeveloperProfile(
            id: id,
            userId: id,
            companyName: 'Unknown Developer',
            companyEmail: 'unknown@example.com',
            companyPhone: '000-000-0000',
            tradeLicense: 'Unknown',
            signatoryPassport: 'Unknown',
            businessModel: BusinessModel.business,
            areasInterested: [],
            deliveredProjects: 0,
            underConstruction: 0,
            totalValue: 0,
            teamSize: 0,
            freeYearStart: DateTime.now(),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
        return developer.companyName;
      }).toList();
    } catch (e) {
      print('Error fetching developer names: $e');
      return developerIds.map((id) => 'Developer $id').toList();
    }
  }

  Widget _buildListingContent() {
    final listing = _listing!;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Photo Gallery
          _buildPhotoGallery(listing),
          const SizedBox(height: 16),
          
          // Header Card
          _buildHeaderCard(listing),
          const SizedBox(height: 16),
          
          // Details Card
          _buildDetailsCard(listing),
          const SizedBox(height: 16),
          
          // Permissions Card
          _buildPermissionsCard(listing),
          const SizedBox(height: 16),
          
          // Preferred Developers Card
          if (listing.preferredDeveloperIds.isNotEmpty)
            _buildPreferredDevelopersCard(listing),
          if (listing.preferredDeveloperIds.isNotEmpty)
            const SizedBox(height: 16),
          
          // Status Card
          _buildStatusCard(listing),
          const SizedBox(height: 16),
          
          // Status message for accepted negotiations or sold listings
          if (_hasAcceptedNegotiation || listing.status == ListingStatus.sold) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      listing.status == ListingStatus.sold 
                          ? 'This listing has been sold. You cannot edit or delete it.'
                          : 'This listing has an accepted offer. You cannot edit or delete it.',
                      style: TextStyle(
                        color: Colors.orange[800],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // Action Buttons
          _buildActionButtons(listing),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Listing Details'),
        backgroundColor: AppTheme.accentColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          onPressed: () => context.go('/seller'),
          icon: const Icon(Icons.arrow_back),
        ),
        actions: [
          if (_listing != null && !_hasAcceptedNegotiation && _listing!.status != ListingStatus.sold)
            IconButton(
              onPressed: () {
                final editUrl = '/seller/listing/${_listing!.id}/edit';
                print('Navigating to edit URL: $editUrl');
                context.go(editUrl);
              },
              icon: const Icon(Icons.edit),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _listing == null
              ? const Center(
                  child: Text('Listing not found'),
                )
              : _buildListingContent(),
    );
  }

  String _getNegotiationStatusText() {
    if (_hasAcceptedNegotiation) {
      // Check if it's a JV proposal by looking at the negotiation messages
      final negotiationService = NegotiationService();
      // For now, we'll assume it's a regular offer unless we can check the messages
      return 'Pending Admin';
    }
    return _getStatusText(_listing!.status);
  }

  Color _getNegotiationStatusColor() {
    if (_hasAcceptedNegotiation) {
      return Colors.purple;
    }
    return _getStatusColor(_listing!.status);
  }
}