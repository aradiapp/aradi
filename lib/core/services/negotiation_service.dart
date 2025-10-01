import 'package:aradi/core/models/negotiation.dart';
import 'package:aradi/core/models/offer.dart';

class NegotiationService {
  static Negotiation createNegotiation({
    required String id,
    required String listingId,
    required String developerId,
    required String developerName,
    required String listingTitle,
    required double listingPrice,
    required String currency,
    required DateTime createdAt,
  }) {
    return Negotiation(
      id: id,
      listingId: listingId,
      listingTitle: listingTitle,
      sellerId: 'seller_1',
      sellerName: 'Seller Name',
      developerId: developerId,
      developerName: developerName,
      status: OfferStatus.sent,
      createdAt: createdAt,
      updatedAt: createdAt,
      messages: [],
    );
  }

  static NegotiationMessage sendMessage({
    required String negotiationId,
    required String senderId,
    required String senderName,
    required String senderRole,
    required String content,
  }) {
    return NegotiationMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      negotiationId: negotiationId,
      senderId: senderId,
      senderName: senderName,
      senderRole: senderRole,
      type: NegotiationType.message,
      content: content,
      createdAt: DateTime.now(),
    );
  }

  static NegotiationMessage sendOffer({
    required String negotiationId,
    required String senderId,
    required String senderName,
    required String senderRole,
    required Offer offer,
  }) {
    return NegotiationMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      negotiationId: negotiationId,
      senderId: senderId,
      senderName: senderName,
      senderRole: senderRole,
      type: NegotiationType.offer,
      content: 'New offer submitted',
      createdAt: DateTime.now(),
    );
  }

  static NegotiationMessage respondToOffer({
    required String negotiationId,
    required String senderId,
    required String senderName,
    required String senderRole,
    required OfferStatus response,
    String? notes,
  }) {
    String content;
    switch (response) {
      case OfferStatus.accepted:
        content = 'Offer accepted';
        break;
      case OfferStatus.rejected:
        content = 'Offer rejected';
        break;
      case OfferStatus.countered:
        content = 'Offer countered';
        break;
      case OfferStatus.sent:
        content = 'Response sent';
        break;
    }

    if (notes != null && notes.isNotEmpty) {
      content += ': $notes';
    }

    return NegotiationMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      negotiationId: negotiationId,
      senderId: senderId,
      senderName: senderName,
      senderRole: senderRole,
      type: NegotiationType.offer,
      content: content,
      createdAt: DateTime.now(),
    );
  }

  static bool isOfferValid(Offer offer) {
    // Basic validation - in a real app, this would be more complex
    return offer.id.isNotEmpty && 
           offer.listingId.isNotEmpty && 
           offer.developerId.isNotEmpty;
  }

  static String? getOfferValidationMessage(Offer offer) {
    if (offer.id.isEmpty) return 'Offer ID is required';
    if (offer.listingId.isEmpty) return 'Listing ID is required';
    if (offer.developerId.isEmpty) return 'Developer ID is required';
    return null;
  }

  static double calculateNegotiationScore(Negotiation negotiation) {
    // Simple scoring based on message count and activity
    double score = 0.0;
    
    // Base score for having messages
    score += negotiation.messages.length * 10;
    
    // Bonus for recent activity
    final daysSinceUpdate = DateTime.now().difference(negotiation.updatedAt).inDays;
    if (daysSinceUpdate <= 1) score += 50;
    else if (daysSinceUpdate <= 3) score += 30;
    else if (daysSinceUpdate <= 7) score += 10;
    
    return score;
  }

  static int getNegotiationPriority(Negotiation negotiation) {
    // Priority based on status and activity
    switch (negotiation.status) {
      case OfferStatus.sent:
        return 3; // Medium priority
      case OfferStatus.countered:
        return 2; // High priority
      case OfferStatus.accepted:
        return 1; // Low priority
      case OfferStatus.rejected:
        return 1; // Low priority
    }
  }

  static bool needsAttention(Negotiation negotiation) {
    // Check if negotiation needs immediate attention
    final daysSinceUpdate = DateTime.now().difference(negotiation.updatedAt).inDays;
    return daysSinceUpdate > 3 && negotiation.status == OfferStatus.sent;
  }

  static String getSuggestedResponseTime(Negotiation negotiation) {
    // Suggest response time based on status
    switch (negotiation.status) {
      case OfferStatus.sent:
        return 'Within 24 hours';
      case OfferStatus.countered:
        return 'Within 48 hours';
      case OfferStatus.accepted:
        return 'No response needed';
      case OfferStatus.rejected:
        return 'No response needed';
    }
  }

  static String generateNotificationSummary(Negotiation negotiation) {
    // Generate a summary for notifications
    final messageCount = negotiation.messages.length;
    final lastMessage = negotiation.messages.isNotEmpty 
        ? negotiation.messages.last 
        : null;
    
    if (lastMessage != null) {
      return '${negotiation.listingTitle}: ${lastMessage.content}';
    }
    
    return '${negotiation.listingTitle}: New negotiation started';
  }
}

