import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  offerReceived,
  offerAccepted,
  offerRejected,
  offerCountered,
  listingVerified,
  listingRejected,
  listingApproved,
  listingExpired,
  subscriptionExpiring,
  newMessage,
  dealCompleted,
  kycRejected,
  preferredDeveloper,
  systemAlert
}

enum NotificationPriority { low, normal, high, urgent }

class NotificationEvent {
  final String id;
  final String userId;
  final String title;
  final String body;
  final NotificationType type;
  final NotificationPriority priority;
  final Map<String, dynamic>? data;
  final String? deepLink;
  final bool isRead;
  final bool isPushSent;
  final DateTime createdAt;
  final DateTime? readAt;
  final DateTime? pushSentAt;

  const NotificationEvent({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    this.priority = NotificationPriority.normal,
    this.data,
    this.deepLink,
    this.isRead = false,
    this.isPushSent = false,
    required this.createdAt,
    this.readAt,
    this.pushSentAt,
  });

  factory NotificationEvent.fromJson(Map<String, dynamic> json) {
    return NotificationEvent(
      id: json['id'] as String,
      userId: json['userId'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      type: NotificationType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => NotificationType.systemAlert,
      ),
      priority: NotificationPriority.values.firstWhere(
        (e) => e.toString().split('.').last == json['priority'],
        orElse: () => NotificationPriority.normal,
      ),
      data: json['data'] as Map<String, dynamic>?,
      deepLink: json['deepLink'] as String?,
      isRead: json['isRead'] as bool? ?? false,
      isPushSent: json['isPushSent'] as bool? ?? false,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      readAt: json['readAt'] != null
          ? (json['readAt'] as Timestamp).toDate()
          : null,
      pushSentAt: json['pushSentAt'] != null
          ? (json['pushSentAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'body': body,
      'type': type.toString().split('.').last,
      'priority': priority.toString().split('.').last,
      'data': data,
      'deepLink': deepLink,
      'isRead': isRead,
      'isPushSent': isPushSent,
      'createdAt': Timestamp.fromDate(createdAt),
      'readAt': readAt != null ? Timestamp.fromDate(readAt!) : null,
      'pushSentAt': pushSentAt != null ? Timestamp.fromDate(pushSentAt!) : null,
    };
  }

  NotificationEvent copyWith({
    String? id,
    String? userId,
    String? title,
    String? body,
    NotificationType? type,
    NotificationPriority? priority,
    Map<String, dynamic>? data,
    String? deepLink,
    bool? isRead,
    bool? isPushSent,
    DateTime? createdAt,
    DateTime? readAt,
    DateTime? pushSentAt,
  }) {
    return NotificationEvent(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      data: data ?? this.data,
      deepLink: deepLink ?? this.deepLink,
      isRead: isRead ?? this.isRead,
      isPushSent: isPushSent ?? this.isPushSent,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
      pushSentAt: pushSentAt ?? this.pushSentAt,
    );
  }

  // Business Logic Methods
  bool get isUrgent => priority == NotificationPriority.urgent;
  bool get isHigh => priority == NotificationPriority.high;

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    
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

  // Factory methods for common notification types
  factory NotificationEvent.offerReceived({
    required String id,
    required String userId,
    required String developerName,
    required String listingTitle,
    String? deepLink,
  }) {
    return NotificationEvent(
      id: id,
      userId: userId,
      title: 'New Offer Received',
      body: '$developerName sent an offer for $listingTitle',
      type: NotificationType.offerReceived,
      priority: NotificationPriority.high,
      deepLink: deepLink,
      createdAt: DateTime.now(),
    );
  }

  factory NotificationEvent.offerAccepted({
    required String id,
    required String userId,
    required String developerName,
    required String listingTitle,
    String? deepLink,
  }) {
    return NotificationEvent(
      id: id,
      userId: userId,
      title: 'Offer Accepted!',
      body: 'Your offer for $listingTitle has been accepted by $developerName',
      type: NotificationType.offerAccepted,
      priority: NotificationPriority.urgent,
      deepLink: deepLink,
      createdAt: DateTime.now(),
    );
  }

  factory NotificationEvent.listingVerified({
    required String id,
    required String userId,
    required String listingTitle,
    String? deepLink,
  }) {
    return NotificationEvent(
      id: id,
      userId: userId,
      title: 'Listing Verified',
      body: 'Your listing "$listingTitle" has been verified and is now active',
      type: NotificationType.listingVerified,
      priority: NotificationPriority.normal,
      deepLink: deepLink,
      createdAt: DateTime.now(),
    );
  }

  factory NotificationEvent.listingApproved({
    required String id,
    required String userId,
    required String listingTitle,
    String? deepLink,
  }) {
    return NotificationEvent(
      id: id,
      userId: userId,
      title: 'Listing Approved',
      body: 'Your listing "$listingTitle" has been approved and is now live',
      type: NotificationType.listingApproved,
      priority: NotificationPriority.normal,
      deepLink: deepLink,
      createdAt: DateTime.now(),
    );
  }

  factory NotificationEvent.preferredDeveloper({
    required String id,
    required String userId,
    required String listingTitle,
    required String listingId,
    String? deepLink,
  }) {
    return NotificationEvent(
      id: id,
      userId: userId,
      title: 'You\'re a Preferred Developer!',
      body: 'You have been selected as a preferred developer for "$listingTitle"',
      type: NotificationType.preferredDeveloper,
      priority: NotificationPriority.high,
      deepLink: deepLink,
      createdAt: DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NotificationEvent && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'NotificationEvent(id: $id, type: $type, title: $title)';
  }
}
