import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:aradi/app/theme/app_theme.dart';
import 'package:aradi/core/models/negotiation.dart';
import 'package:aradi/core/models/offer.dart';

class ThreadPage extends StatefulWidget {
  final String threadId;
  const ThreadPage({super.key, required this.threadId});

  @override
  State<ThreadPage> createState() => _ThreadPageState();
}

class _ThreadPageState extends State<ThreadPage> {
  final _messageController = TextEditingController();
  final _offerAmountController = TextEditingController();
  final _offerNotesController = TextEditingController();
  late Negotiation _negotiation;
  bool _isLoading = true;
  bool _isSubmittingOffer = false;

  @override
  void initState() {
    super.initState();
    _loadNegotiation();
  }

  void _loadNegotiation() async {
    setState(() {
      _isLoading = true;
    });

    // Load negotiation from Firebase (no mock data)
    setState(() {
      _isLoading = false;
    });
  }

  Negotiation _createMockNegotiation() {
    return Negotiation(
      id: widget.threadId,
      listingId: 'listing1',
      listingTitle: 'Premium Land Plot - Dubai Marina',
      sellerId: 'seller1',
      sellerName: 'Fatima Al Zahra',
      developerId: 'dev1',
      developerName: 'Ahmed Al Mansouri',
      messages: [
        NegotiationMessage(
          id: 'msg1',
          negotiationId: widget.threadId,
          senderId: 'dev1',
          senderName: 'Ahmed Al Mansouri',
          senderRole: 'Developer',
          type: NegotiationType.message,
          content: 'Hi Fatima, I\'m very interested in your land plot. Can we discuss the development potential?',
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
        ),
        NegotiationMessage(
          id: 'msg2',
          negotiationId: widget.threadId,
          senderId: 'seller1',
          senderName: 'Fatima Al Zahra',
          senderRole: 'Seller',
          type: NegotiationType.message,
          content: 'Hello Ahmed! Absolutely, I\'d love to discuss this. What type of development are you considering?',
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
        NegotiationMessage(
          id: 'msg3',
          negotiationId: widget.threadId,
          senderId: 'dev1',
          senderName: 'Ahmed Al Mansouri',
          senderRole: 'Developer',
          type: NegotiationType.offer,
          content: 'I would like to make an offer for this property.',
          offer: Offer(
            id: 'offer1',
            listingId: 'listing1',
            developerId: 'dev1',
            developerName: 'Ahmed Al Mansouri',
            type: OfferType.buy,
            buyPrice: 2500000,
            status: OfferStatus.sent,
            notes: 'This is a competitive offer based on current market conditions.',
            createdAt: DateTime.now().subtract(const Duration(hours: 6)),
            updatedAt: DateTime.now().subtract(const Duration(hours: 6)),
          ),
          createdAt: DateTime.now().subtract(const Duration(hours: 6)),
        ),
      ],
      status: OfferStatus.sent,
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 6)),
    );
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final newMessage = NegotiationMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      negotiationId: widget.threadId,
      senderId: 'dev1',
      senderName: 'Ahmed Al Mansouri',
      senderRole: 'Developer',
      type: NegotiationType.message,
      content: _messageController.text.trim(),
      createdAt: DateTime.now(),
    );

    setState(() {
      _negotiation = _negotiation.copyWith(
        messages: [..._negotiation.messages, newMessage],
        updatedAt: DateTime.now(),
        lastMessageAt: DateTime.now(),
      );
      _messageController.clear();
    });
  }

  void _showOfferDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Submit Offer'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _offerAmountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Offer Amount (AED)',
                  prefixText: 'AED ',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _offerNotesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Offer Notes (Optional)',
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
      ),
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

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    final offer = Offer(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      listingId: _negotiation.listingId,
      developerId: 'dev1',
      developerName: 'Ahmed Al Mansouri',
      type: OfferType.buy,
      buyPrice: double.parse(_offerAmountController.text),
      status: OfferStatus.sent,
      notes: _offerNotesController.text.trim(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final offerMessage = NegotiationMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      negotiationId: widget.threadId,
      senderId: 'dev1',
      senderName: 'Ahmed Al Mansouri',
      senderRole: 'Developer',
      type: NegotiationType.offer,
      content: 'I would like to make an offer for this property.',
      offer: offer,
      createdAt: DateTime.now(),
    );

    setState(() {
      _negotiation = _negotiation.copyWith(
        messages: [..._negotiation.messages, offerMessage],
        status: OfferStatus.sent,
        updatedAt: DateTime.now(),
        lastMessageAt: DateTime.now(),
      );
      _isSubmittingOffer = false;
      _offerAmountController.clear();
      _offerNotesController.clear();
    });

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Offer submitted successfully!'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    }
  }

  void _respondToOffer(OfferStatus status) {
    String responseText = '';
    String systemMessage = '';
    
    switch (status) {
      case OfferStatus.accepted:
        responseText = 'I accept your offer. Let\'s proceed with the next steps.';
        systemMessage = 'You will receive an e-contract on your registered email within 24 hours.';
        break;
      case OfferStatus.rejected:
        responseText = 'Thank you for your offer, but I cannot accept it at this time.';
        systemMessage = 'Offer has been rejected.';
        break;
      case OfferStatus.countered:
        responseText = 'I would like to counter your offer. Let\'s discuss the terms.';
        systemMessage = 'Counter offer requested.';
        break;
      default:
        return;
    }

    // Add system message first
    final systemChipMessage = NegotiationMessage(
      id: '${DateTime.now().millisecondsSinceEpoch}_system',
      negotiationId: widget.threadId,
      senderId: 'system',
      senderName: 'System',
      senderRole: 'System',
      type: NegotiationType.message,
      content: systemMessage,
      createdAt: DateTime.now(),
    );

    // Add response message
    final responseMessage = NegotiationMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      negotiationId: widget.threadId,
      senderId: 'seller1',
      senderName: 'Fatima Al Zahra',
      senderRole: 'Seller',
      type: NegotiationType.message,
      content: responseText,
      createdAt: DateTime.now().add(const Duration(seconds: 1)),
    );

    setState(() {
      _negotiation = _negotiation.copyWith(
        messages: [..._negotiation.messages, systemChipMessage, responseMessage],
        status: status,
        updatedAt: DateTime.now(),
        lastMessageAt: DateTime.now().add(const Duration(seconds: 1)),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: Column(
        children: [
          _buildStatusBanner(),
          if (_negotiation.status == OfferStatus.sent) _buildOfferActions(),
          Expanded(
            child: _buildMessagesList(),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildStatusBanner() {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (_negotiation.status) {
      case OfferStatus.sent:
        statusColor = AppTheme.primaryColor;
        statusText = 'Offer Sent';
        statusIcon = Icons.send;
        break;
      case OfferStatus.pending:
        statusColor = AppTheme.warningColor;
        statusText = 'Offer Pending';
        statusIcon = Icons.schedule;
        break;
      case OfferStatus.countered:
        statusColor = AppTheme.warningColor;
        statusText = 'Offer Countered';
        statusIcon = Icons.swap_horiz;
        break;
      case OfferStatus.accepted:
        statusColor = AppTheme.successColor;
        statusText = 'Offer Accepted';
        statusIcon = Icons.check_circle;
        break;
      case OfferStatus.rejected:
        statusColor = AppTheme.errorColor;
        statusText = 'Offer Rejected';
        statusIcon = Icons.cancel;
        break;
      case OfferStatus.completed:
        statusColor = AppTheme.successColor;
        statusText = 'Deal Completed';
        statusIcon = Icons.check_circle_outline;
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(color: statusColor.withOpacity(0.2)),
        ),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 20),
          const SizedBox(width: 8),
          Text(
            statusText,
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const Spacer(),
          Text(
            'Last updated: ${_formatDate(_negotiation.updatedAt)}',
            style: TextStyle(
              color: statusColor.withOpacity(0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _negotiation.messages.length,
      itemBuilder: (context, index) {
        final message = _negotiation.messages[index];
        final isCurrentUser = message.senderId == 'dev1';
        final isSystem = message.senderId == 'system';
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: isSystem 
              ? _buildSystemChip(message)
              : _buildMessageBubble(message, isCurrentUser),
        );
      },
    );
  }

  Widget _buildSystemChip(NegotiationMessage message) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.info_outline,
              size: 16,
              color: AppTheme.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              message.content,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(NegotiationMessage message, bool isCurrentUser) {
    return Row(
      mainAxisAlignment: isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isCurrentUser) ...[
          CircleAvatar(
            radius: 16,
            backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
            child: Text(
              message.senderName[0],
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
        
        Flexible(
          child: Column(
            crossAxisAlignment: isCurrentUser 
                ? CrossAxisAlignment.end 
                : CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                children: [
                  Text(
                    message.senderName,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatTime(message.createdAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              
              Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.75,
                ),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isCurrentUser ? AppTheme.primaryColor : Colors.white,
                  borderRadius: BorderRadius.circular(16),
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
                    if (message.type == NegotiationType.offer && message.offer != null)
                      _buildOfferCard(message.offer!),
                    if (message.content.isNotEmpty) ...[
                      if (message.type == NegotiationType.offer && message.offer != null)
                        const SizedBox(height: 8),
                      Text(
                        message.content,
                        style: TextStyle(
                          color: isCurrentUser ? Colors.white : AppTheme.textPrimary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        
        if (isCurrentUser) ...[
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 16,
            backgroundColor: AppTheme.primaryColor,
            child: const Icon(
              Icons.person,
              color: Colors.white,
              size: 16,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildOfferCard(Offer offer) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.attach_money,
                size: 16,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(width: 4),
              Text(
                'OFFER',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'AED ${(offer.buyPrice! / 1000000).toStringAsFixed(1)}M',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (offer.notes != null && offer.notes!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              offer.notes!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOfferActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.warningColor.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(color: AppTheme.warningColor.withOpacity(0.2)),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.attach_money, color: AppTheme.warningColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Respond to Offer',
                style: TextStyle(
                  color: AppTheme.warningColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _respondToOffer(OfferStatus.rejected),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.errorColor,
                    side: BorderSide(color: AppTheme.errorColor),
                  ),
                  child: const Text('Reject'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _respondToOffer(OfferStatus.countered),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.warningColor,
                    side: BorderSide(color: AppTheme.warningColor),
                  ),
                  child: const Text('Counter'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _respondToOffer(OfferStatus.accepted),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.successColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Accept'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: AppTheme.borderColor),
        ),
      ),
      child: Column(
        children: [
          // Quick action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _showOfferDialog,
                  icon: const Icon(Icons.attach_money, size: 16),
                  label: const Text('Make Offer'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // Navigate to final agreement page
                    context.go('/agreement/${widget.threadId}');
                  },
                  icon: const Icon(Icons.handshake, size: 16),
                  label: const Text('Final Agreement'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Message input
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: 'Type your message...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: _sendMessage,
                icon: const Icon(Icons.send),
                style: IconButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(12),
                ),
              ),
            ],
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

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _messageController.dispose();
    _offerAmountController.dispose();
    _offerNotesController.dispose();
    super.dispose();
  }
}