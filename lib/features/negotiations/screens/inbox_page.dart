import 'package:flutter/material.dart';
import 'package:aradi/core/models/negotiation.dart';
import 'package:aradi/core/models/offer.dart';
import 'package:aradi/app/theme/app_theme.dart';
import 'package:go_router/go_router.dart';

class InboxPage extends StatefulWidget {
  const InboxPage({super.key});

  @override
  State<InboxPage> createState() => _InboxPageState();
}

class _InboxPageState extends State<InboxPage> {
  List<Negotiation> _negotiations = [];
  bool _isLoading = true;
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadNegotiations();
  }

  void _loadNegotiations() async {
    setState(() {
      _isLoading = true;
    });

    // Load negotiations from Firebase (no mock data)
    setState(() {
      _negotiations = <Negotiation>[]; // Will be loaded from Firebase
      _isLoading = false;
    });
  }

  List<Negotiation> _createDemoNegotiations() {
    return [
      Negotiation(
        id: 'neg_1',
        listingId: 'listing_1',
        listingTitle: 'Premium Land Plot - Dubai Marina',
        sellerId: 'seller_1',
        sellerName: 'Fatima Al Zahra',
        developerId: 'dev_1',
        developerName: 'Dubai Properties',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 3)),
        messages: [
          NegotiationMessage(
            id: 'msg_1',
            negotiationId: 'neg_1',
            senderId: 'dev_1',
            senderName: 'Dubai Properties',
            senderRole: 'Developer',
            type: NegotiationType.message,
            content: 'Interested in your land listing. Can we discuss the terms?',
            createdAt: DateTime.now().subtract(const Duration(days: 2)),
          ),
        ],
      ),
      Negotiation(
        id: 'neg_2',
        listingId: 'listing_2',
        listingTitle: 'Commercial Land - Business Bay',
        sellerId: 'seller_2',
        sellerName: 'Ahmed Al Mansouri',
        developerId: 'dev_2',
        developerName: 'Emaar Properties',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
        messages: [
          NegotiationMessage(
            id: 'msg_2',
            negotiationId: 'neg_2',
            senderId: 'dev_2',
            senderName: 'Emaar Properties',
            senderRole: 'Developer',
            type: NegotiationType.message,
            content: 'We would like to propose a joint venture.',
            createdAt: DateTime.now().subtract(const Duration(days: 5)),
          ),
        ],
      ),
      Negotiation(
        id: 'neg_3',
        listingId: 'listing_3',
        listingTitle: 'Residential Land - Palm Jumeirah',
        sellerId: 'seller_3',
        sellerName: 'Sarah Johnson',
        developerId: 'dev_3',
        developerName: 'Meraas',
        status: OfferStatus.accepted,
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
        updatedAt: DateTime.now().subtract(const Duration(days: 2)),
        messages: [
          NegotiationMessage(
            id: 'msg_3',
            negotiationId: 'neg_3',
            senderId: 'dev_3',
            senderName: 'Meraas',
            senderRole: 'Developer',
            type: NegotiationType.message,
            content: 'Deal completed successfully!',
            createdAt: DateTime.now().subtract(const Duration(days: 2)),
          ),
        ],
      ),
    ];
  }

  void _applyFilters() {
    setState(() {
      // Filter existing negotiations (no mock data)
      if (_selectedFilter == 'all') {
        // Show all negotiations
      } else if (_selectedFilter == 'active') {
        _negotiations = _negotiations
            .where((n) => n.status == OfferStatus.sent)
            .toList();
      } else if (_selectedFilter == 'completed') {
        _negotiations = _negotiations
            .where((n) => n.status == OfferStatus.accepted)
            .toList();
      } else if (_selectedFilter == 'pending') {
        _negotiations = _negotiations
            .where((n) => n.status == OfferStatus.sent)
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('all', 'All'),
                  const SizedBox(width: 8),
                  _buildFilterChip('active', 'Active'),
                  const SizedBox(width: 8),
                  _buildFilterChip('pending', 'Pending'),
                  const SizedBox(width: 8),
                  _buildFilterChip('completed', 'Completed'),
                ],
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _negotiations.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _negotiations.length,
                        itemBuilder: (context, index) {
                          final negotiation = _negotiations[index];
                          return _buildNegotiationCard(negotiation);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
        });
        _applyFilters();
      },
      backgroundColor: Colors.white,
      selectedColor: Colors.blue[100],
      labelStyle: TextStyle(
        color: isSelected ? Colors.blue[600] : Colors.grey[600],
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? Colors.blue[600]! : Colors.grey[300]!,
      ),
    );
  }

  Widget _buildNegotiationCard(Negotiation negotiation) {
    final lastMessage = negotiation.messages.isNotEmpty
        ? negotiation.messages.last
        : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          context.push('/negotiations/${negotiation.id}');
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      negotiation.listingTitle,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  _buildStatusChip(negotiation.status),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Developer: ${negotiation.developerName}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Seller: ${negotiation.sellerName}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
              if (lastMessage != null)
                Row(
                  children: [
                    Icon(
                      Icons.message,
                      size: 16,
                      color: Colors.grey[500],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${lastMessage.senderName}: ${lastMessage.content}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 13,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    'Updated ${_formatDate(negotiation.updatedAt)}',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${negotiation.messages.length} messages',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(OfferStatus status) {
    Color color;
    IconData icon;
    String text;

    switch (status) {
      case OfferStatus.sent:
        color = Colors.blue;
        icon = Icons.send;
        text = 'Sent';
        break;
      case OfferStatus.countered:
        color = Colors.orange;
        icon = Icons.swap_horiz;
        text = 'Countered';
        break;
      case OfferStatus.accepted:
        color = Colors.green;
        icon = Icons.check_circle;
        text = 'Accepted';
        break;
      case OfferStatus.rejected:
        color = Colors.red;
        icon = Icons.cancel;
        text = 'Rejected';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No negotiations yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start browsing land listings to begin negotiations',
            style: TextStyle(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
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

