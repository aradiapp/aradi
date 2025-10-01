import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:aradi/core/models/offer.dart';

enum NegotiationType { offer, counter, message }

class NegotiationMessage {
  final String id;
  final String negotiationId;
  final String senderId;
  final String senderName;
  final String senderRole;
  final NegotiationType type;
  final String content;
  final Offer? offer; // For offer/counter messages
  final DateTime createdAt;
  final bool isRead;

  const NegotiationMessage({
    required this.id,
    required this.negotiationId,
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    required this.type,
    required this.content,
    this.offer,
    required this.createdAt,
    this.isRead = false,
  });

  factory NegotiationMessage.fromJson(Map<String, dynamic> json) {
    return NegotiationMessage(
      id: json['id'] as String,
      negotiationId: json['negotiationId'] as String,
      senderId: json['senderId'] as String,
      senderName: json['senderName'] as String,
      senderRole: json['senderRole'] as String,
      type: NegotiationType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => NegotiationType.message,
      ),
      content: json['content'] as String,
      offer: json['offer'] != null
          ? Offer.fromJson(json['offer'] as Map<String, dynamic>)
          : null,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      isRead: json['isRead'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'negotiationId': negotiationId,
      'senderId': senderId,
      'senderName': senderName,
      'senderRole': senderRole,
      'type': type.toString().split('.').last,
      'content': content,
      'offer': offer?.toJson(),
      'createdAt': Timestamp.fromDate(createdAt),
      'isRead': isRead,
    };
  }

  NegotiationMessage copyWith({
    String? id,
    String? negotiationId,
    String? senderId,
    String? senderName,
    String? senderRole,
    NegotiationType? type,
    String? content,
    Offer? offer,
    DateTime? createdAt,
    bool? isRead,
  }) {
    return NegotiationMessage(
      id: id ?? this.id,
      negotiationId: negotiationId ?? this.negotiationId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderRole: senderRole ?? this.senderRole,
      type: type ?? this.type,
      content: content ?? this.content,
      offer: offer ?? this.offer,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NegotiationMessage && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'NegotiationMessage(id: $id, type: $type, sender: $senderName)';
  }
}

class Negotiation {
  final String id;
  final String listingId;
  final String listingTitle;
  final String sellerId;
  final String sellerName;
  final String developerId;
  final String developerName;
  final List<NegotiationMessage> messages;
  final OfferStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastMessageAt;

  const Negotiation({
    required this.id,
    required this.listingId,
    required this.listingTitle,
    required this.sellerId,
    required this.sellerName,
    required this.developerId,
    required this.developerName,
    this.messages = const [],
    this.status = OfferStatus.sent,
    required this.createdAt,
    required this.updatedAt,
    this.lastMessageAt,
  });

  factory Negotiation.fromJson(Map<String, dynamic> json) {
    return Negotiation(
      id: json['id'] as String,
      listingId: json['listingId'] as String,
      listingTitle: json['listingTitle'] as String,
      sellerId: json['sellerId'] as String,
      sellerName: json['sellerName'] as String,
      developerId: json['developerId'] as String,
      developerName: json['developerName'] as String,
      messages: (json['messages'] as List<dynamic>?)
          ?.map((e) => NegotiationMessage.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      status: OfferStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => OfferStatus.sent,
      ),
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: (json['updatedAt'] as Timestamp).toDate(),
      lastMessageAt: json['lastMessageAt'] != null
          ? (json['lastMessageAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'listingId': listingId,
      'listingTitle': listingTitle,
      'sellerId': sellerId,
      'sellerName': sellerName,
      'developerId': developerId,
      'developerName': developerName,
      'messages': messages.map((e) => e.toJson()).toList(),
      'status': status.toString().split('.').last,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'lastMessageAt': lastMessageAt != null ? Timestamp.fromDate(lastMessageAt!) : null,
    };
  }

  Negotiation copyWith({
    String? id,
    String? listingId,
    String? listingTitle,
    String? sellerId,
    String? sellerName,
    String? developerId,
    String? developerName,
    List<NegotiationMessage>? messages,
    OfferStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastMessageAt,
  }) {
    return Negotiation(
      id: id ?? this.id,
      listingId: listingId ?? this.listingId,
      listingTitle: listingTitle ?? this.listingTitle,
      sellerId: sellerId ?? this.sellerId,
      sellerName: sellerName ?? this.sellerName,
      developerId: developerId ?? this.developerId,
      developerName: developerName ?? this.developerName,
      messages: messages ?? this.messages,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
    );
  }

  // Business Logic Methods
  bool get hasUnreadMessages {
    return messages.any((message) => !message.isRead);
  }

  int get unreadCount {
    return messages.where((message) => !message.isRead).length;
  }

  NegotiationMessage? get lastMessage {
    if (messages.isEmpty) return null;
    return messages.reduce((a, b) => a.createdAt.isAfter(b.createdAt) ? a : b);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Negotiation && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Negotiation(id: $id, listing: $listingTitle, status: $status)';
  }
}
