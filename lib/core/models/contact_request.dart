import 'package:cloud_firestore/cloud_firestore.dart';

class ContactRequest {
  final String id;
  final String userId;
  final String userEmail;
  final String userName;
  final String role; // 'seller' | 'developer'
  final String subject;
  final String message;
  final DateTime createdAt;
  final String status; // 'unread' | 'read' | 'replied'
  final DateTime? adminRepliedAt;
  final String? adminReplyText;

  const ContactRequest({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.userName,
    required this.role,
    required this.subject,
    required this.message,
    required this.createdAt,
    this.status = 'unread',
    this.adminRepliedAt,
    this.adminReplyText,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userEmail': userEmail,
      'userName': userName,
      'role': role,
      'subject': subject,
      'message': message,
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status,
      if (adminRepliedAt != null) 'adminRepliedAt': Timestamp.fromDate(adminRepliedAt!),
      if (adminReplyText != null) 'adminReplyText': adminReplyText,
    };
  }

  factory ContactRequest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ContactRequest(
      id: doc.id,
      userId: data['userId'] as String,
      userEmail: data['userEmail'] as String,
      userName: data['userName'] as String,
      role: data['role'] as String,
      subject: data['subject'] as String,
      message: data['message'] as String,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: data['status'] as String? ?? 'unread',
      adminRepliedAt: data['adminRepliedAt'] != null ? (data['adminRepliedAt'] as Timestamp).toDate() : null,
      adminReplyText: data['adminReplyText'] as String?,
    );
  }

  ContactRequest copyWith({
    String? status,
    DateTime? adminRepliedAt,
    String? adminReplyText,
  }) {
    return ContactRequest(
      id: id,
      userId: userId,
      userEmail: userEmail,
      userName: userName,
      role: role,
      subject: subject,
      message: message,
      createdAt: createdAt,
      status: status ?? this.status,
      adminRepliedAt: adminRepliedAt ?? this.adminRepliedAt,
      adminReplyText: adminReplyText ?? this.adminReplyText,
    );
  }
}
