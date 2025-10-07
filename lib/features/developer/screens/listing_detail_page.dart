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
import 'package:aradi/core/services/notification_service.dart';
import 'package:aradi/app/providers/data_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aradi/features/shared/widgets/fullscreen_image_viewer.dart';
import 'package:url_launcher/url_launcher.dart';
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
  bool _hasActiveOffer = false;
  bool _hasActiveJV = false;
  bool _isCheckingOffers = false;
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Check for active offers when the page becomes visible
    if (_listing != null) {
      _checkActiveOffer();
    }
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
      
      // Check for active offers
      await _checkActiveOffer();
    } catch (e) {
      print('Error loading listing: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading listing: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
        context.go('/dev/browse');
      }
    }
  }

  Future<void> _checkActiveOffer() async {
    try {
      setState(() {
        _isCheckingOffers = true;
      });
      
      final authService = ref.read(authServiceProvider);
      final currentUser = await authService.getCurrentUser();
      
      if (currentUser != null) {
        // Check if there's an active negotiation for this listing
        final negotiations = await _negotiationService.getNegotiationsForUser(
          currentUser.id,
          'developer',
        );
        
        print('Checking active offers for listing: ${widget.listingId}');
        print('Found ${negotiations.length} negotiations');
        
        // Find active negotiations for this listing
        final activeNegotiations = negotiations.where((negotiation) => 
          negotiation.listingId == widget.listingId && 
          (negotiation.status == OfferStatus.sent || 
           negotiation.status == OfferStatus.pending ||
           negotiation.status == OfferStatus.countered)).toList();
        
        print('Active negotiations for this listing: ${activeNegotiations.length}');
        
        // Check if we need to get the actual offer details to determine type
        bool hasActiveOffer = false;
        bool hasActiveJV = false;
        
        for (final negotiation in activeNegotiations) {
          // Get the negotiation with messages to check the offer type
          final fullNegotiation = await _negotiationService.getNegotiationWithMessages(negotiation.id);
          if (fullNegotiation != null && fullNegotiation.messages.isNotEmpty) {
            // Check the first message to see if it's an offer or JV
            final firstMessage = fullNegotiation.messages.first;
            if (firstMessage.content.contains('Made an offer of AED')) {
              hasActiveOffer = true;
              print('Found active offer');
            } else if (firstMessage.content.contains('JV Proposal')) {
              hasActiveJV = true;
              print('Found active JV proposal');
            }
          }
        }
        
        print('Has active offer: $hasActiveOffer');
        print('Has active JV: $hasActiveJV');
        
        if (mounted) {
          setState(() {
            _hasActiveOffer = hasActiveOffer;
            _hasActiveJV = hasActiveJV;
            _isCheckingOffers = false;
          });
        }
      }
    } catch (e) {
      print('Error checking active offer: $e');
      if (mounted) {
        setState(() {
          _isCheckingOffers = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => context.go('/dev/browse'),
        ),
        title: Text(
          'Listing Details',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
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
              onPressed: () => context.go('/dev/browse'),
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
          _buildTechnicalSpecs(),
          const SizedBox(height: 20),
          _buildPricingInfo(),
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
    // Check if current developer is preferred for this listing
    final authService = ref.read(authServiceProvider);
    final currentUser = authService.currentUser;
    final isPreferredDeveloper = currentUser != null && 
        _listing!.preferredDeveloperIds.contains(currentUser.uid);
    
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
                if (isPreferredDeveloper) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _showPreferredDeveloperInfo(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.amber, width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.workspace_premium,
                            color: Colors.amber[700],
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Preferred Developer',
                            style: TextStyle(
                              color: Colors.amber[700],
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
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
            _buildInfoRow('Emirate', _listing!.emirate),
            _buildInfoRow('City', _listing!.city),
            _buildInfoRow('Area', _listing!.area),
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
            _buildInfoRow('Land Size', '${_listing!.landSize} sqm'),
            _buildInfoRow('GFA', '${_listing!.gfa} sqm'),
            _buildInfoRow('Ownership Type', _getOwnershipTypeText(_listing!.ownershipType)),
            _buildInfoRow('Listing Type', _getListingTypeText(_listing!.listingType)),
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
          ],
        ),
      ),
    );
  }

  Widget _buildTechnicalSpecs() {
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
                  Icons.engineering,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Technical Specifications',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_listing!.buildingSpecs?.isNotEmpty == true)
              _buildInfoRow('Building Specs', _listing!.buildingSpecs!),
            _buildInfoRow('Listed Date', _formatDate(_listing!.createdAt)),
            _buildInfoRow('Last Updated', _formatDate(_listing!.updatedAt)),
          ],
        ),
      ),
    );
  }


  Widget _buildDocumentItem(String title, IconData icon, String url) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryColor),
      title: Text(title),
      trailing: const Icon(Icons.open_in_new),
      onTap: () async {
        try {
          final Uri uri = Uri.parse(url);
          
          // Try different launch modes
          bool launched = false;
          
          // First try with external application
          if (await canLaunchUrl(uri)) {
            launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
          
          // If that fails, try with platformDefault
          if (!launched) {
            if (await canLaunchUrl(uri)) {
              launched = await launchUrl(uri, mode: LaunchMode.platformDefault);
            }
          }
          
          // If that fails, try with inAppWebView
          if (!launched) {
            if (await canLaunchUrl(uri)) {
              launched = await launchUrl(uri, mode: LaunchMode.inAppWebView);
            }
          }
          
          if (!launched) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Cannot open $title. Please try opening the link manually.'),
                  backgroundColor: AppTheme.errorColor,
                  action: SnackBarAction(
                    label: 'Copy Link',
                    onPressed: () {
                      // TODO: Implement copy to clipboard
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Link copied to clipboard'),
                          backgroundColor: AppTheme.successColor,
                        ),
                      );
                    },
                  ),
                ),
              );
            }
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error opening $title: $e'),
                backgroundColor: AppTheme.errorColor,
              ),
            );
          }
        }
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
            // Make Offer / Cancel Offer button - only show for BUY or BOTH listing types
            if (_listing?.listingType == ListingType.buy || _listing?.listingType == ListingType.both) ...[
              Expanded(
                child: _isCheckingOffers
                    ? OutlinedButton.icon(
                        onPressed: null, // Disabled during loading
                        icon: const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        label: const Text('Checking...'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      )
                    : _hasActiveOffer
                        ? ElevatedButton.icon(
                            onPressed: _isSubmittingOffer ? null : _cancelOffer,
                            icon: _isSubmittingOffer 
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.cancel),
                            label: Text(_isSubmittingOffer ? 'Cancelling...' : 'Cancel Offer'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.errorColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          )
                        : OutlinedButton.icon(
                            onPressed: _isSubmittingOffer ? null : _showOfferDialog,
                            icon: _isSubmittingOffer 
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.mail),
                            label: Text(_isSubmittingOffer ? 'Submitting...' : 'Make Offer'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
              ),
            ],
            // JV Proposal button - only show for JV or BOTH listing types
            if (_listing?.listingType == ListingType.jv || _listing?.listingType == ListingType.both) ...[
              if (_listing?.listingType == ListingType.both) const SizedBox(width: 12),
              Expanded(
                child: _isCheckingOffers
                    ? ElevatedButton.icon(
                        onPressed: null, // Disabled during loading
                        icon: const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                        label: const Text('Checking...'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      )
                    : _hasActiveJV
                        ? ElevatedButton.icon(
                            onPressed: _isSubmittingJV ? null : _cancelJVOffer,
                            icon: _isSubmittingJV 
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.cancel),
                            label: Text(_isSubmittingJV ? 'Cancelling...' : 'Cancel JV'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.errorColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          )
                        : ElevatedButton.icon(
                            onPressed: _isSubmittingJV ? null : _showJVDialog,
                            icon: _isSubmittingJV 
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.handshake),
                            label: Text(_isSubmittingJV ? 'Submitting...' : 'JV Proposal'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
              ),
            ],
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

  Future<void> _cancelOffer() async {
    try {
      setState(() {
        _isSubmittingOffer = true;
      });
      
      final authService = ref.read(authServiceProvider);
      final currentUser = await authService.getCurrentUser();
      
      if (currentUser != null) {
        // Find the active negotiation for this listing
        final negotiations = await _negotiationService.getNegotiationsForUser(
          currentUser.id,
          'developer',
        );
        
        final activeNegotiation = negotiations.firstWhere(
          (negotiation) => 
            negotiation.listingId == widget.listingId && 
            (negotiation.status == OfferStatus.sent || 
             negotiation.status == OfferStatus.pending ||
             negotiation.status == OfferStatus.countered),
          orElse: () => throw Exception('No active offer found'),
        );
        
        // Update negotiation status to rejected
        await _negotiationService.updateNegotiationStatus(
          activeNegotiation.id,
          OfferStatus.rejected,
        );
        
        // Get developer profile to use company name
        final developerProfile = await authService.getDeveloperProfile(currentUser.id);
        final developerName = developerProfile?.companyName ?? currentUser.name;

        // Add cancellation message
        await _negotiationService.sendMessage(
          negotiationId: activeNegotiation.id,
          senderId: currentUser.id,
          senderName: developerName,
          senderRole: 'developer',
          content: 'Offer cancelled by developer',
        );
        
        if (mounted) {
          setState(() {
            _hasActiveOffer = false;
            _isSubmittingOffer = false;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Offer cancelled successfully'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        }
      }
    } catch (e) {
      print('Error cancelling offer: $e');
      if (mounted) {
        setState(() {
          _isSubmittingOffer = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error cancelling offer: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _cancelJVOffer() async {
    try {
      setState(() {
        _isSubmittingJV = true;
      });
      
      final authService = ref.read(authServiceProvider);
      final currentUser = await authService.getCurrentUser();
      
      if (currentUser != null) {
        // Find the active JV negotiation for this listing
        final negotiations = await _negotiationService.getNegotiationsForUser(
          currentUser.id,
          'developer',
        );
        
        final activeJVNegotiation = negotiations.firstWhere(
          (negotiation) => 
            negotiation.listingId == widget.listingId && 
            (negotiation.status == OfferStatus.sent || 
             negotiation.status == OfferStatus.pending ||
             negotiation.status == OfferStatus.countered),
          orElse: () => throw Exception('No active JV offer found'),
        );
        
        // Update negotiation status to rejected
        await _negotiationService.updateNegotiationStatus(
          activeJVNegotiation.id,
          OfferStatus.rejected,
        );
        
        // Get developer profile to use company name
        final developerProfile = await authService.getDeveloperProfile(currentUser.id);
        final developerName = developerProfile?.companyName ?? currentUser.name;

        // Add cancellation message
        await _negotiationService.sendMessage(
          negotiationId: activeJVNegotiation.id,
          senderId: currentUser.id,
          senderName: developerName,
          senderRole: 'developer',
          content: 'JV Proposal cancelled by developer',
        );
        
        if (mounted) {
          setState(() {
            _hasActiveJV = false;
            _isSubmittingJV = false;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('JV Proposal cancelled successfully'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        }
      }
    } catch (e) {
      print('Error cancelling JV offer: $e');
      if (mounted) {
        setState(() {
          _isSubmittingJV = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error cancelling JV offer: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Widget _buildOfferDialog() {
    final askingPrice = _listing?.askingPrice ?? 0;
    final minPrice = askingPrice * 0.8; // 20% below asking price
    final maxPrice = askingPrice * 1.2; // 20% above asking price
    
    return AlertDialog(
      title: const Text('Make Offer'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Offer must be within ±20% of asking price',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Asking Price: AED ${_formatPrice(askingPrice)}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Valid Range: AED ${_formatPrice(minPrice)} - AED ${_formatPrice(maxPrice)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _offerAmountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Offer Amount',
                prefixText: 'AED ',
                border: OutlineInputBorder(),
                hintText: 'Enter your offer amount',
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
            Text(
              'Partnership percentages must sum to 100%',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _jvEquityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Landowner Percentage',
                suffixText: '%',
                border: OutlineInputBorder(),
                hintText: 'e.g., 40',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _jvInvestmentController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Developer Percentage',
                suffixText: '%',
                border: OutlineInputBorder(),
                hintText: 'e.g., 60',
              ),
            ),
            const SizedBox(height: 8),
            Builder(
              builder: (context) {
                final landownerPercent = double.tryParse(_jvEquityController.text) ?? 0;
                final developerPercent = double.tryParse(_jvInvestmentController.text) ?? 0;
                final total = landownerPercent + developerPercent;
                
                return Text(
                  'Total: ${total.toStringAsFixed(1)}%',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: total == 100 ? AppTheme.successColor : AppTheme.errorColor,
                    fontWeight: FontWeight.w600,
                  ),
                );
              },
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

    // Validate offer amount is within ±20% of asking price
    final offerAmount = double.parse(_offerAmountController.text.trim());
    final askingPrice = _listing?.askingPrice ?? 0;
    final minPrice = askingPrice * 0.8;
    final maxPrice = askingPrice * 1.2;
    
    if (offerAmount < minPrice || offerAmount > maxPrice) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Offer must be between AED ${_formatPrice(minPrice)} and AED ${_formatPrice(maxPrice)}'),
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
        buyPrice: offerAmount,
        status: OfferStatus.pending,
        notes: '', // No notes allowed
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Save offer to Firebase
      print('Creating offer...');
      await _offerService.createOffer(offer);
      print('Offer created successfully');

      // Get developer profile to use company name
      print('=== DEBUG: Getting developer profile for user: ${currentUser.id}');
      final developerProfile = await authService.getDeveloperProfile(currentUser.id);
      print('Developer profile: ${developerProfile?.companyName}');
      print('Developer profile is null: ${developerProfile == null}');
      print('Current user name: ${currentUser.name}');
      final developerName = developerProfile?.companyName ?? currentUser.name;
      print('Using developer name: $developerName');

      // Create negotiation thread
      print('Creating negotiation...');
      final negotiationId = await _negotiationService.createNegotiation(
        listingId: widget.listingId,
        developerId: currentUser.id,
        developerName: developerName,
        listingTitle: '${_listing!.emirate}, ${_listing!.city}',
        sellerId: _listing!.sellerId,
        sellerName: 'Property Owner', // Don't reveal seller name to developers
      );
      print('Negotiation created with ID: $negotiationId');

      // Add offer message to negotiation
      print('Sending message to negotiation...');
      await _negotiationService.sendMessage(
        negotiationId: negotiationId,
        senderId: currentUser.id,
        senderName: developerName,
        senderRole: 'developer',
        content: 'Made an offer of AED ${_formatPrice(offerAmount)}',
      );
      print('Message sent successfully');

      // Send notification to seller
      print('Sending notification to seller...');
      await NotificationService().notifyOfferReceived(
        sellerId: _listing!.sellerId,
        developerName: developerName,
        listingTitle: '${_listing!.emirate}, ${_listing!.city}',
        offerId: offer.id,
      );
      print('Notification sent successfully');

        if (mounted) {
          setState(() {
            _hasActiveOffer = true;
            _isSubmittingOffer = false;
          });
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
        setState(() {
          _isSubmittingOffer = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting offer: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
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

    // Parse JV percentages
    final landownerPercentage = double.parse(_jvEquityController.text.trim());
    final developerPercentage = double.parse(_jvInvestmentController.text.trim());
    
    // Validate percentages sum to 100%
    if (landownerPercentage + developerPercentage != 100.0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Partnership percentages must sum to 100%'),
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

      // Create JV proposal
      final jvProposal = JVProposal(
        sellerPercentage: landownerPercentage,
        developerPercentage: developerPercentage,
        investmentAmount: 0, // Not used in percentage-only JV
        notes: '', // No notes allowed
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
        notes: '', // No notes allowed
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Save offer to Firebase
      print('Creating JV offer...');
      await _offerService.createOffer(offer);
      print('JV offer created successfully');

      // Get developer profile to use company name
      print('=== DEBUG: Getting developer profile for JV user: ${currentUser.id}');
      final developerProfile = await authService.getDeveloperProfile(currentUser.id);
      print('Developer profile: ${developerProfile?.companyName}');
      print('Developer profile is null: ${developerProfile == null}');
      print('Current user name: ${currentUser.name}');
      final developerName = developerProfile?.companyName ?? currentUser.name;
      print('Using developer name for JV: $developerName');

      // Create negotiation thread
      print('Creating JV negotiation...');
      final negotiationId = await _negotiationService.createNegotiation(
        listingId: widget.listingId,
        developerId: currentUser.id,
        developerName: developerName,
        listingTitle: '${_listing!.emirate}, ${_listing!.city}',
        sellerId: _listing!.sellerId,
        sellerName: 'Property Owner', // Don't reveal seller name to developers
      );
      print('JV negotiation created with ID: $negotiationId');

      // Add JV proposal message to negotiation
      print('Sending JV message to negotiation...');
      await _negotiationService.sendMessage(
        negotiationId: negotiationId,
        senderId: currentUser.id,
        senderName: developerName,
        senderRole: 'developer',
        content: 'JV Proposal: ${landownerPercentage.toInt()}% Landowner, ${developerPercentage.toInt()}% Developer',
      );
      print('JV message sent successfully');

      // Send notification to seller
      print('Sending JV notification to seller...');
      await NotificationService().notifyOfferReceived(
        sellerId: _listing!.sellerId,
        developerName: developerName,
        listingTitle: '${_listing!.emirate}, ${_listing!.city}',
        offerId: offer.id,
      );
      print('JV notification sent successfully');

      if (mounted) {
        setState(() {
          _hasActiveJV = true;
          _isSubmittingJV = false;
        });
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
        setState(() {
          _isSubmittingJV = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting JV proposal: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
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

  String _getOwnershipTypeText(OwnershipType ownershipType) {
    switch (ownershipType) {
      case OwnershipType.freehold:
        return 'Freehold';
      case OwnershipType.leasehold:
        return 'Leasehold';
      case OwnershipType.gcc:
        return 'GCC National';
    }
  }

  String _getListingTypeText(ListingType listingType) {
    switch (listingType) {
      case ListingType.buy:
        return 'Buy';
      case ListingType.jv:
        return 'Joint Venture';
      case ListingType.both:
        return 'Buy or Joint Venture';
    }
  }

  void _showPreferredDeveloperInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.workspace_premium,
              color: Colors.amber[700],
              size: 24,
            ),
            const SizedBox(width: 8),
            const Text('Preferred Developer'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Congratulations! You have been selected as a preferred developer for this listing.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'What this means:',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.amber[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• The seller has specifically chosen you for this project',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}
