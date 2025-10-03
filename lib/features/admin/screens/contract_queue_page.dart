import 'package:flutter/material.dart';
import 'package:aradi/core/models/land_listing.dart';
import 'package:aradi/core/models/developer_profile.dart';
import 'package:aradi/core/models/deal.dart';
import 'package:aradi/core/models/subscription.dart';
import 'package:aradi/app/theme/app_theme.dart';

class ContractQueuePage extends StatefulWidget {
  const ContractQueuePage({super.key});

  @override
  State<ContractQueuePage> createState() => _ContractQueuePageState();
}

class _ContractQueuePageState extends State<ContractQueuePage> {
  List<LandListing> _pendingListings = [];
  List<DeveloperProfile> _pendingDevelopers = [];
  List<Deal> _pendingDeals = [];
  bool _isLoading = true;
  String _selectedTab = 'listings';

  @override
  void initState() {
    super.initState();
    _loadPendingItems();
  }

  void _loadPendingItems() async {
    setState(() {
      _isLoading = true;
    });

    await Future.delayed(const Duration(milliseconds: 500));
    
    _pendingListings = _createMockPendingListings();
    _pendingDevelopers = _createMockPendingDevelopers();
    _pendingDeals = _createMockPendingDeals();
    
    setState(() {
      _isLoading = false;
    });
  }

  List<LandListing> _createMockPendingListings() {
    return [
      LandListing(
        id: 'listing_1',
        sellerId: 'seller_1',
        sellerName: 'Fatima Al Zahra',
        landSize: 5000.0,
        gfa: 15000.0,
        location: 'Dubai Marina',
        area: 'Dubai Marina',
        askingPrice: 25000000.0,
        ownershipType: OwnershipType.freehold,
        permissions: [PermissionType.residential, PermissionType.commercial],
        photoUrls: ['https://example.com/photo1.jpg'],
        status: ListingStatus.pending_verification,
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        updatedAt: DateTime.now().subtract(const Duration(days: 5)),
        title: 'Premium Marina Land Plot',
        description: 'Prime location land plot in Dubai Marina with excellent development potential',
        city: 'Dubai',
        state: 'Dubai',
        zipCode: '00000',
        developmentPermissions: ['Residential', 'Commercial'],
        zoning: 'Mixed Use',
      ),
      LandListing(
        id: 'listing_2',
        sellerId: 'seller_2',
        sellerName: 'Ahmed Al Mansouri',
        landSize: 3000.0,
        gfa: 9000.0,
        location: 'Business Bay',
        area: 'Business Bay',
        askingPrice: 18000000.0,
        ownershipType: OwnershipType.freehold,
        permissions: [PermissionType.commercial],
        photoUrls: ['https://example.com/photo2.jpg'],
        status: ListingStatus.pending_verification,
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        updatedAt: DateTime.now().subtract(const Duration(days: 3)),
        title: 'Business Bay Commercial Plot',
        description: 'Prime commercial land in Business Bay with excellent connectivity',
        city: 'Dubai',
        state: 'Dubai',
        zipCode: '00000',
        developmentPermissions: ['Commercial'],
        zoning: 'Commercial',
      ),
    ];
  }

  List<DeveloperProfile> _createMockPendingDevelopers() {
    return [
      DeveloperProfile(
        id: 'dev_1',
        userId: 'user_1',
        companyName: 'Dubai Properties',
        companyEmail: 'info@dubaiproperties.ae',
        companyPhone: '+971501234567',
        tradeLicense: 'TL123456',
        signatoryPassport: 'P123456',
        businessModel: BusinessModel.business,
        areasInterested: ['Dubai Marina', 'Business Bay'],
        deliveredProjects: 15,
        underConstruction: 3,
        landsInPipeline: 5,
        teamSize: 50,
        freeYearStart: DateTime.now(),
        createdAt: DateTime.now().subtract(const Duration(days: 7)),
        updatedAt: DateTime.now().subtract(const Duration(days: 7)),
        isVerified: false,
      ),
      DeveloperProfile(
        id: 'dev_2',
        userId: 'user_2',
        companyName: 'Emaar Properties',
        companyEmail: 'info@emaar.ae',
        companyPhone: '+971502345678',
        tradeLicense: 'TL234567',
        signatoryPassport: 'P234567',
        businessModel: BusinessModel.business,
        areasInterested: ['Palm Jumeirah', 'Downtown Dubai'],
        deliveredProjects: 25,
        underConstruction: 5,
        landsInPipeline: 8,
        teamSize: 100,
        freeYearStart: DateTime.now(),
        createdAt: DateTime.now().subtract(const Duration(days: 4)),
        updatedAt: DateTime.now().subtract(const Duration(days: 4)),
        isVerified: false,
      ),
    ];
  }

  List<Deal> _createMockPendingDeals() {
    return [
      Deal(
        id: 'deal_1',
        listingId: 'listing_3',
        listingTitle: 'Luxury Villa Plot - Palm Jumeirah',
        sellerId: 'seller_3',
        sellerName: 'Sarah Johnson',
        buyerId: 'buyer_1',
        buyerName: 'Mohammed Al Rashid',
        developerId: 'dev_3',
        developerName: 'Nakheel Properties',
        finalPrice: 45000000.0,
        status: DealStatus.pending,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        updatedAt: DateTime.now().subtract(const Duration(days: 2)),
        notes: 'All documentation completed, awaiting final verification',
      ),
      Deal(
        id: 'deal_2',
        listingId: 'listing_4',
        listingTitle: 'Commercial Land - DIFC',
        sellerId: 'seller_4',
        sellerName: 'David Wilson',
        buyerId: 'buyer_2',
        buyerName: 'Aisha Al Maktoum',
        finalPrice: 32000000.0,
        status: DealStatus.pending,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
        notes: 'Contract signed, payment processed',
      ),
    ];
  }

