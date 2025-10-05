import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:aradi/app/theme/app_theme.dart';
import 'package:aradi/core/models/land_listing.dart';
import 'package:aradi/core/models/user.dart';
import 'package:aradi/core/models/offer.dart';
import 'package:aradi/core/services/land_listing_service.dart';
import 'package:aradi/core/services/offer_service.dart';
import 'package:aradi/core/services/negotiation_service.dart';
import 'package:aradi/core/services/auth_service.dart';
import 'package:aradi/app/providers/data_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aradi/features/shared/widgets/fullscreen_image_viewer.dart';
import 'dart:io';

class ListingDetailPage extends ConsumerStatefulWidget {
  final String listingId;

  const ListingDetailPage({super.key, required this.listingId});

  @override
  ConsumerState<ListingDetailPage> createState() => _ListingDetailPageState();
}

class _ListingDetailPageState extends ConsumerState<ListingDetailPage> {
  LandListing? _listing;
  bool _isLoading = true;
  bool _isSubmittingOffer = false;
  bool _isSubmittingJV = false;
  int _currentPhotoIndex = 0;
  
  // Offer form controllers
  final _offerAmountController = TextEditingController();
  final _offerNotesController = TextEditingController();
  
  // JV form controllers
  final _jvEquityController = TextEditingController();
  final _jvInvestmentController = TextEditingController();
  final _jvNotesController = TextEditingController();
  
  // Services
  final LandListingService _landListingService = LandListingService();
  final OfferService _offerService = OfferService();
  final NegotiationService _negotiationService = NegotiationService();

  @override
  void initState() {
    super.initState();
    _loadListing();
  }

  @override
  void dispose() {
    _offerAmountController.dispose();
    _offerNotesController.dispose();
    _jvEquityController.dispose();
    _jvInvestmentController.dispose();
    _jvNotesController.dispose();
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
      
      setState(() {
        _listing = listing;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading listing: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading listing: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
        context.go('/dev');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _listing == null
              ? _buildErrorState()
              : _buildListingDetails(),
      bottomNavigationBar: _buildActionButtons(),
    );
  }

  Widget _buildErrorState() {
    return Center(
        child: Padding(
        padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
              Icons.error_outline,
              size: 64,
              color: AppTheme.errorColor,
            ),
            const SizedBox(height: 16),
            Text(
              'Listing Not Found',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'The listing you are looking for could not be found.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.pop(),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListingDetails() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildImageGallery(),
          const SizedBox(height: 20),
          _buildBasicInfo(),
          const SizedBox(height: 20),
          _buildLocationInfo(),
          const SizedBox(height: 20),
          _buildPropertyDetails(),
          const SizedBox(height: 20),
          _buildPricingInfo(),
          const SizedBox(height: 20),
          _buildSellerInfo(),
          const SizedBox(height: 20),
          _buildDocuments(),
          const SizedBox(height: 100), // Space for bottom buttons
        ],
      ),
    );
  }

