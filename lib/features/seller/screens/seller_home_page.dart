import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:aradi/app/theme/app_theme.dart';
import 'package:aradi/core/models/land_listing.dart';
import 'package:aradi/core/models/offer.dart';
import 'package:aradi/core/models/negotiation.dart';
import 'package:aradi/core/services/land_listing_service.dart';
import 'package:aradi/core/services/offer_service.dart';
import 'package:aradi/core/services/negotiation_service.dart';
import 'package:aradi/core/services/auth_service.dart';
import 'package:aradi/app/providers/data_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SellerHomePage extends ConsumerStatefulWidget {
  const SellerHomePage({super.key});

  @override
  ConsumerState<SellerHomePage> createState() => _SellerHomePageState();
}

class _SellerHomePageState extends ConsumerState<SellerHomePage> {
  List<LandListing> _myListings = [];
  List<Offer> _offers = [];
  List<Negotiation> _negotiations = [];
  bool _isLoading = true;
  final LandListingService _landListingService = LandListingService();
  final OfferService _offerService = OfferService();
  final NegotiationService _negotiationService = NegotiationService();
  
  // Track negotiation status for each listing
  Map<String, String> _listingNegotiationStatus = {};

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
      // Get current user
      final authService = ref.read(authServiceProvider);
      final currentUser = await authService.getCurrentUser();
      
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Load seller's listings (exclude rejected ones)
      final allListings = await _landListingService.getListingsBySeller(currentUser.id);
      _myListings = allListings.where((listing) => listing.status != ListingStatus.rejected).toList();

      // Check negotiation status for each listing
      await _checkNegotiationStatus();

