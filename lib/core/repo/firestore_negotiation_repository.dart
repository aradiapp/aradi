import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:aradi/core/models/negotiation.dart';
import 'package:aradi/core/models/offer.dart';
import 'package:aradi/core/repo/base_repository.dart';

class FirestoreNegotiationRepository implements NegotiationRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<List<Negotiation>> getNegotiationsForUser(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('negotiations')
          .where('participants', arrayContains: userId)
          .orderBy('lastMessageAt', descending: true)
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Negotiation.fromJson(data);
      }).toList();
    } catch (e) {
      print('Error getting negotiations for user: $e');
      return [];
    }
  }

  @override
  Future<Negotiation?> getNegotiationById(String negotiationId) async {
    try {
      final doc = await _firestore.collection('negotiations').doc(negotiationId).get();
      if (!doc.exists) return null;
      
      final data = doc.data()!;
      data['id'] = doc.id;
      return Negotiation.fromJson(data);
    } catch (e) {
      print('Error getting negotiation by ID: $e');
      return null;
    }
  }

  @override
  Future<Negotiation> createNegotiation(Negotiation negotiation) async {
    try {
      final docRef = await _firestore.collection('negotiations').add(negotiation.toJson());
      return negotiation.copyWith(id: docRef.id);
    } catch (e) {
      print('Error creating negotiation: $e');
      rethrow;
    }
  }

  @override
  Future<Negotiation> updateNegotiation(Negotiation negotiation) async {
    try {
      await _firestore.collection('negotiations').doc(negotiation.id).update(negotiation.toJson());
      return negotiation;
    } catch (e) {
      print('Error updating negotiation: $e');
      rethrow;
    }
  }

  @override
  Future<List<NegotiationMessage>> getMessagesForNegotiation(String negotiationId) async {
    try {
      final snapshot = await _firestore
          .collection('negotiations')
          .doc(negotiationId)
          .collection('messages')
          .orderBy('createdAt', descending: false)
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return NegotiationMessage.fromJson(data);
      }).toList();
    } catch (e) {
      print('Error getting messages for negotiation: $e');
      return [];
    }
  }

  @override
  Future<NegotiationMessage> sendMessage(NegotiationMessage message) async {
    try {
      final docRef = await _firestore
          .collection('negotiations')
          .doc(message.negotiationId)
          .collection('messages')
          .add(message.toJson());
      
      // Update last message timestamp
      await _firestore.collection('negotiations').doc(message.negotiationId).update({
        'lastMessageAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      return message.copyWith(id: docRef.id);
    } catch (e) {
      print('Error sending message: $e');
      rethrow;
    }
  }

  @override
  Future<void> markMessagesAsRead(String negotiationId, String userId) async {
    try {
      final messagesSnapshot = await _firestore
          .collection('negotiations')
          .doc(negotiationId)
          .collection('messages')
          .where('senderId', isNotEqualTo: userId)
          .get();
      
      final batch = _firestore.batch();
      for (final doc in messagesSnapshot.docs) {
        batch.update(doc.reference, {'read': true});
      }
      await batch.commit();
    } catch (e) {
      print('Error marking messages as read: $e');
      rethrow;
    }
  }

  @override
  Future<int> getUnreadMessageCount(String userId) async {
    try {
      final negotiationsSnapshot = await _firestore
          .collection('negotiations')
          .where('participants', arrayContains: userId)
          .get();
      
      int totalUnread = 0;
      for (final negotiationDoc in negotiationsSnapshot.docs) {
        final messagesSnapshot = await _firestore
            .collection('negotiations')
            .doc(negotiationDoc.id)
            .collection('messages')
            .where('senderId', isNotEqualTo: userId)
            .where('read', isEqualTo: false)
            .get();
        
        totalUnread += messagesSnapshot.docs.length;
      }
      
      return totalUnread;
    } catch (e) {
      print('Error getting unread message count: $e');
      return 0;
    }
  }

  @override
  Future<Negotiation?> findNegotiationByListingAndDeveloper(String listingId, String developerId) async {
    try {
      final snapshot = await _firestore
          .collection('negotiations')
          .where('listingId', isEqualTo: listingId)
          .where('developerId', isEqualTo: developerId)
          .limit(1)
          .get();
      
      if (snapshot.docs.isEmpty) return null;
      
      final data = snapshot.docs.first.data();
      data['id'] = snapshot.docs.first.id;
      return Negotiation.fromJson(data);
    } catch (e) {
      print('Error finding negotiation by listing and developer: $e');
      return null;
    }
  }

  @override
  Future<void> updateNegotiationStatus(String negotiationId, OfferStatus status) async {
    try {
      await _firestore.collection('negotiations').doc(negotiationId).update({
        'status': status.toString().split('.').last,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating negotiation status: $e');
      rethrow;
    }
  }
}
