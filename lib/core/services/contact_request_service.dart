import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:aradi/core/models/contact_request.dart';

class ContactRequestService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'contact_requests';

  /// Submit a contact request (seller or developer)
  Future<void> submitContactRequest({
    required String userId,
    required String userEmail,
    required String userName,
    required String role,
    required String subject,
    required String message,
  }) async {
    await _firestore.collection(_collection).add({
      'userId': userId,
      'userEmail': userEmail,
      'userName': userName,
      'role': role,
      'subject': subject,
      'message': message,
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'unread',
    });
  }

  /// List all contact requests (admin only)
  Stream<List<ContactRequest>> streamAllContactRequests() {
    return _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => ContactRequest.fromFirestore(d)).toList());
  }

  /// Mark as read (admin)
  Future<void> markAsRead(String requestId) async {
    await _firestore.collection(_collection).doc(requestId).update({'status': 'read'});
  }

  /// Mark as replied and store reply text (admin)
  Future<void> markAsReplied(String requestId, String replyText) async {
    await _firestore.collection(_collection).doc(requestId).update({
      'status': 'replied',
      'adminRepliedAt': FieldValue.serverTimestamp(),
      'adminReplyText': replyText,
    });
  }

  /// Get single request (admin)
  Future<ContactRequest?> getRequest(String requestId) async {
    final doc = await _firestore.collection(_collection).doc(requestId).get();
    if (doc.exists && doc.data() != null) {
      return ContactRequest.fromFirestore(doc);
    }
    return null;
  }
}
