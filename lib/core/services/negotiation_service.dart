import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:aradi/core/models/negotiation.dart';
import 'package:aradi/core/models/offer.dart';

class NegotiationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Create a new negotiation
  Future<String> createNegotiation({
    required String listingId,
    required String developerId,
    required String developerName,
    required String listingTitle,
    required String sellerId,
    required String sellerName,
  }) async {
    try {
      final negotiation = Negotiation(
        id: '', // Will be set by Firestore
        listingId: listingId,
        listingTitle: listingTitle,
        sellerId: sellerId,
        sellerName: sellerName,
        developerId: developerId,
        developerName: developerName,
        status: OfferStatus.sent,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        messages: [],
      );

      final docRef = await _firestore
          .collection('negotiations')
          .add(negotiation.toJson());

      return docRef.id;
    } catch (e) {
      print('Error creating negotiation: $e');
      throw Exception('Failed to create negotiation: $e');
    }
  }

  /// Send a message in a negotiation
  Future<String> sendMessage({
    required String negotiationId,
    required String senderId,
    required String senderName,
    required String senderRole,
    required String content,
  }) async {
    try {
      final message = NegotiationMessage(
        id: '', // Will be set by Firestore
        negotiationId: negotiationId,
        senderId: senderId,
        senderName: senderName,
        senderRole: senderRole,
        type: NegotiationType.message,
        content: content,
        createdAt: DateTime.now(),
      );

      // Add message to negotiation
      final docRef = await _firestore
          .collection('negotiations')
          .doc(negotiationId)
          .collection('messages')
          .add(message.toJson());

      // Update negotiation timestamp
      await _firestore
          .collection('negotiations')
          .doc(negotiationId)
          .update({
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return docRef.id;
    } catch (e) {
      print('Error sending message: $e');
      throw Exception('Failed to send message: $e');
    }
  }

  /// Get all negotiations (for admin use)
  Future<List<Negotiation>> getAllNegotiations() async {
    try {
      final snapshot = await _firestore
          .collection('negotiations')
          .orderBy('createdAt', descending: true)
          .get();

      final negotiations = <Negotiation>[];
      
      for (final doc in snapshot.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        final negotiation = Negotiation.fromJson(data);
        
        // Get messages for this negotiation
        final messagesQuery = await _firestore
            .collection('negotiations')
            .doc(doc.id)
            .collection('messages')
            .orderBy('createdAt', descending: false)
            .get();
        
        final messages = messagesQuery.docs
            .map((messageDoc) {
              final messageData = messageDoc.data();
              messageData['id'] = messageDoc.id;
              return NegotiationMessage.fromJson(messageData);
            })
            .toList();
        
        negotiations.add(negotiation.copyWith(messages: messages));
      }

      return negotiations;
    } catch (e) {
      print('Error getting all negotiations: $e');
      throw Exception('Failed to get negotiations: $e');
    }
  }

  /// Get negotiations for a user
  Future<List<Negotiation>> getNegotiationsForUser(String userId, String userRole) async {
    try {
      Query query;
      
      if (userRole == 'developer') {
        query = _firestore
            .collection('negotiations')
            .where('developerId', isEqualTo: userId);
      } else if (userRole == 'seller') {
        query = _firestore
            .collection('negotiations')
            .where('sellerId', isEqualTo: userId);
      } else {
        throw Exception('Invalid user role: $userRole');
      }

      final querySnapshot = await query.get();
      
      final negotiations = <Negotiation>[];
      for (final doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; // Add the document ID to the data
        final negotiation = Negotiation.fromJson(data);
        
        // Get messages for this negotiation
        final messagesQuery = await _firestore
            .collection('negotiations')
            .doc(doc.id)
            .collection('messages')
            .orderBy('createdAt', descending: false)
            .get();

        final messages = messagesQuery.docs
            .map((messageDoc) {
              final messageData = messageDoc.data();
              messageData['id'] = messageDoc.id; // Add the document ID to the message data
              return NegotiationMessage.fromJson(messageData);
            })
            .toList();

        negotiations.add(negotiation.copyWith(messages: messages));
      }

      // Sort by updatedAt descending on the client side
      negotiations.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      return negotiations;
    } catch (e) {
      print('Error fetching negotiations: $e');
      return [];
    }
  }

  /// Get a specific negotiation with messages
  Future<Negotiation?> getNegotiationWithMessages(String negotiationId) async {
    try {
      final negotiationDoc = await _firestore
          .collection('negotiations')
          .doc(negotiationId)
          .get();

      if (!negotiationDoc.exists) {
        return null;
      }

      final data = negotiationDoc.data()!;
      data['id'] = negotiationDoc.id; // Add the document ID to the data
      final negotiation = Negotiation.fromJson(data);

      // Get messages
      final messagesQuery = await _firestore
          .collection('negotiations')
          .doc(negotiationId)
          .collection('messages')
          .orderBy('createdAt', descending: false)
          .get();

      final messages = messagesQuery.docs
          .map((doc) {
            final messageData = doc.data();
            messageData['id'] = doc.id; // Add the document ID to the message data
            return NegotiationMessage.fromJson(messageData);
          })
          .toList();

      return negotiation.copyWith(messages: messages);
    } catch (e) {
      print('Error fetching negotiation with messages: $e');
      return null;
    }
  }

  /// Update negotiation status
  Future<void> updateNegotiationStatus(String negotiationId, OfferStatus status) async {
    try {
      await _firestore
          .collection('negotiations')
          .doc(negotiationId)
          .update({
        'status': status.toString().split('.').last,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating negotiation status: $e');
      throw Exception('Failed to update negotiation status: $e');
    }
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
      case OfferStatus.pending:
        content = 'Offer pending';
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
      case OfferStatus.completed:
        content = 'Deal completed';
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
      case OfferStatus.pending:
        return 3; // Medium priority
      case OfferStatus.countered:
        return 2; // High priority
      case OfferStatus.accepted:
        return 1; // Low priority
      case OfferStatus.rejected:
        return 1; // Low priority
      case OfferStatus.completed:
        return 0; // No priority - completed
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
      case OfferStatus.pending:
        return 'Within 24 hours';
      case OfferStatus.countered:
        return 'Within 48 hours';
      case OfferStatus.accepted:
        return 'No response needed';
      case OfferStatus.rejected:
        return 'No response needed';
      case OfferStatus.completed:
        return 'Deal completed';
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