  void _verifyListing(LandListing listing) async {
    setState(() {
      _pendingListings.remove(listing);
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${listing.location} has been verified and activated!'),
        backgroundColor: AppTheme.successColor,
      ),
    );
  }

  void _rejectListing(LandListing listing) async {
    setState(() {
      _pendingListings.remove(listing);
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${listing.location} has been rejected.'),
        backgroundColor: AppTheme.errorColor,
      ),
    );
  }

  void _verifyDeveloper(DeveloperProfile developer) async {
    setState(() {
      _pendingDevelopers.remove(developer);
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${developer.companyName} has been verified!'),
        backgroundColor: AppTheme.successColor,
      ),
    );
  }

  void _rejectDeveloper(DeveloperProfile developer) async {
    setState(() {
      _pendingDevelopers.remove(developer);
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${developer.companyName} has been rejected.'),
        backgroundColor: AppTheme.errorColor,
      ),
    );
  }

  void _completeDeal(Deal deal) async {
    setState(() {
      _pendingDeals.remove(deal);
    });
    
    // In a real app, this would:
    // 1. Update the deal status to completed
    // 2. Increment the buyer's boughtLandCount in their subscription
    // 3. Update the listing status to sold
    // 4. Send notifications to all parties
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Deal for ${deal.listingTitle} has been completed! Buyer\'s land count incremented.'),
        backgroundColor: AppTheme.successColor,
      ),
    );
  }

  void _cancelDeal(Deal deal) async {
    setState(() {
      _pendingDeals.remove(deal);
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Deal for ${deal.listingTitle} has been cancelled.'),
        backgroundColor: AppTheme.errorColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: Column(
        children: [
          _buildStatsCards(),
          const SizedBox(height: 16),
          _buildTabBar(),
          Expanded(
            child: _selectedTab == 'listings'
                ? _buildListingsTab()
                : _selectedTab == 'developers'
                    ? _buildDevelopersTab()
                    : _buildDealsTab(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Pending Listings',
              '${_pendingListings.length}',
              Icons.home,
              AppTheme.primaryColor,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              'Pending Developers',
              '${_pendingDevelopers.length}',
              Icons.business,
              AppTheme.successColor,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              'Pending Deals',
              '${_pendingDeals.length}',
              Icons.handshake,
              AppTheme.warningColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton('listings', 'Land Listings'),
          ),
          Expanded(
            child: _buildTabButton('developers', 'Developers'),
          ),
          Expanded(
            child: _buildTabButton('deals', 'Deals'),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String value, String label) {
    final isSelected = _selectedTab == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildListingsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_pendingListings.isEmpty) {
      return _buildEmptyState('No pending land listings', Icons.check_circle);
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: _pendingListings.length,
      itemBuilder: (context, index) {
        final listing = _pendingListings[index];
        return _buildListingCard(listing);
      },
    );
  }

  Widget _buildDevelopersTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_pendingDevelopers.isEmpty) {
      return _buildEmptyState('No pending developer profiles', Icons.check_circle);
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: _pendingDevelopers.length,
      itemBuilder: (context, index) {
        final developer = _pendingDevelopers[index];
        return _buildDeveloperCard(developer);
      },
    );
  }

  Widget _buildDealsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_pendingDeals.isEmpty) {
      return _buildEmptyState('No pending deals', Icons.check_circle);
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: _pendingDeals.length,
      itemBuilder: (context, index) {
        final deal = _pendingDeals[index];
        return _buildDealCard(deal);
      },
    );
  }

  Widget _buildListingCard(LandListing listing) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    listing.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.warningColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Pending',
                    style: TextStyle(
                      color: AppTheme.warningColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'AED ${(listing.askingPrice / 1000000).toStringAsFixed(2)}M',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.successColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Seller: ${listing.sellerName}',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildInfoChip('Size', '${listing.landSize.toStringAsFixed(0)} sqm'),
                const SizedBox(width: 8),
                _buildInfoChip('GFA', '${listing.gfa.toStringAsFixed(0)} sqm'),
                const SizedBox(width: 8),
                _buildInfoChip('Type', listing.ownershipType.toString().split('.').last),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _verifyListing(listing),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.successColor,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Verify & Activate'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _rejectListing(listing),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.errorColor,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Reject'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeveloperCard(DeveloperProfile developer) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    developer.companyName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.warningColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Pending',
                    style: TextStyle(
                      color: AppTheme.warningColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Email: ${developer.companyEmail}',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildInfoChip('Projects', '${developer.deliveredProjects}'),
                const SizedBox(width: 8),
                _buildInfoChip('Team', '${developer.teamSize}'),
                const SizedBox(width: 8),
                _buildInfoChip('License', developer.tradeLicense),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _verifyDeveloper(developer),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.successColor,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Verify'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _rejectDeveloper(developer),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.errorColor,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Reject'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDealCard(Deal deal) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    deal.listingTitle,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Pending',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'AED ${(deal.finalPrice / 1000000).toStringAsFixed(2)}M',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.successColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Seller: ${deal.sellerName}',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Buyer: ${deal.buyerName}',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
            ),
            if (deal.developerName != null) ...[
              const SizedBox(height: 4),
              Text(
                'Developer: ${deal.developerName}',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
            if (deal.notes != null && deal.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  deal.notes!,
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _completeDeal(deal),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.successColor,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Mark Complete'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _cancelDeal(deal),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.errorColor,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          fontSize: 12,
          color: AppTheme.textSecondary,
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: AppTheme.successColor,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

}