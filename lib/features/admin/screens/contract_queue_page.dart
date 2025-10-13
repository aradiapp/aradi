import 'package:flutter/material.dart';
import 'package:aradi/core/models/deal.dart';
import 'package:aradi/app/theme/app_theme.dart';
import 'package:aradi/core/services/notification_service.dart';
import 'package:aradi/core/services/deal_service.dart';
import 'package:aradi/core/services/negotiation_service.dart';
import 'package:aradi/core/services/document_upload_service.dart';
import 'package:aradi/core/models/offer.dart';
import 'package:aradi/core/models/notification_event.dart';
import 'package:aradi/core/services/land_listing_service.dart';
import 'package:aradi/core/models/land_listing.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';

class ContractQueuePage extends StatefulWidget {
  const ContractQueuePage({super.key});

  @override
  State<ContractQueuePage> createState() => _ContractQueuePageState();
}

class _ContractQueuePageState extends State<ContractQueuePage> {
  List<Deal> _deals = [];
  List<Deal> _filteredDeals = [];
  bool _isLoading = true;
  DealStatus _selectedFilter = DealStatus.pending;
  bool _showFilters = false;
  final DealService _dealService = DealService();
  final NegotiationService _negotiationService = NegotiationService();
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _loadDeals();
  }

  Future<void> _loadDeals() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // First, create deals from accepted negotiations
      await _createDealsFromAcceptedNegotiations();
      
      // Update existing deals with correct seller names
      await _dealService.updateDealsWithCorrectSellerNames();
      
      // Then load all deals
      _deals = await _dealService.getAllDeals();
      _applyFilter();
    } catch (e) {
      print('Error loading deals: $e');
      if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
            content: Text('Error loading deals: $e'),
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

  Future<void> _createDealsFromAcceptedNegotiations() async {
    try {
      // Get all accepted negotiations
      final allNegotiations = await _negotiationService.getAllNegotiations();
      print('Total negotiations found: ${allNegotiations.length}');
      
      final acceptedNegotiations = allNegotiations.where((n) => 
        n.status == OfferStatus.accepted).toList();
      print('Accepted negotiations found: ${acceptedNegotiations.length}');

      // Check which negotiations already have deals
      final existingDeals = await _dealService.getAllDeals();
      final existingDealIds = existingDeals.map((d) => d.id).toSet();
      print('Existing deals: ${existingDeals.length}');

      // Create deals for accepted negotiations that don't have deals yet
      for (final negotiation in acceptedNegotiations) {
        print('Processing negotiation: ${negotiation.id}, status: ${negotiation.status}');
        if (!existingDealIds.contains(negotiation.id)) {
          try {
            await _dealService.createDealFromNegotiation(negotiation);
            print('✅ Created deal for negotiation: ${negotiation.id}');
          } catch (e) {
            print('❌ Error creating deal for negotiation ${negotiation.id}: $e');
          }
        } else {
          print('Deal already exists for negotiation: ${negotiation.id}');
        }
      }
    } catch (e) {
      print('Error creating deals from negotiations: $e');
    }
  }

  // Mock data method removed - now using real data from DealService

  void _applyFilter() {
    setState(() {
      _filteredDeals = _deals.where((deal) {
        switch (_selectedFilter) {
          case DealStatus.pending:
            return deal.status == DealStatus.pending;
          case DealStatus.completed:
            return deal.status == DealStatus.completed;
          case DealStatus.cancelled:
            return deal.status == DealStatus.cancelled;
        }
      }).toList();
    });
  }

  void _onFilterChanged(DealStatus filter) {
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
      backgroundColor: AppTheme.backgroundLight,
      body: Column(
        children: [
          // Filter toggle button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: _toggleFilters,
                  icon: Icon(_showFilters ? Icons.filter_list_off : Icons.filter_list),
                  tooltip: _showFilters ? 'Hide Filters' : 'Show Filters',
                ),
              ],
            ),
          ),
          if (_showFilters) _buildFilters(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredDeals.isEmpty
                    ? _buildEmptyState()
                    : _buildDealsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filter by Status',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
        children: [
          Expanded(
                child: _buildFilterChip(
                  'Pending',
                  DealStatus.pending,
                  AppTheme.warningColor,
                ),
              ),
              const SizedBox(width: 8),
          Expanded(
                child: _buildFilterChip(
                  'Completed',
                  DealStatus.completed,
              AppTheme.successColor,
            ),
          ),
              const SizedBox(width: 8),
          Expanded(
                child: _buildFilterChip(
                  'Cancelled',
                  DealStatus.cancelled,
                  AppTheme.errorColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, DealStatus status, Color color) {
    final isSelected = _selectedFilter == status;
    
    return InkWell(
      onTap: () => _onFilterChanged(status),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
          color: isSelected ? color : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: 2,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.handshake_outlined,
            size: 80,
            color: AppTheme.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            'No deals found',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'There are no deals matching the current filter.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDealsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredDeals.length,
      itemBuilder: (context, index) {
        final deal = _filteredDeals[index];
        return _buildDealCard(deal);
      },
    );
  }

  Widget _buildDealCard(Deal deal) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showDealDetails(deal),
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
                          deal.listingTitle,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${deal.sellerName} ↔ ${deal.developerName ?? deal.buyerName}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
          ),
        ],
      ),
                  ),
                  _buildStatusChip(deal.status),
                ],
              ),
              const SizedBox(height: 12),
              Row(
        children: [
                  Icon(
                    Icons.attach_money,
                    size: 20,
                    color: AppTheme.successColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'AED ${_formatPrice(deal.finalPrice)}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppTheme.successColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Created: ${_formatDate(deal.createdAt)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  if (deal.acceptedAt != null)
                    Text(
                      'Accepted: ${_formatDate(deal.acceptedAt!)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                ],
              ),
              if (deal.status == DealStatus.completed && deal.completedAt != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Completed: ${_formatDate(deal.completedAt!)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.successColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              if (deal.status == DealStatus.cancelled && deal.cancelledAt != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Cancelled: ${_formatDate(deal.cancelledAt!)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.errorColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(DealStatus status) {
    Color backgroundColor;
    Color textColor;
    String text;

    switch (status) {
      case DealStatus.pending:
        backgroundColor = AppTheme.warningColor;
        textColor = Colors.white;
        text = 'Pending';
        break;
      case DealStatus.completed:
        backgroundColor = AppTheme.successColor;
        textColor = Colors.white;
        text = 'Completed';
        break;
      case DealStatus.cancelled:
        backgroundColor = AppTheme.errorColor;
        textColor = Colors.white;
        text = 'Cancelled';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
        color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
        text,
          style: TextStyle(
          color: textColor,
            fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _showDealDetails(Deal deal) {
    showDialog(
      context: context,
      builder: (context) => DealDetailsDialog(
        deal: deal,
        onAction: (action, {String? rejectionReason}) async {
          await _handleDealAction(deal, action, rejectionReason: rejectionReason);
        },
      ),
    );
  }

  Future<void> _handleDealAction(Deal deal, String action, {String? rejectionReason}) async {
    try {
      switch (action) {
        case 'Approve':
          await _approveDeal(deal);
          break;
        case 'Reject':
          await _rejectDeal(deal);
          break;
        case 'Complete':
          await _completeDeal(deal);
          break;
        case 'Cancel':
          await _cancelDeal(deal, rejectionReason: rejectionReason);
          break;
      }
      
      if (mounted) {
        Navigator.pop(context); // Close dialog
        _loadDeals(); // Refresh deals
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _approveDeal(Deal deal) async {
    try {
      await _dealService.updateDealStatus(deal.id, DealStatus.completed, completedBy: 'admin');
      
      // Send notifications to both parties
      await _sendDealNotification(deal, 'completed', 'Deal Completed', 
          'Your deal for ${deal.listingTitle} has been completed successfully.');
      
      await _loadDeals(); // Refresh deals
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Deal approved successfully'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } catch (e) {
      print('Error approving deal: $e');
      rethrow;
    }
  }

  Future<void> _rejectDeal(Deal deal) async {
    try {
      await _dealService.updateDealStatus(deal.id, DealStatus.cancelled, rejectionReason: 'Deal rejected by admin');
      
      // Send notifications to both parties
      await _sendDealNotification(deal, 'rejected', 'Deal Rejected', 
          'Your deal for ${deal.listingTitle} has been rejected by admin.');
      
      await _loadDeals(); // Refresh deals
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Deal rejected'),
          backgroundColor: AppTheme.warningColor,
        ),
      );
    } catch (e) {
      print('Error rejecting deal: $e');
      rethrow;
    }
  }

  Future<void> _completeDeal(Deal deal) async {
    try {
      // Update deal status (this will also update negotiation and listing statuses)
      await _dealService.updateDealStatus(deal.id, DealStatus.completed, completedBy: 'admin');
      
      // Send notifications to both parties
      await _sendDealNotification(deal, 'completed', 'Deal Completed', 
          'Your deal for ${deal.listingTitle} has been completed successfully.');
      
      await _loadDeals(); // Refresh deals
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Deal completed successfully'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } catch (e) {
      print('Error completing deal: $e');
      rethrow;
    }
  }

  Future<void> _cancelDeal(Deal deal, {String? rejectionReason}) async {
    try {
      await _dealService.updateDealStatus(deal.id, DealStatus.cancelled, rejectionReason: rejectionReason ?? 'Deal cancelled by admin');
      
      // Send notifications to both parties
      await _sendDealNotification(deal, 'cancelled', 'Deal Cancelled', 
          'Your deal for ${deal.listingTitle} has been cancelled. Reason: ${rejectionReason ?? 'Deal cancelled by admin'}');
      
      await _loadDeals(); // Refresh deals
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Deal cancelled'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    } catch (e) {
      print('Error cancelling deal: $e');
      rethrow;
    }
  }

  Future<void> _sendDealNotification(Deal deal, String type, String title, String body) async {
    try {
      // Send notification to seller
      await _notificationService.createNotificationEvent(
        userId: deal.sellerId,
        type: NotificationType.dealUpdate,
        title: title,
        body: body,
        data: {
          'type': 'deal_$type',
          'dealId': deal.id,
          'listingTitle': deal.listingTitle,
        },
      );

      // Send notification to developer
      await _notificationService.createNotificationEvent(
        userId: deal.developerId ?? deal.buyerId,
        type: NotificationType.dealUpdate,
        title: title,
        body: body,
        data: {
          'type': 'deal_$type',
          'dealId': deal.id,
          'listingTitle': deal.listingTitle,
        },
      );
    } catch (e) {
      print('Error sending deal notifications: $e');
      // Don't throw error here as it's not critical for the main operation
    }
  }

  String _formatPrice(double price) {
    if (price >= 1000000) {
      return '${(price / 1000000).toStringAsFixed(1)}M';
    } else if (price >= 1000) {
      return '${(price / 1000).toStringAsFixed(0)}K';
    } else {
      return price.toStringAsFixed(0);
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

class DealDetailsDialog extends StatefulWidget {
  final Deal deal;
  final Function(String action, {String? rejectionReason}) onAction;

  const DealDetailsDialog({
    super.key,
    required this.deal,
    required this.onAction,
  });

  @override
  State<DealDetailsDialog> createState() => _DealDetailsDialogState();
}

class _DealDetailsDialogState extends State<DealDetailsDialog> {
  final DealService _dealService = DealService();
  final DocumentUploadService _documentUploadService = DocumentUploadService();
  final LandListingService _landListingService = LandListingService();
  final TextEditingController _rejectionReasonController = TextEditingController();
  final Map<String, bool> _uploadingStates = {
    'Contract A': false,
    'Contract B': false,
    'Contract F': false,
    'JV Agreement': false,
  };
  
  // Local state to track the current deal data
  late Deal _currentDeal;

  @override
  void initState() {
    super.initState();
    _currentDeal = widget.deal;
  }

  @override
  void dispose() {
    _rejectionReasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.95,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
                Container(
              padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
              children: [
                  Icon(
                    _currentDeal.type == DealType.jv ? Icons.handshake : Icons.sell,
                    color: Colors.white,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
            Text(
                          '${_currentDeal.type == DealType.jv ? 'JV' : 'Buy'} Deal Details',
                    style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
            Text(
                          _currentDeal.listingTitle,
                          style: const TextStyle(
                            color: Colors.white70,
                fontSize: 14,
              ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                ),
              ],
            ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                    // Property Information
                    _buildSectionHeader('Property Information'),
                    _buildDetailRow('Property', _currentDeal.listingTitle),
                    _buildDetailRow('Asking Price', 'AED ${_formatPrice(_currentDeal.askingPrice)}'),
                    _buildDetailRow('Final Price', 'AED ${_formatPrice(_currentDeal.finalPrice)}'),
                    _buildTitleDeedRow(),
                    
                    const SizedBox(height: 20),

                    // Listing Details
                    _buildSectionHeader('Listing Details'),
                    FutureBuilder<LandListing?>(
                      future: _landListingService.getListingById(_currentDeal.listingId),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        
                        if (snapshot.hasError || !snapshot.hasData) {
                          return const Text('Error loading listing details');
                        }
                        
                        final listing = snapshot.data!;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildDetailRow('Emirate', listing.emirate),
                            _buildDetailRow('City', listing.city),
                            _buildDetailRow('Area', listing.area),
                            _buildDetailRow('Land Size', '${listing.landSize} sqm'),
                            _buildDetailRow('GFA', '${listing.gfa} sqm'),
                            _buildDetailRow('Ownership Type', listing.ownershipType.toString().split('.').last),
                            _buildDetailRow('Permissions', listing.permissions.map((p) => p.toString().split('.').last).join(', ')),
                            if (listing.buildingSpecs != null)
                              _buildDetailRow('Building Specs', listing.buildingSpecs!),
                            if (listing.photos.isNotEmpty) ...[
            const SizedBox(height: 8),
                              const Text('Photos:', style: TextStyle(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 8),
                              SizedBox(
                                height: 100,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: listing.photos.length,
                                  itemBuilder: (context, index) {
                                    return Container(
                                      margin: const EdgeInsets.only(right: 8),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          listing.photos[index],
                                          width: 100,
                                          height: 100,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Container(
                                              width: 100,
                                              height: 100,
                                              color: Colors.grey[300],
                                              child: const Icon(Icons.image_not_supported),
                                            );
                                          },
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ],
                        );
                      },
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Parties Information
                    _buildSectionHeader('Parties Information'),
                    _buildDetailRow('Seller', _currentDeal.sellerName),
                    _buildDetailRow('Developer', _currentDeal.developerName ?? _currentDeal.buyerName),
                    
                    const SizedBox(height: 20),
                    
                    // Deal Specific Information
                    if (_currentDeal.type == DealType.jv) ...[
                      _buildSectionHeader('JV Partnership Details'),
                      _buildDetailRow('Landowner %', '${_currentDeal.sellerPercentage?.toInt() ?? 0}%'),
                      _buildDetailRow('Developer %', '${_currentDeal.developerPercentage?.toInt() ?? 0}%'),
                    ] else ...[
                      _buildSectionHeader('Buy Offer Details'),
                      _buildDetailRow('Offer Amount', 'AED ${_formatPrice(_currentDeal.offerAmount ?? _currentDeal.finalPrice)}'),
                      _buildDetailRow('Price Difference', '${_calculatePriceDifference()}%'),
                    ],
                    
                    const SizedBox(height: 20),
                    
                    // Contract Documents
                    if (_currentDeal.type == DealType.buy) ...[
                      _buildSectionHeader('Contract Documents'),
                      _buildDocumentUpload('Contract A', 'Contract A'),
                      _buildDocumentUpload('Contract B', 'Contract B'),
                      _buildDocumentUpload('Contract F', 'Contract F'),
                    ] else if (_currentDeal.type == DealType.jv) ...[
                      _buildSectionHeader('JV Agreement'),
                      _buildDocumentUpload('JV Agreement', 'JV Agreement'),
                    ],
                    
                    const SizedBox(height: 20),
                    
                    // Deal Status
                    _buildSectionHeader('Deal Status'),
                    _buildDetailRow('Status', _getStatusText(_currentDeal.status)),
                    _buildDetailRow('Created', _formatDate(_currentDeal.createdAt)),
                    if (_currentDeal.acceptedAt != null)
                      _buildDetailRow('Accepted', _formatDate(_currentDeal.acceptedAt!)),
                    if (_currentDeal.completedAt != null)
                      _buildDetailRow('Completed', _formatDate(_currentDeal.completedAt!)),
                    if (_currentDeal.cancelledAt != null)
                      _buildDetailRow('Cancelled', _formatDate(_currentDeal.cancelledAt!)),
                    if (_currentDeal.rejectionReason != null)
                      _buildDetailRow('Rejection Reason', _currentDeal.rejectionReason!),
                  ],
                ),
              ),
            ),

            // Actions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
              children: [
                  if (_currentDeal.status == DealStatus.pending) ...[
                    // Action buttons in a column for better mobile layout
                    SizedBox(
                      width: double.infinity,
                  child: ElevatedButton(
                        onPressed: () => _showCancelDialog(),
                    style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.errorColor,
                          foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                        child: const Text('Cancel Deal'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Complete button for both buy and JV deals
                    SizedBox(
                      width: double.infinity,
                  child: ElevatedButton(
                        onPressed: _dealService.hasAllRequiredDocuments(_currentDeal) 
                            ? () => widget.onAction('Complete')
                            : null,
                    style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.successColor,
                          foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                        child: Text(_currentDeal.type == DealType.jv 
                            ? 'Complete JV Deal' 
                            : 'Complete Deal'),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  // Close button
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Close'),
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

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
        title,
                    style: const TextStyle(
                      fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryColor,
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          SizedBox(
            width: 120,
                  child: Text(
              label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
      ),
    );
  }

  Widget _buildTitleDeedRow() {
    return FutureBuilder<LandListing?>(
      future: _landListingService.getListingById(_currentDeal.listingId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildDetailRow('Title Deed', 'Loading...');
        }
        
        if (snapshot.hasError || !snapshot.hasData) {
          return _buildDetailRow('Title Deed', 'Not available');
        }
        
        final listing = snapshot.data!;
        final titleDeedUrl = listing.titleDeedDocumentUrl;
        
        if (titleDeedUrl == null || titleDeedUrl.isEmpty) {
          return _buildDetailRow('Title Deed', 'Not uploaded');
        }
        
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            const SizedBox(
              width: 120,
                  child: Text(
                'Title Deed',
                style: TextStyle(
                      fontWeight: FontWeight.w600,
                  color: Colors.grey,
                    ),
                  ),
                ),
                Expanded(
              child: GestureDetector(
                onTap: () => _viewTitleDeed(titleDeedUrl),
                child: Row(
                  children: [
                    const Icon(
                      Icons.description,
                      color: AppTheme.primaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'View Title Deed',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w500,
                        decoration: TextDecoration.underline,
                  ),
                ),
              ],
            ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _viewTitleDeed(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open title deed')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening title deed: $e')),
        );
      }
    }
  }

  Widget _buildDocumentUpload(String label, String documentType) {
    final hasDocument = _currentDeal.contractDocuments.containsKey(documentType);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          // Label row
            Row(
              children: [
              SizedBox(
                width: 120,
                  child: Text(
                  label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              Expanded(
                child: Row(
                  children: [
                    if (hasDocument) ...[
                      const Icon(Icons.check_circle, color: AppTheme.successColor, size: 20),
                      const SizedBox(width: 8),
                      const Expanded(
                  child: Text(
                          'Uploaded',
                    style: TextStyle(
                color: AppTheme.successColor,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ] else ...[
                      const Icon(Icons.upload_file, color: AppTheme.textSecondary, size: 20),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Not uploaded',
              style: TextStyle(
                color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
              const SizedBox(height: 8),
          // Button row
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton.icon(
                onPressed: _uploadingStates[documentType]! ? null : () => _uploadDocument(documentType),
                icon: _uploadingStates[documentType]! 
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.upload, size: 16),
                label: Text(hasDocument ? 'Replace' : 'Upload'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: hasDocument ? AppTheme.warningColor : AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showCancelDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Deal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
              children: [
            const Text('Are you sure you want to cancel this deal?'),
            const SizedBox(height: 16),
            TextField(
              controller: _rejectionReasonController,
              decoration: const InputDecoration(
                labelText: 'Reason for cancellation',
                hintText: 'Enter the reason for cancelling this deal...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_rejectionReasonController.text.trim().isNotEmpty) {
                Navigator.pop(context); // Close dialog
                widget.onAction('Cancel', rejectionReason: _rejectionReasonController.text.trim());
              }
            },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.errorColor,
              foregroundColor: Colors.white,
                    ),
            child: const Text('Yes, Cancel'),
                ),
              ],
            ),
    );
  }

  Future<void> _uploadDocument(String documentType) async {
    print('Starting upload for $documentType');
    setState(() {
      _uploadingStates[documentType] = true;
    });

    try {
      // Pick document from device
      print('Picking document...');
      final File? file = await _documentUploadService.pickDocument();
      
      if (file == null) {
        print('No file selected');
        setState(() {
          _uploadingStates[documentType] = false;
        });
        return;
      }

      print('File selected: ${file.path}');

      // Validate file type
      if (!_documentUploadService.isValidFileType(file.path)) {
        print('Invalid file type: ${file.path}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invalid file type. Please select PDF, DOC, DOCX, JPG, or PNG files.'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
        setState(() {
          _uploadingStates[documentType] = false;
        });
        return;
      }

      // Validate file size
      if (!_documentUploadService.isValidFileSize(file)) {
        print('File too large: ${_documentUploadService.getFileSizeInMB(file)}MB');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('File size too large. Maximum size is 10MB.'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
        setState(() {
          _uploadingStates[documentType] = false;
        });
        return;
      }

      print('Starting Firebase Storage upload...');
      // Upload document
      final downloadUrl = await _documentUploadService.uploadDocument(file, _currentDeal.id, documentType);
      print('Upload completed, download URL: $downloadUrl');
      
      print('Saving document URL to deal...');
      // Save document URL to deal
      await _dealService.uploadContractDocument(_currentDeal.id, documentType, downloadUrl);
      print('Document URL saved to deal');
      
      // Refresh the deal data to show uploaded documents
      final updatedDeal = await _dealService.getDealById(_currentDeal.id);
      if (updatedDeal != null) {
        setState(() {
          // Update the local deal state
          _currentDeal = updatedDeal;
        });
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$documentType uploaded successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      print('Error during upload: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading $documentType: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      print('Upload process finished, resetting loading state');
      if (mounted) {
        setState(() {
          _uploadingStates[documentType] = false;
        });
      }
    }
  }

  String _calculatePriceDifference() {
    if (_currentDeal.offerAmount == null) return '0';
    final difference = ((_currentDeal.offerAmount! - _currentDeal.askingPrice) / _currentDeal.askingPrice) * 100;
    return difference.toStringAsFixed(1);
  }

  String _getStatusText(DealStatus status) {
    switch (status) {
      case DealStatus.pending:
        return 'Pending';
      case DealStatus.completed:
        return 'Completed';
      case DealStatus.cancelled:
        return 'Cancelled';
    }
  }

  String _formatPrice(double price) {
    if (price >= 1000000) {
      return '${(price / 1000000).toStringAsFixed(1)}M';
    } else if (price >= 1000) {
      return '${(price / 1000).toStringAsFixed(0)}K';
    } else {
      return price.toStringAsFixed(0);
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}