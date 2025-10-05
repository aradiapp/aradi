import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:aradi/app/theme/app_theme.dart';
import 'package:aradi/core/models/land_listing.dart';
import 'package:aradi/core/services/land_listing_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aradi/features/shared/widgets/fullscreen_image_viewer.dart';
import 'dart:io';

class BuyerListingDetailPage extends ConsumerStatefulWidget {
  final String listingId;
  
  const BuyerListingDetailPage({
    super.key,
    required this.listingId,
  });

  @override
  ConsumerState<BuyerListingDetailPage> createState() => _BuyerListingDetailPageState();
}

class _BuyerListingDetailPageState extends ConsumerState<BuyerListingDetailPage> {
  LandListing? _listing;
  bool _isLoading = true;
  int _currentPhotoIndex = 0;
  final LandListingService _landListingService = LandListingService();

  @override
  void initState() {
    super.initState();
    _loadListing();
  }

  Future<void> _loadListing() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final listing = await _landListingService.getListingById(widget.listingId);
      if (mounted) {
        setState(() {
          _listing = listing;
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
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Listing Details'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          onPressed: () => context.go('/buyer/browse'),
          icon: const Icon(Icons.arrow_back),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _listing == null
              ? const Center(
                  child: Text('Listing not found'),
                )
              : _buildListingContent(),
    );
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
          
          // Seller Info Card
          _buildSellerInfoCard(listing),
          const SizedBox(height: 24),
          
          // Action Buttons
          _buildActionButtons(listing),
        ],
      ),
    );
  }

  Widget _buildPhotoGallery(LandListing listing) {
    final photos = listing.photos;
    final photoUrls = listing.photoUrls;
    final allPhotos = [...photos, ...photoUrls];
    
    if (allPhotos.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: AppTheme.surfaceColor,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: double.infinity,
            height: double.infinity,
            color: AppTheme.primaryColor.withOpacity(0.1),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.image,
                  size: 48,
                  color: AppTheme.primaryColor,
                ),
                SizedBox(height: 8),
                Text(
                  'No photos available',
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AppTheme.surfaceColor,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Photo carousel
            GestureDetector(
              onTap: () => _showFullscreenImage(allPhotos),
              child: Container(
                width: double.infinity,
                height: double.infinity,
                child: allPhotos.isNotEmpty
                    ? PageView.builder(
                        onPageChanged: (index) {
                          setState(() {
                            _currentPhotoIndex = index;
                          });
                        },
                        itemCount: allPhotos.length,
                        itemBuilder: (context, index) {
                          return _buildImageWidget(allPhotos[index]);
                        },
                      )
                    : Container(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        child: const Icon(
                          Icons.image,
                          size: 48,
                          color: AppTheme.primaryColor,
                        ),
                      ),
              ),
            ),
            // Image counter
            if (allPhotos.length > 1)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_currentPhotoIndex + 1} / ${allPhotos.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            // Photo indicator dots
            if (allPhotos.length > 1)
              Positioned(
                bottom: 12,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    allPhotos.length,
                    (index) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: index == _currentPhotoIndex ? Colors.white : Colors.white.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageWidget(String imagePath) {
    // Check if it's a local file path or network URL
    if (imagePath.startsWith('http')) {
      return Image.network(
        imagePath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: AppTheme.primaryColor.withOpacity(0.1),
            child: const Icon(
              Icons.broken_image,
              size: 48,
              color: AppTheme.primaryColor,
            ),
          );
        },
      );
    } else {
      // Local file
      return Image.file(
        File(imagePath),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: AppTheme.primaryColor.withOpacity(0.1),
            child: const Icon(
              Icons.broken_image,
              size: 48,
              color: AppTheme.primaryColor,
            ),
          );
        },
      );
    }
  }

  Widget _buildHeaderCard(LandListing listing) {
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
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${listing.emirate}, ${listing.city}',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${listing.emirate}, ${listing.city}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      Text(
                        listing.area,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.successColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.verified,
                        size: 16,
                        color: AppTheme.successColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Verified',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.successColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              listing.description.isNotEmpty ? listing.description : 'No description provided',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTheme.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsCard(LandListing listing) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
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
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            _buildDetailRow(
              icon: Icons.square_foot,
              label: 'Land Size',
              value: '${listing.landSize.toStringAsFixed(0)} sqm',
            ),
            _buildDetailRow(
              icon: Icons.business,
              label: 'GFA',
              value: '${listing.gfa.toStringAsFixed(0)} sqm',
            ),
            _buildDetailRow(
              icon: Icons.attach_money,
              label: 'Asking Price',
              value: 'AED ${(listing.askingPrice / 1000000).toStringAsFixed(2)}M',
            ),
            _buildDetailRow(
              icon: Icons.category,
              label: 'Ownership Type',
              value: listing.ownershipType.toString().split('.').last,
            ),
            _buildDetailRow(
              icon: Icons.type_specimen,
              label: 'Listing Type',
              value: listing.listingType.toString().split('.').last,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionsCard(LandListing listing) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
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
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: listing.developmentPermissions.map((permission) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    permission,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.secondaryColor,
                      fontWeight: FontWeight.w500,
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

  Widget _buildSellerInfoCard(LandListing listing) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Seller Information',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            _buildDetailRow(
              icon: Icons.person,
              label: 'Seller Name',
              value: listing.sellerName,
            ),
            _buildDetailRow(
              icon: Icons.calendar_today,
              label: 'Listed On',
              value: _formatDate(listing.createdAt),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(LandListing listing) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => context.go('/buyer/browse'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Back to Browse',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.primaryColor,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: () => _showOfferDialog(listing),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Make Offer',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: AppTheme.textSecondary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showOfferDialog(LandListing listing) {
    final offerController = TextEditingController();
    final notesController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Make an Offer'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Property: ${listing.emirate}, ${listing.city}',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Asking Price: AED ${(listing.askingPrice / 1000000).toStringAsFixed(2)}M',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: offerController,
                decoration: const InputDecoration(
                  labelText: 'Your Offer (AED)',
                  hintText: 'Enter your offer amount',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'Additional Notes (Optional)',
                  hintText: 'Any additional information for the seller',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.warningColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info,
                      size: 16,
                      color: AppTheme.warningColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Your offer must be within ±20% of the asking price',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.warningColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _submitOffer(listing, offerController.text, notesController.text);
            },
            child: const Text('Submit Offer'),
          ),
        ],
      ),
    );
  }

  void _submitOffer(LandListing listing, String offerAmount, String notes) {
    // TODO: Implement actual offer submission to Firebase
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Offer submitted successfully! The seller will be notified.'),
        backgroundColor: AppTheme.successColor,
      ),
    );
  }

  void _showFullscreenImage(List<String> imageUrls) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FullscreenImageViewer(
          imageUrls: imageUrls,
          initialIndex: _currentPhotoIndex,
        ),
      ),
    );
  }

}
