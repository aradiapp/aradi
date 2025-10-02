import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:aradi/app/theme/app_theme.dart';
import 'package:aradi/core/models/developer_profile.dart';
import 'package:aradi/core/models/land_listing.dart';
import 'package:aradi/core/services/matching_service.dart';
import 'package:aradi/core/services/auth_service.dart';
import 'package:aradi/core/services/land_listing_service.dart';
import 'package:aradi/app/providers/data_providers.dart';

class DevHomePage extends ConsumerStatefulWidget {
  const DevHomePage({super.key});

  @override
  ConsumerState<DevHomePage> createState() => _DevHomePageState();
}

class _DevHomePageState extends ConsumerState<DevHomePage> {
  List<LandListing> _filteredListings = [];
  final LandListingService _landListingService = LandListingService();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // Get current user
      final authService = ref.read(authServiceProvider);
      final currentUser = await authService.getCurrentUser();
      
      if (currentUser != null) {
        // Get developer profile
        final developerProfile = await ref.read(developerProfileProvider(currentUser.id).future);
        
        if (developerProfile != null) {
          // Get active listings using new service
          final listings = await _landListingService.getActiveListings();
          
          // Sort by matching score
          final sortedListings = MatchingService.sortByMatchingScore(listings, developerProfile);
          
          setState(() {
            _filteredListings = sortedListings;
          });
        }
      }
      
    } catch (e) {
      print('Error loading data: $e');
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Stats Header
              Consumer(
                builder: (context, ref, child) {
                  final authState = ref.watch(authStateProvider);
                  return authState.when(
                    data: (user) {
                      if (user != null) {
                        final developerProfile = ref.watch(developerProfileProvider(user.id));
                        return developerProfile.when(
                          data: (profile) => profile != null ? _buildStatsHeader(profile) : const SizedBox.shrink(),
                          loading: () => const Center(child: CircularProgressIndicator()),
                          error: (error, stack) => const SizedBox.shrink(),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (error, stack) => const SizedBox.shrink(),
                  );
                },
              ),
              const SizedBox(height: 24),
              
              // Filters
              const SizedBox(height: 24),
              
              // Listings Feed
              Consumer(
                builder: (context, ref, child) {
                  final listingsAsync = ref.watch(allListingsProvider);
                  return listingsAsync.when(
                    data: (listings) => _buildListingsFeed(listings),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (error, stack) => Center(
                      child: Text('Error loading listings: $error'),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsHeader(DeveloperProfile profile) {
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
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                  child: Icon(
                    Icons.business,
                    size: 30,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.companyName,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        '${profile.businessModel.toString().split('.').last} Developer',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _StatPill(
                    icon: Icons.check_circle,
                    label: 'Delivered',
                    value: profile.deliveredProjects.toString(),
                    color: AppTheme.successColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatPill(
                    icon: Icons.construction,
                    label: 'Under Construction',
                    value: profile.underConstruction.toString(),
                    color: AppTheme.warningColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatPill(
                    icon: Icons.pending,
                    label: 'Pipeline',
                    value: profile.landsInPipeline.toString(),
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatPill(
                    icon: Icons.people,
                    label: 'Team Size',
                    value: profile.teamSize.toString(),
                    color: AppTheme.secondaryColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildListingsFeed(List<LandListing> listings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Land Listings',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            Text(
              '${listings.length} listings',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (listings.isEmpty)
          _EmptyState(
            icon: Icons.search_off,
            title: 'No Listings Found',
            subtitle: 'Try adjusting your filters or check back later',
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: listings.length,
            itemBuilder: (context, index) {
              final listing = listings[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _LandListingCard(
                  listing: listing,
                  onTap: () => context.go('/dev/listing/${listing.id}'),
                ),
              );
            },
          ),
      ],
    );
  }
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatPill({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}


class _LandListingCard extends StatelessWidget {
  final LandListing listing;
  final VoidCallback onTap;

  const _LandListingCard({
    required this.listing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
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
                          listing.location,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          listing.area,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (listing.matchingScore != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${listing.matchingScore!.toStringAsFixed(0)}%',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.primaryColor,
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
                    ),
                  ),
                  Expanded(
                    child: _InfoRow(
                      icon: Icons.business,
                      label: 'GFA',
                      value: '${listing.gfa.toStringAsFixed(0)} sqm',
                    ),
                  ),
                  Expanded(
                    child: _InfoRow(
                      icon: Icons.attach_money,
                      label: 'Price',
                      value: 'AED ${(listing.askingPrice / 1000000).toStringAsFixed(1)}M',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: listing.permissions.map((permission) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.secondaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      permission.toString().split('.').last,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          icon,
          size: 20,
          color: AppTheme.textSecondary,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.textSecondary,
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
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
