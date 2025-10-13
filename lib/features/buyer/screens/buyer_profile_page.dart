import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:aradi/app/theme/app_theme.dart';
import 'package:aradi/app/providers/data_providers.dart';
import 'package:aradi/core/models/buyer_profile.dart';
import 'package:aradi/core/models/land_listing.dart';
import 'package:aradi/core/services/land_listing_service.dart';

class BuyerProfilePage extends ConsumerStatefulWidget {
  const BuyerProfilePage({super.key});

  @override
  ConsumerState<BuyerProfilePage> createState() => _BuyerProfilePageState();
}

class _BuyerProfilePageState extends ConsumerState<BuyerProfilePage> {
  List<LandListing> _myListings = [];
  bool _isLoadingListings = true;
  final LandListingService _landListingService = LandListingService();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (mounted) {
      setState(() {
        _isLoadingListings = true;
      });
    }

    try {
      // Load all active listings that buyers can see
      final allListings = await _landListingService.getActiveListings();
      
      // Filter out JV-only listings for buyers
      _myListings = allListings.where((listing) => 
        listing.isActive && 
        listing.listingType != ListingType.jv
      ).toList();
    } catch (e) {
      print('Error loading buyer data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingListings = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserAsync = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Buyer Profile'),
        backgroundColor: AppTheme.primaryLight,
        foregroundColor: Colors.white,
        leading: IconButton(
          onPressed: () {
            context.push('/buyer/profile/edit');
          },
          icon: const Icon(Icons.edit),
          tooltip: 'Edit Profile',
        ),
        actions: [
          IconButton(
            onPressed: () async {
              final authService = ref.read(authServiceProvider);
              await authService.signOut();
              // Small delay to ensure auth state change is processed
              await Future.delayed(const Duration(milliseconds: 100));
              if (context.mounted) {
                context.go('/auth');
              }
            },
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
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
          final buyerProfileAsync = ref.watch(buyerProfileProvider(user.id));
          return buyerProfileAsync.when(
            data: (profile) {
              if (profile == null) {
                return const Center(
                  child: Text('No buyer profile found. Please complete your KYC first.'),
                );
              }
              return _buildProfileContent(context, profile);
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

  Widget _buildProfileContent(BuildContext context, BuyerProfile profile) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProfileHeader(context, profile),
          const SizedBox(height: 24),
          _buildMarketStats(context),
          const SizedBox(height: 24),
          _buildPersonalInfo(context, profile),
          const SizedBox(height: 24),
          _buildPreferences(context, profile),
          const SizedBox(height: 24),
          _buildSubscriptionInfo(context, profile),
        ],
      ),
    );
  }

  Widget _buildMarketStats(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Market Overview',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            const Divider(),
            if (_isLoadingListings)
              const Center(child: CircularProgressIndicator())
            else
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      context,
                      'Available Listings',
                      _myListings.length.toString(),
                      Icons.home_work,
                      AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      context,
                      'Average Price',
                      _calculateAveragePrice(),
                      Icons.attach_money,
                      AppTheme.successColor,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  String _calculateAveragePrice() {
    if (_myListings.isEmpty) return 'N/A';
    final total = _myListings.fold<double>(0, (sum, listing) => sum + listing.askingPrice);
    final average = total / _myListings.length;
    return 'AED ${(average / 1000000).toStringAsFixed(0)}M';
  }

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
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
    );
  }

  Widget _buildProfileHeader(BuildContext context, BuyerProfile profile) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: AppTheme.secondaryColor.withOpacity(0.1),
              child: const Icon(Icons.person, size: 40, color: AppTheme.secondaryColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                  ),
                  Text(
                    profile.email,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                  ),
                  Text(
                    profile.phone,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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

  Widget _buildPersonalInfo(BuildContext context, BuyerProfile profile) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Personal Information',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
            ),
            const Divider(),
            _buildDetailRow(context, 'Name:', profile.name),
            _buildDetailRow(context, 'Email:', profile.email),
            _buildDetailRow(context, 'Phone:', profile.phone),
            _buildImageField(context, 'Passport:', profile.passport),
          ],
        ),
      ),
    );
  }

  Widget _buildPreferences(BuildContext context, BuyerProfile profile) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Preferences',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
            ),
            const Divider(),
            _buildDetailRow(context, 'Areas Interested:', profile.areasInterested.join(', ')),
            if (profile.gfaRange != null)
              _buildDetailRow(context, 'GFA Range:', '${profile.gfaRange!['min']} - ${profile.gfaRange!['max']} sqft'),
            if (profile.budgetRange != null)
              _buildDetailRow(context, 'Budget Range:', 'AED ${profile.budgetRange!['min']} - AED ${profile.budgetRange!['max']}'),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionInfo(BuildContext context, BuyerProfile profile) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Subscription',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
            ),
            const Divider(),
            _buildDetailRow(context, 'Status:', profile.hasActiveSubscription ? 'Active' : 'Inactive'),
            if (profile.subscriptionExpiry != null)
              _buildDetailRow(context, 'Expires:', profile.subscriptionExpiry!.toLocal().toString().split(' ')[0]),
            _buildDetailRow(context, 'Bought Land Count:', profile.boughtLandCount.toString()),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimary,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageField(BuildContext context, String label, String imageUrl) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary,
                ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey.shade100,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error, color: Colors.grey.shade400),
                        const SizedBox(height: 8),
                        Text(
                          'Failed to load image',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'URL: ${imageUrl.length > 50 ? '${imageUrl.substring(0, 50)}...' : imageUrl}',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}