      // Load negotiations for seller's listings (replacing old offers system)
      _negotiations = await _negotiationService.getNegotiationsForUser(currentUser.id, 'seller');
      
      
      // Convert negotiations to offers for compatibility with existing UI
      _offers = _negotiations.map((negotiation) => Offer(
        id: negotiation.id,
        listingId: negotiation.listingId,
        developerId: negotiation.developerId,
        developerName: negotiation.developerName,
        type: OfferType.buy, // Default type, could be determined from negotiation content
        status: negotiation.status,
        notes: '',
        createdAt: negotiation.createdAt,
        updatedAt: negotiation.updatedAt,
      )).toList();
    } catch (e) {
      print('Error loading data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: $e'),
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

  Future<void> _checkNegotiationStatus() async {
    try {
      final authService = ref.read(authServiceProvider);
      final currentUser = await authService.getCurrentUser();
      
      if (currentUser == null) return;

      final negotiations = await _negotiationService.getNegotiationsForUser(currentUser.id, 'seller');
      
      for (final listing in _myListings) {
        // Check if listing has accepted negotiations (same logic as listing details page)
        final hasAccepted = negotiations.any((n) => n.listingId == listing.id && n.status.toString().contains('accepted'));
        
        if (hasAccepted) {
          // Check if it's a JV proposal
          final acceptedNegotiation = negotiations.firstWhere((n) => n.listingId == listing.id && n.status.toString().contains('accepted'));
          final isJV = acceptedNegotiation.messages.any((message) => 
            message.content.contains('JV Proposal') || 
            message.content.contains('% Landowner') ||
            message.content.contains('% Developer'));
          
          _listingNegotiationStatus[listing.id] = isJV ? 'Admin will contact you' : 'Pending Admin';
        } else {
          // No accepted negotiations, use normal listing status
          if (listing.status == ListingStatus.sold) {
            _listingNegotiationStatus[listing.id] = 'Sold';
          } else if (listing.isVerified) {
            _listingNegotiationStatus[listing.id] = 'Active';
          } else {
            _listingNegotiationStatus[listing.id] = 'Pending';
          }
        }
      }
    } catch (e) {
      print('Error checking negotiation status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome Header
                    _buildWelcomeHeader(),
                    const SizedBox(height: 24),
                    
                    // Quick Stats
                    _buildQuickStats(),
                    const SizedBox(height: 24),
                    
                    // My Listings
                    _buildMyListings(),
                    const SizedBox(height: 24),
                    
                    // Recent Offers
                    _buildRecentOffers(),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/seller/land/add'),
        icon: const Icon(Icons.add),
        label: const Text('Add Listing'),
        backgroundColor: AppTheme.accentColor,
      ),
    );
  }

  Widget _buildWelcomeHeader() {
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
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppTheme.accentColor.withOpacity(0.1),
                  child: Icon(
                    Icons.sell,
                    size: 30,
                    color: AppTheme.accentColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
          child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome Back!',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        'Manage your land listings and offers',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppTheme.accentColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: Container(
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
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Connect with developers and negotiate the best deals for your land',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    final activeListings = _myListings.where((l) => l.isActive).length;
    final pendingOffers = _offers.where((o) => 
      o.status == OfferStatus.sent || o.status == OfferStatus.pending || o.status == OfferStatus.countered).length;
    final totalValue = _myListings.fold<double>(0, (sum, listing) => sum + listing.askingPrice);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Overview',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _QuickStatCard(
                icon: Icons.list_alt,
                title: 'Active Listings',
                value: activeListings.toString(),
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _QuickStatCard(
                icon: Icons.mail,
                title: 'Pending Offers',
                value: pendingOffers.toString(),
                color: AppTheme.warningColor,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _QuickStatCard(
                icon: Icons.attach_money,
                title: 'Total Value',
                value: 'AED ${(totalValue / 1000000).toStringAsFixed(0)}M',
                color: AppTheme.successColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMyListings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
              Text(
              'My Listings',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
              ),
            ),
            TextButton(
              onPressed: () => context.go('/seller/land/add'),
              child: const Text('Add New'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_myListings.isEmpty)
          _EmptyState(
            icon: Icons.add_location,
            title: 'No Listings Yet',
            subtitle: 'Add your first land listing to start connecting with developers',
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _myListings.length,
            itemBuilder: (context, index) {
              final listing = _myListings[index];
              final listingOffers = _offers.where((o) => o.listingId == listing.id).toList();
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _ListingCard(
                  listing: listing,
                  offerCount: listingOffers.length,
                  negotiationStatus: _listingNegotiationStatus[listing.id] ?? 'Active',
                  onTap: () => context.go('/seller/listing/${listing.id}'),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildRecentOffers() {
    // Sort offers by creation date (most recent first) and take top 3
    // Show all offers except rejected ones for recent offers section
    final recentOffers = _offers
        .where((offer) => offer.status != OfferStatus.rejected)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final topOffers = recentOffers.take(3).toList();
    
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Offers',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            if (_offers.length > 3)
              TextButton(
                onPressed: () => context.go('/seller/negotiations'),
                child: const Text('View All'),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (topOffers.isEmpty)
          _EmptyState(
            icon: Icons.mail_outline,
            title: 'No Offers Yet',
            subtitle: 'Offers from developers will appear here',
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: topOffers.length,
            itemBuilder: (context, index) {
              final offer = topOffers[index];
              final listing = _myListings.firstWhere((l) => l.id == offer.listingId);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _OfferCard(
                  offer: offer,
                  listing: listing,
                  onTap: () => context.go('/seller/negotiations'),
                ),
              );
            },
          ),
      ],
    );
  }


  void _showListingDetails(BuildContext context, LandListing listing, List<Offer> offers) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.textSecondary.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Text(
                      '${listing.emirate}, ${listing.city}',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
              Text(
                      listing.area,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Status
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: listing.isActive 
                            ? AppTheme.successColor.withOpacity(0.1)
                            : AppTheme.warningColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        listing.status.toString().split('.').last.toUpperCase(),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: listing.isActive 
                              ? AppTheme.successColor
                              : AppTheme.warningColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Details
                    _DetailRow(
                      icon: Icons.square_foot,
                      label: 'Land Size',
                      value: '${listing.landSize.toStringAsFixed(0)} sqm',
                    ),
                    _DetailRow(
                      icon: Icons.business,
                      label: 'GFA',
                      value: '${listing.gfa.toStringAsFixed(0)} sqm',
                    ),
                    _DetailRow(
                      icon: Icons.attach_money,
                      label: 'Asking Price',
                      value: 'AED ${(listing.askingPrice / 1000000).toStringAsFixed(2)}M',
                    ),
                    _DetailRow(
                      icon: Icons.mail,
                      label: 'Offers Received',
                      value: offers.length.toString(),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Offers
                    if (offers.isNotEmpty) ...[
                      Text(
                        'Offers',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...offers.map((offer) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _OfferCard(
                          offer: offer,
                          listing: listing,
                          onTap: () {
                            Navigator.of(context).pop();
                            context.go('/neg/thread/${offer.id}');
                          },
                        ),
                      )),
                    ],
                    
                    const SizedBox(height: 30),
                    
                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Close',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              context.go('/seller/developers');
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Browse Developers',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickStatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _QuickStatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: color,
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ListingCard extends StatelessWidget {
  final LandListing listing;
  final int offerCount;
  final String negotiationStatus;
  final VoidCallback onTap;

  const _ListingCard({
    required this.listing,
    required this.offerCount,
    required this.negotiationStatus,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          // Background image
          if (listing.photoUrls.isNotEmpty)
            Container(
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                image: DecorationImage(
                  image: NetworkImage(listing.photoUrls.first),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          // Semi-transparent overlay
          if (listing.photoUrls.isNotEmpty)
            Container(
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.black.withOpacity(0.3),
              ),
            ),
          // Content
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
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
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: listing.photoUrls.isNotEmpty ? Colors.white : AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          listing.area,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: listing.photoUrls.isNotEmpty ? Colors.white.withOpacity(0.9) : AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(negotiationStatus),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      negotiationStatus,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: _getStatusTextColor(negotiationStatus),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _InfoRow(
                      icon: Icons.square_foot,
                      label: 'Land Size',
                      value: '${listing.landSize.toStringAsFixed(0)} sqm',
                      textColor: listing.photoUrls.isNotEmpty ? Colors.white : null,
                    ),
                  ),
                  Expanded(
                    child: _InfoRow(
                      icon: Icons.attach_money,
                      label: 'Price',
                      value: 'AED ${(listing.askingPrice / 1000000).toStringAsFixed(2)}M',
                      textColor: listing.photoUrls.isNotEmpty ? Colors.white : null,
                    ),
                  ),
                  Expanded(
                    child: _InfoRow(
                      icon: Icons.mail,
                      label: 'Offers',
                      value: offerCount.toString(),
                      textColor: listing.photoUrls.isNotEmpty ? Colors.white : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Active':
        return AppTheme.successColor.withOpacity(0.1);
      case 'Pending':
        return AppTheme.warningColor.withOpacity(0.1);
      case 'Pending Admin':
        return AppTheme.primaryColor.withOpacity(0.1);
      case 'Admin will contact you':
        return Colors.purple.withOpacity(0.1);
      case 'Sold':
        return Colors.grey.withOpacity(0.1);
      default:
        return AppTheme.warningColor.withOpacity(0.1);
    }
  }

  Color _getStatusTextColor(String status) {
    switch (status) {
      case 'Active':
        return AppTheme.successColor;
      case 'Pending':
        return AppTheme.warningColor;
      case 'Pending Admin':
        return AppTheme.primaryColor;
      case 'Admin will contact you':
        return Colors.purple;
      case 'Sold':
        return Colors.grey;
      default:
        return AppTheme.warningColor;
    }
  }
}

class _OfferCard extends StatelessWidget {
  final Offer offer;
  final LandListing listing;
  final VoidCallback onTap;

  const _OfferCard({
    required this.offer,
    required this.listing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                child: Icon(
                  offer.type == OfferType.buy ? Icons.shopping_cart : Icons.handshake,
                  size: 20,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      offer.developerName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      '${listing.emirate}, ${listing.city}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    if (offer.buyPrice != null)
                      Text(
                        'AED ${(offer.buyPrice! / 1000000).toStringAsFixed(1)}M',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.successColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(offer.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  offer.status.toString().split('.').last,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: _getStatusColor(offer.status),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(OfferStatus status) {
    switch (status) {
      case OfferStatus.sent:
        return AppTheme.warningColor;
      case OfferStatus.pending:
        return AppTheme.warningColor;
      case OfferStatus.countered:
        return AppTheme.primaryColor;
      case OfferStatus.accepted:
        return AppTheme.successColor;
      case OfferStatus.rejected:
        return AppTheme.errorColor;
      case OfferStatus.completed:
        return AppTheme.successColor;
    }
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? textColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          icon,
          size: 20,
          color: textColor ?? AppTheme.textSecondary,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: textColor ?? AppTheme.textSecondary,
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: textColor ?? AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(
            icon,
            size: 24,
            color: AppTheme.textSecondary,
          ),
          const SizedBox(width: 16),
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
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(
              icon,
              size: 64,
              color: AppTheme.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