  Widget _buildImageGallery() {
    final photos = _listing?.photos ?? [];
    final photoUrls = _listing?.photoUrls ?? [];
    final allPhotos = [...photos, ...photoUrls];
    
    if (allPhotos.isEmpty) {
      return Container(
        height: 250,
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
                  size: 64,
                  color: AppTheme.primaryColor,
                ),
                SizedBox(height: 8),
                Text(
                  'No photos available',
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontSize: 16,
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
      height: 250,
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
                          size: 64,
                          color: AppTheme.primaryColor,
                        ),
                      ),
              ),
            ),
            // Image counter
            if (allPhotos.length > 1)
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_currentPhotoIndex + 1} / ${allPhotos.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            // Photo indicator dots
            if (allPhotos.length > 1)
              Positioned(
                bottom: 16,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    allPhotos.length,
                    (index) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: 8,
                      height: 8,
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
              size: 64,
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
              size: 64,
              color: AppTheme.primaryColor,
            ),
          );
        },
      );
    }
  }

  Widget _buildBasicInfo() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
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
                    color: _getStatusColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _listing!.status.toString().split('.').last.toUpperCase(),
                    style: TextStyle(
                      color: _getStatusColor(),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  'AED ${_formatPrice(_listing!.askingPrice)}',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '${_listing!.emirate}, ${_listing!.city}',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _listing!.description,
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

  Widget _buildLocationInfo() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Location',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Address', '${_listing!.emirate}, ${_listing!.city}'),
            _buildInfoRow('City', _listing!.city),
          ],
        ),
      ),
    );
  }

  Widget _buildPropertyDetails() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.home,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Property Details',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Land Size', '${_listing!.landSize} acres'),
            _buildInfoRow('GFA', '${_listing!.gfa} sq ft'),
            _buildInfoRow('Ownership Type', _listing!.ownershipType.toString().split('.').last),
            _buildInfoRow('Development Permissions', _listing!.developmentPermissions.join(', ')),
          ],
        ),
      ),
    );
  }

  Widget _buildPricingInfo() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.attach_money,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Pricing Information',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Asking Price', 'AED ${_formatPrice(_listing!.askingPrice)}'),
            _buildInfoRow('Price per Acre', 'AED ${_formatPrice(_listing!.askingPrice / _listing!.landSize)}'),
            _buildInfoRow('Price per Sq Ft', 'AED ${(_listing!.askingPrice / _listing!.gfa).toStringAsFixed(2)}'),
          ],
        ),
      ),
    );
  }

  Widget _buildSellerInfo() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.person,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Seller Information',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Seller ID', _listing!.sellerId),
            _buildInfoRow('Listed Date', _formatDate(_listing!.createdAt)),
            _buildInfoRow('Last Updated', _formatDate(_listing!.updatedAt)),
          ],
        ),
      ),
    );
  }

  Widget _buildDocuments() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.description,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Documents',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDocumentItem('Property Deed', Icons.description),
            _buildDocumentItem('Survey Report', Icons.map),
            _buildDocumentItem('Zoning Certificate', Icons.verified),
            _buildDocumentItem('Environmental Report', Icons.eco),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentItem(String title, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryColor),
      title: Text(title),
      trailing: const Icon(Icons.download),
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Downloading $title...'),
            backgroundColor: AppTheme.primaryColor,
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _showOfferDialog,
                icon: const Icon(Icons.mail),
                label: const Text('Make Offer'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _showJVDialog,
                icon: const Icon(Icons.handshake),
                label: const Text('JV Proposal'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showOfferDialog() {
    showDialog(
      context: context,
      builder: (context) => _buildOfferDialog(),
    );
  }

  void _showJVDialog() {
    showDialog(
      context: context,
      builder: (context) => _buildJVDialog(),
    );
  }

  Widget _buildOfferDialog() {
    return AlertDialog(
      title: const Text('Make an Offer'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _offerAmountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Offer Amount',
                prefixText: 'AED ',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _offerNotesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Notes (Optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submitOffer,
          child: _isSubmittingOffer
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Submit Offer'),
        ),
      ],
    );
  }

  Widget _buildJVDialog() {
    return AlertDialog(
      title: const Text('Joint Venture Proposal'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _jvEquityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Equity Percentage',
                suffixText: '%',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _jvInvestmentController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Investment Amount',
                prefixText: 'AED ',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _jvNotesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Proposal Details',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submitJV,
          child: _isSubmittingJV
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Submit Proposal'),
        ),
      ],
    );
  }

  Future<void> _submitOffer() async {
    if (_offerAmountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter an offer amount'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    setState(() {
      _isSubmittingOffer = true;
    });

    try {
      // Get current user
      final authService = ref.read(authServiceProvider);
      final currentUser = await authService.getCurrentUser();
      
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Create the offer
      final offer = Offer(
        id: '', // Will be set by Firestore
        listingId: widget.listingId,
        developerId: currentUser.id,
        developerName: currentUser.name,
        type: OfferType.buy,
        buyPrice: double.parse(_offerAmountController.text.trim()),
        status: OfferStatus.pending,
        notes: _offerNotesController.text.trim(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Save offer to Firebase
      await _offerService.createOffer(offer);

      // Create negotiation thread
      await _negotiationService.createNegotiation(
        listingId: widget.listingId,
        developerId: currentUser.id,
        developerName: currentUser.name,
        listingTitle: '${_listing!.emirate}, ${_listing!.city}',
        sellerId: _listing!.sellerId,
        sellerName: 'Seller', // TODO: Get actual seller name
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Offer submitted successfully!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      print('Error submitting offer: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting offer: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmittingOffer = false;
        });
      }
    }
  }

  Future<void> _submitJV() async {
    if (_jvEquityController.text.isEmpty || _jvInvestmentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    setState(() {
      _isSubmittingJV = true;
    });

    try {
      // Get current user
      final authService = ref.read(authServiceProvider);
      final currentUser = await authService.getCurrentUser();
      
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Parse JV percentages
      final sellerPercentage = double.parse(_jvEquityController.text.trim());
      final developerPercentage = double.parse(_jvInvestmentController.text.trim());
      
      // Validate percentages sum to 100%
      if (sellerPercentage + developerPercentage != 100.0) {
        throw Exception('Partnership percentages must sum to 100%');
      }

      // Create JV proposal
      final jvProposal = JVProposal(
        sellerPercentage: sellerPercentage,
        developerPercentage: developerPercentage,
        investmentAmount: double.parse(_jvInvestmentController.text.trim()),
        notes: _jvNotesController.text.trim(),
      );

      // Create the offer
      final offer = Offer(
        id: '', // Will be set by Firestore
        listingId: widget.listingId,
        developerId: currentUser.id,
        developerName: currentUser.name,
        type: OfferType.jv,
        jvProposal: jvProposal,
        status: OfferStatus.pending,
        notes: _jvNotesController.text.trim(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Save offer to Firebase
      await _offerService.createOffer(offer);

      // Create negotiation thread
      await _negotiationService.createNegotiation(
        listingId: widget.listingId,
        developerId: currentUser.id,
        developerName: currentUser.name,
        listingTitle: '${_listing!.emirate}, ${_listing!.city}',
        sellerId: _listing!.sellerId,
        sellerName: 'Seller', // TODO: Get actual seller name
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('JV proposal submitted successfully!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      print('Error submitting JV proposal: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting JV proposal: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmittingJV = false;
        });
      }
    }
  }

  void _shareListing() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sharing listing...'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  void _toggleFavorite() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Added to favorites'),
        backgroundColor: AppTheme.successColor,
      ),
    );
  }

  Color _getStatusColor() {
    switch (_listing!.status) {
      case ListingStatus.active:
        return AppTheme.successColor;
      case ListingStatus.pending_verification:
        return AppTheme.warningColor;
      case ListingStatus.sold:
        return AppTheme.textSecondary;
      case ListingStatus.expired:
        return AppTheme.errorColor;
      case ListingStatus.rejected:
        return AppTheme.errorColor;
    }
  }

  String _formatPrice(double price) {
    if (price >= 1000000) {
      return '${(price / 1000000).toStringAsFixed(2)}M';
    } else if (price >= 1000) {
      return '${(price / 1000).toStringAsFixed(0)}K';
    } else {
      return price.toStringAsFixed(0);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
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
