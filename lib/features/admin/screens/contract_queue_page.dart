import 'package:flutter/material.dart';
import 'package:aradi/core/models/deal.dart';
import 'package:aradi/app/theme/app_theme.dart';
import 'package:aradi/core/services/notification_service.dart';

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

  @override
  void initState() {
    super.initState();
    _loadDeals();
  }

  void _loadDeals() async {
    setState(() {
      _isLoading = true;
    });

    await Future.delayed(const Duration(milliseconds: 500));
    
    _deals = _createMockDeals();
    _applyFilter();
    
    setState(() {
      _isLoading = false;
    });
  }

  List<Deal> _createMockDeals() {
    return [
      Deal(
        id: 'deal_1',
        listingId: 'listing_1',
        listingTitle: 'Dubai Marina, Jumeirah',
        sellerId: 'seller_1',
        sellerName: 'Property Owner',
        buyerId: 'dev_1',
        buyerName: 'Emaar Properties',
        developerId: 'dev_1',
        developerName: 'Emaar Properties',
        finalPrice: 2500000,
        offerAmount: 2500000,
        status: DealStatus.pending,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        updatedAt: DateTime.now().subtract(const Duration(days: 2)),
        acceptedAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      Deal(
        id: 'deal_2',
        listingId: 'listing_2',
        listingTitle: 'Downtown Dubai, Burj Khalifa',
        sellerId: 'seller_2',
        sellerName: 'Property Owner',
        buyerId: 'dev_2',
        buyerName: 'Nakheel Properties',
        developerId: 'dev_2',
        developerName: 'Nakheel Properties',
        finalPrice: 3500000,
        offerAmount: 3500000,
        status: DealStatus.completed,
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        updatedAt: DateTime.now().subtract(const Duration(days: 5)),
        acceptedAt: DateTime.now().subtract(const Duration(days: 4)),
        completedAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      Deal(
        id: 'deal_3',
        listingId: 'listing_3',
        listingTitle: 'Palm Jumeirah, The Palm',
        sellerId: 'seller_3',
        sellerName: 'Property Owner',
        buyerId: 'dev_3',
        buyerName: 'Damac Properties',
        developerId: 'dev_3',
        developerName: 'Damac Properties',
        finalPrice: 1800000,
        offerAmount: 1800000,
        status: DealStatus.cancelled,
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        updatedAt: DateTime.now().subtract(const Duration(days: 3)),
        acceptedAt: DateTime.now().subtract(const Duration(days: 2)),
        cancelledAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];
  }

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
      appBar: AppBar(
        title: const Text('Deals'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
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
                          '${deal.sellerName} ↔ ${deal.developerName}',
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
                    'AED ${_formatPrice(deal.offerAmount ?? deal.finalPrice)}',
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
        onAction: (action) async {
          await _handleDealAction(deal, action);
        },
      ),
    );
  }

  Future<void> _handleDealAction(Deal deal, String action) async {
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
          await _cancelDeal(deal);
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
    // TODO: Implement deal approval logic
    setState(() {
      final index = _deals.indexWhere((d) => d.id == deal.id);
      if (index != -1) {
        _deals[index] = deal.copyWith(status: DealStatus.completed);
      }
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Deal approved successfully'),
        backgroundColor: AppTheme.successColor,
      ),
    );
  }

  Future<void> _rejectDeal(Deal deal) async {
    // TODO: Implement deal rejection logic
    setState(() {
      final index = _deals.indexWhere((d) => d.id == deal.id);
      if (index != -1) {
        _deals[index] = deal.copyWith(status: DealStatus.cancelled);
      }
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Deal rejected'),
        backgroundColor: AppTheme.warningColor,
      ),
    );
  }

  Future<void> _completeDeal(Deal deal) async {
    // TODO: Implement deal completion logic
    setState(() {
      final index = _deals.indexWhere((d) => d.id == deal.id);
      if (index != -1) {
        _deals[index] = deal.copyWith(
          status: DealStatus.completed,
          completedAt: DateTime.now(),
        );
      }
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Deal marked as completed'),
        backgroundColor: AppTheme.successColor,
      ),
    );
  }

  Future<void> _cancelDeal(Deal deal) async {
    // TODO: Implement deal cancellation logic
    setState(() {
      final index = _deals.indexWhere((d) => d.id == deal.id);
      if (index != -1) {
        _deals[index] = deal.copyWith(
          status: DealStatus.cancelled,
          cancelledAt: DateTime.now(),
        );
      }
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Deal cancelled'),
        backgroundColor: AppTheme.errorColor,
      ),
    );
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

class DealDetailsDialog extends StatelessWidget {
  final Deal deal;
  final Function(String action) onAction;

  const DealDetailsDialog({
    super.key,
    required this.deal,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
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
                  const Icon(
                    Icons.handshake,
                    color: Colors.white,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Deal Details',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          deal.listingTitle,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
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
                    _buildDetailRow('Property', deal.listingTitle),
                    _buildDetailRow('Seller', deal.sellerName),
                    _buildDetailRow('Developer', deal.developerName ?? 'N/A'),
                    _buildDetailRow('Offer Amount', 'AED ${_formatPrice(deal.offerAmount ?? deal.finalPrice)}'),
                    _buildDetailRow('Status', _getStatusText(deal.status)),
                    _buildDetailRow('Created', _formatDate(deal.createdAt)),
                    if (deal.acceptedAt != null)
                      _buildDetailRow('Accepted', _formatDate(deal.acceptedAt!)),
                    if (deal.completedAt != null)
                      _buildDetailRow('Completed', _formatDate(deal.completedAt!)),
                    if (deal.cancelledAt != null)
                      _buildDetailRow('Cancelled', _formatDate(deal.cancelledAt!)),
                  ],
                ),
              ),
            ),

            // Actions
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                  const SizedBox(width: 12),
                  if (deal.status == DealStatus.pending) ...[
                    ElevatedButton(
                      onPressed: () => onAction('Approve'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.successColor,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Approve'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => onAction('Reject'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.errorColor,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Reject'),
                    ),
                  ] else if (deal.status == DealStatus.completed) ...[
                    ElevatedButton(
                      onPressed: () => onAction('Complete'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Mark Complete'),
                    ),
                  ] else if (deal.status == DealStatus.cancelled) ...[
                    ElevatedButton(
                      onPressed: () => onAction('Cancel'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.warningColor,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Cancel Deal'),
                    ),
                  ],
                ],
              ),
            ),
          ],
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
            width: 100,
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
            ),
          ),
        ],
      ),
    );
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