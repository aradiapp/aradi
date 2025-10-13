import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:aradi/app/theme/app_theme.dart';
import 'package:aradi/core/models/negotiation.dart';
import 'package:aradi/core/models/offer.dart';
import 'package:aradi/core/services/negotiation_service.dart';
import 'package:aradi/core/services/land_listing_service.dart';
import 'package:aradi/core/services/auth_service.dart';
import 'package:aradi/app/providers/data_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DeveloperNegotiationsPage extends ConsumerStatefulWidget {
  const DeveloperNegotiationsPage({super.key});

  @override
  ConsumerState<DeveloperNegotiationsPage> createState() => _DeveloperNegotiationsPageState();
}

class _DeveloperNegotiationsPageState extends ConsumerState<DeveloperNegotiationsPage> {
  List<Negotiation> _negotiations = [];
  List<Negotiation> _filteredNegotiations = [];
  bool _isLoading = true;
  final NegotiationService _negotiationService = NegotiationService();
  final LandListingService _landListingService = LandListingService();
  
  // Filter options for developer
  final List<String> _filterOptions = [
    'All',
    'Pending Seller',
    'Pending You', 
    'Pending Admin',
    'Admin will contact you',
    'Cancelled',
    'Completed'
  ];
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _loadNegotiations();
  }

  void _applyFilter() {
    if (_selectedFilter == 'All') {
      _filteredNegotiations = _negotiations;
    } else {
      _filteredNegotiations = _negotiations.where((negotiation) {
        switch (_selectedFilter) {
          case 'Pending Seller':
            return negotiation.status == OfferStatus.sent || negotiation.status == OfferStatus.pending;
          case 'Pending You':
            return negotiation.status == OfferStatus.countered;
          case 'Pending Admin':
            return negotiation.status == OfferStatus.accepted && !_isJVProposal(negotiation);
          case 'Admin will contact you':
            return negotiation.status == OfferStatus.accepted && _isJVProposal(negotiation);
          case 'Cancelled':
            return negotiation.status == OfferStatus.rejected;
          case 'Completed':
            // Only show truly completed negotiations (admin has completed the deal)
            return negotiation.status == OfferStatus.completed;
          default:
            return true;
        }
      }).toList();
    }
  }

  bool _isJVProposal(Negotiation negotiation) {
    return negotiation.messages.any((message) => 
      message.content.contains('JV Proposal') || 
      message.content.contains('% Landowner') ||
      message.content.contains('% Developer'));
  }

  void _onFilterChanged(String filter) {
    setState(() {
      _selectedFilter = filter;
      _applyFilter();
    });
  }

  Future<void> _loadNegotiations() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final authService = ref.read(authServiceProvider);
      final currentUser = await authService.getCurrentUser();
      
      print('Loading negotiations for user: ${currentUser?.id}');
      
      if (currentUser != null) {
        final negotiations = await _negotiationService.getNegotiationsForUser(
          currentUser.id,
          'developer',
        );
        
        print('Found ${negotiations.length} negotiations');
        for (final negotiation in negotiations) {
          print('Negotiation: ${negotiation.id} - ${negotiation.listingTitle}');
        }
        
        setState(() {
          _negotiations = negotiations;
          _applyFilter();
        });
      }
    } catch (e) {
      print('Error loading negotiations: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading negotiations: $e'),
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _negotiations.isEmpty
              ? _buildEmptyState()
              : Column(
                  children: [
                    _buildFilterChips(),
                    Expanded(child: _buildNegotiationsList()),
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
            Icons.handshake_outlined,
            size: 80,
            color: AppTheme.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            'No negotiations yet',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'When you make offers on listings, negotiations will appear here.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _filterOptions.map((filter) {
            final isSelected = _selectedFilter == filter;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(filter),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    _onFilterChanged(filter);
                  }
                },
                selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                checkmarkColor: AppTheme.primaryColor,
                labelStyle: TextStyle(
                  color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildNegotiationsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredNegotiations.length,
      itemBuilder: (context, index) {
        final negotiation = _filteredNegotiations[index];
        return _buildNegotiationCard(negotiation);
      },
    );
  }

  Widget _buildNegotiationCard(Negotiation negotiation) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showNegotiationDetails(negotiation),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppTheme.primaryColor,
                    child: const Icon(
                      Icons.home,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          negotiation.listingTitle,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Property Owner',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusChip(negotiation),
                ],
              ),
              const SizedBox(height: 12),
              if (negotiation.messages.isNotEmpty) ...[
                Text(
                  negotiation.messages.last.content,
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDate(negotiation.updatedAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  if (negotiation.hasUnreadMessages)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${negotiation.unreadCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
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

  Widget _buildStatusChip(Negotiation negotiation) {
    Color backgroundColor;
    Color textColor;
    String text;

    // Check if this is a JV proposal by looking at the first message
    final isJV = negotiation.messages.any((message) => 
      message.content.contains('JV Proposal') || 
      message.content.contains('% Landowner') ||
      message.content.contains('% Developer'));

    switch (negotiation.status) {
      case OfferStatus.sent:
        backgroundColor = AppTheme.warningColor;
        textColor = Colors.white;
        text = 'Pending Seller'; // Developer perspective
        break;
      case OfferStatus.pending:
        backgroundColor = AppTheme.warningColor;
        textColor = Colors.white;
        text = 'Pending Seller'; // Developer perspective
        break;
      case OfferStatus.countered:
        backgroundColor = AppTheme.primaryColor;
        textColor = Colors.white;
        // Check who made the last counter by looking at the last message
        final lastMessage = negotiation.messages.isNotEmpty 
            ? negotiation.messages.reduce((a, b) => a.createdAt.isAfter(b.createdAt) ? a : b)
            : null;
        
        if (lastMessage != null && lastMessage.senderRole.toLowerCase() == 'developer') {
          text = 'Pending Seller'; // Developer countered, waiting for seller
        } else {
          text = 'Pending You'; // Seller countered, waiting for developer
        }
        break;
      case OfferStatus.accepted:
        backgroundColor = AppTheme.successColor;
        textColor = Colors.white;
        text = isJV ? 'Admin will contact you' : 'Pending Admin';
        break;
      case OfferStatus.rejected:
        backgroundColor = AppTheme.errorColor;
        textColor = Colors.white;
        text = 'Cancelled'; // Changed from 'Rejected' to 'Cancelled'
        break;
      case OfferStatus.completed:
        backgroundColor = AppTheme.successColor;
        textColor = Colors.white;
        text = 'Completed';
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

  void _showNegotiationDetails(Negotiation negotiation) {
    showDialog(
      context: context,
      builder: (context) => DeveloperNegotiationDetailsDialog(
        negotiation: negotiation,
        onResponse: (response, counterAmount) async {
          // Handle response (Accept, Reject, Counter)
          await _handleNegotiationResponse(negotiation, response, counterAmount);
        },
      ),
    );
  }

  Future<void> _handleNegotiationResponse(
    Negotiation negotiation,
    String response,
    String? counterAmount,
  ) async {
    print('_handleNegotiationResponse called with: $response, $counterAmount');
    try {
      // Update negotiation status
      OfferStatus newStatus;
      switch (response) {
        case 'Accept':
          newStatus = OfferStatus.accepted; // This will show as "Pending Admin"
          break;
        case 'Reject':
          newStatus = OfferStatus.rejected;
          break;
        case 'Counter':
          newStatus = OfferStatus.countered;
          break;
        case 'Cancel':
          newStatus = OfferStatus.rejected; // Mark as rejected when cancelled
          break;
        default:
          return;
      }

      await _negotiationService.updateNegotiationStatus(
        negotiation.id,
        newStatus,
      );

      // If negotiation is accepted, mark the listing as sold
      if (newStatus == OfferStatus.accepted) {
        await _landListingService.markListingAsSold(negotiation.listingId);
      }

      // Add response message
      String messageContent;
      if (response == 'Counter' && counterAmount != null) {
        // Check if this is JV data (contains comma and %)
        if (counterAmount.contains(',') && counterAmount.contains('%')) {
          final parts = counterAmount.split(',');
          final landownerPercent = parts[0];
          final developerPercent = parts[1];
          messageContent = 'JV Counter: $landownerPercent Landowner, $developerPercent Developer';
        } else {
          // Buy counter
          final amount = double.parse(counterAmount);
          final formattedAmount = amount.toStringAsFixed(0).replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (Match m) => '${m[1]},',
          );
          messageContent = 'Countered with AED $formattedAmount';
        }
      } else {
        messageContent = response;
      }
      
      await _negotiationService.sendMessage(
        negotiationId: negotiation.id,
        senderId: negotiation.developerId,
        senderName: negotiation.developerName,
        senderRole: 'developer',
        content: messageContent,
      );

      // Send notification to seller
      // TODO: Implement notification service call

      if (mounted) {
        Navigator.pop(context); // Close dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Response sent successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        _loadNegotiations(); // Refresh list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending response: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
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

class DeveloperNegotiationDetailsDialog extends StatefulWidget {
  final Negotiation negotiation;
  final Function(String response, String? counterAmount) onResponse;

  const DeveloperNegotiationDetailsDialog({
    super.key,
    required this.negotiation,
    required this.onResponse,
  });

  @override
  State<DeveloperNegotiationDetailsDialog> createState() => _DeveloperNegotiationDetailsDialogState();
}

class _DeveloperNegotiationDetailsDialogState extends State<DeveloperNegotiationDetailsDialog> {
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _jvLandownerController = TextEditingController();
  final TextEditingController _jvDeveloperController = TextEditingController();
  String? _selectedResponse;
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.9,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
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
                  const CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.home,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.negotiation.listingTitle,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Text(
                          'Property Owner',
                          style: TextStyle(
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
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Messages
                    Text(
                      'Conversation',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...widget.negotiation.messages.map((message) => 
                      _buildMessageBubble(message)
                    ).toList(),

                    const SizedBox(height: 20),

                    // Response options
                    Text(
                      'Respond to Offer',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Action buttons - show different buttons based on status
                    _buildActionButtons(),

                    const SizedBox(height: 16),

                    // Counter input (only show if counter is selected)
                    if (_selectedResponse == 'Counter') ...[
                      _buildCounterInput(),
                    ],
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
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: (_selectedResponse != null && !_isSubmitting) ? _submitResponse : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Send Response'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(NegotiationMessage message) {
    final isFromDeveloper = message.senderRole == 'developer';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isFromDeveloper 
            ? MainAxisAlignment.end 
            : MainAxisAlignment.start,
        children: [
          if (!isFromDeveloper) ...[
            const CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey,
              child: Icon(
                Icons.person,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isFromDeveloper ? AppTheme.primaryColor : Colors.grey[200],
                borderRadius: BorderRadius.circular(20).copyWith(
                  bottomLeft: isFromDeveloper ? const Radius.circular(20) : const Radius.circular(4),
                  bottomRight: isFromDeveloper ? const Radius.circular(4) : const Radius.circular(20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: TextStyle(
                      color: isFromDeveloper ? Colors.white : Colors.black87,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.createdAt),
                    style: TextStyle(
                      color: isFromDeveloper ? Colors.white70 : Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isFromDeveloper) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.primaryColor,
              child: const Icon(
                Icons.business,
                color: Colors.white,
                size: 16,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    // Show different buttons based on negotiation status
    switch (widget.negotiation.status) {
      case OfferStatus.sent:
      case OfferStatus.pending:
        // Developer made offer, waiting for seller - show only Cancel
        return SizedBox(
          width: double.infinity,
          child: _buildResponseButton(
            'Cancel',
            Icons.cancel,
            AppTheme.errorColor,
            'Cancel',
          ),
        );
      case OfferStatus.countered:
        // Check who made the last counter to determine what buttons to show
        final lastMessage = widget.negotiation.messages.isNotEmpty 
            ? widget.negotiation.messages.reduce((a, b) => a.createdAt.isAfter(b.createdAt) ? a : b)
            : null;
        
        if (lastMessage != null && lastMessage.senderRole.toLowerCase() == 'developer') {
          // Developer countered, waiting for seller - show only Cancel
          return SizedBox(
            width: double.infinity,
            child: _buildResponseButton(
              'Cancel',
              Icons.cancel,
              AppTheme.errorColor,
              'Cancel',
            ),
          );
        } else {
          // Seller countered, waiting for developer - show Accept, Reject, Counter
          return Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildResponseButton(
                      'Accept',
                      Icons.check,
                      AppTheme.successColor,
                      'Accept',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildResponseButton(
                      'Reject',
                      Icons.close,
                      AppTheme.errorColor,
                      'Reject',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: _buildResponseButton(
                  'Counter',
                  Icons.swap_horiz,
                  AppTheme.primaryColor,
                  'Counter',
                ),
              ),
            ],
          );
        }
      case OfferStatus.accepted:
      case OfferStatus.rejected:
      case OfferStatus.completed:
        // Deal is done - show no action buttons
        return const SizedBox.shrink();
    }
  }

  Widget _buildCounterInput() {
    // Check if this is a JV negotiation by looking at the first message
    final isJV = widget.negotiation.messages.any((message) => 
      message.content.contains('JV Proposal') || 
      message.content.contains('% Landowner') ||
      message.content.contains('% Developer'));
    
    if (isJV) {
      // JV counter - show percentage fields
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'JV Counter Proposal',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Column(
            children: [
              TextField(
                controller: _jvLandownerController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Landowner %',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., 40',
                  suffixText: '%',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _jvDeveloperController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Developer %',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., 60',
                  suffixText: '%',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Percentages must sum to 100%',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      );
    } else {
      // Buy counter - show amount field
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _notesController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Counter Amount (AED)',
              border: OutlineInputBorder(),
              hintText: 'Enter your counter offer...',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Amount must be within ±20% of the original offer',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      );
    }
  }

  Widget _buildResponseButton(String label, IconData icon, Color color, String value) {
    final isSelected = _selectedResponse == value;
    
    return InkWell(
      onTap: () {
        setState(() {
          _selectedResponse = value;
        });
      },
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : color,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submitResponse() {
    print('_submitResponse called with: $_selectedResponse');
    if (_selectedResponse != null) {
      setState(() {
        _isSubmitting = true;
      });
      
      String? counterData;
      
      // If countering, validate the input
      if (_selectedResponse == 'Counter') {
        // Check if this is a JV negotiation
        final isJV = widget.negotiation.messages.any((message) => 
          message.content.contains('JV Proposal') || 
          message.content.contains('% Landowner') ||
          message.content.contains('% Developer'));
        
        if (isJV) {
          // JV counter - validate percentages
          final landownerText = _jvLandownerController.text.trim();
          final developerText = _jvDeveloperController.text.trim();
          
          if (landownerText.isEmpty || developerText.isEmpty) {
            setState(() {
              _isSubmitting = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please enter both percentages'),
                backgroundColor: AppTheme.errorColor,
              ),
            );
            return;
          }
          
          final landownerPercentage = double.tryParse(landownerText);
          final developerPercentage = double.tryParse(developerText);
          
          if (landownerPercentage == null || developerPercentage == null) {
            setState(() {
              _isSubmitting = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please enter valid percentages'),
                backgroundColor: AppTheme.errorColor,
              ),
            );
            return;
          }
          
          if (landownerPercentage + developerPercentage != 100.0) {
            setState(() {
              _isSubmitting = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Percentages must sum to 100%'),
                backgroundColor: AppTheme.errorColor,
              ),
            );
            return;
          }
          
          counterData = '${landownerPercentage.toInt()}%,${developerPercentage.toInt()}%';
        } else {
          // Buy counter - validate amount
          final amountText = _notesController.text.trim();
          if (amountText.isEmpty) {
            setState(() {
              _isSubmitting = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please enter a counter amount'),
                backgroundColor: AppTheme.errorColor,
              ),
            );
            return;
          }
          
          final amount = double.tryParse(amountText);
          if (amount == null) {
            setState(() {
              _isSubmitting = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please enter a valid amount'),
                backgroundColor: AppTheme.errorColor,
              ),
            );
            return;
          }
          
          // Validate ±20% rule and check for same offer
          final originalOfferMessage = widget.negotiation.messages.firstWhere(
            (msg) => msg.content.contains('Made an offer of AED'),
            orElse: () => widget.negotiation.messages.first,
          );
          
          // Extract original amount from message content
          final regex = RegExp(r'Made an offer of AED ([\d.,]+[KM]?)');
          final match = regex.firstMatch(originalOfferMessage.content);
          if (match != null) {
            final originalAmountStr = match.group(1)!;
            final originalAmount = _parseFormattedPrice(originalAmountStr);
            
            if (originalAmount != null) {
              // Check if counter is the same as current offer
              if (amount == originalAmount) {
                setState(() {
                  _isSubmitting = false;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Counter offer must be different from the current offer'),
                    backgroundColor: AppTheme.errorColor,
                  ),
                );
                return;
              }
              
              final minAmount = originalAmount * 0.8; // 20% below
              final maxAmount = originalAmount * 1.2; // 20% above
              
              if (amount < minAmount || amount > maxAmount) {
                setState(() {
                  _isSubmitting = false;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Counter offer must be within ±20% of the original offer (AED ${minAmount.toStringAsFixed(0)} to AED ${maxAmount.toStringAsFixed(0)})'),
                    backgroundColor: AppTheme.errorColor,
                  ),
                );
                return;
              }
            } else {
              // If we can't parse the original amount, show a generic error
              setState(() {
                _isSubmitting = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Unable to validate counter offer. Please try again.'),
                  backgroundColor: AppTheme.errorColor,
                ),
              );
              return;
            }
          } else {
            // If we can't find the original offer message, show a generic error
            setState(() {
              _isSubmitting = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Unable to find original offer. Please try again.'),
                backgroundColor: AppTheme.errorColor,
              ),
            );
            return;
          }
          
          counterData = amountText;
        }
      }
      
      print('Calling widget.onResponse with: $_selectedResponse, $counterData');
      widget.onResponse(_selectedResponse!, counterData);
    }
  }

  double? _parseFormattedPrice(String priceStr) {
    try {
      if (priceStr.endsWith('M')) {
        final number = double.parse(priceStr.replaceAll('M', ''));
        return number * 1000000;
      } else if (priceStr.endsWith('K')) {
        final number = double.parse(priceStr.replaceAll('K', ''));
        return number * 1000;
      } else {
        return double.parse(priceStr.replaceAll(',', ''));
      }
    } catch (e) {
      return null;
    }
  }

  String _formatTime(DateTime date) {
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

  @override
  void dispose() {
    _notesController.dispose();
    _jvLandownerController.dispose();
    _jvDeveloperController.dispose();
    super.dispose();
  }
}
