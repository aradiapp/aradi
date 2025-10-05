import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:aradi/core/models/notification_event.dart';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Initialize notification service
  Future<void> initialize() async {
    // Request permission
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Get FCM token
    final token = await _messaging.getToken();
    if (token != null) {
      print('FCM Token: $token');
      // Store token in user profile
      await _storeFCMToken(token);
    }

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle message opened app
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
  }

  // Store FCM token in user profile
  Future<void> _storeFCMToken(String token) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'fcmToken': token,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error storing FCM token: $e');
    }
  }

  // Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    print('Received foreground message: ${message.messageId}');
    print('Message data: ${message.data}');
    
    if (message.notification != null) {
      print('Message notification: ${message.notification}');
      // Show local notification or update UI
      _showLocalNotification(message);
    }
  }

  // Handle message opened app
  void _handleMessageOpenedApp(RemoteMessage message) {
    print('App opened from notification: ${message.messageId}');
    print('Message data: ${message.data}');
    
    // Handle deep linking
    _handleDeepLink(message.data);
  }

  // Show local notification
  void _showLocalNotification(RemoteMessage message) {
    // In a real app, you would use flutter_local_notifications
    // For now, we'll just print the notification
    print('Local notification: ${message.notification?.title}');
    print('Body: ${message.notification?.body}');
  }

  // Handle deep linking
  void _handleDeepLink(Map<String, dynamic> data) {
    final type = data['type'];
    final id = data['id'];
    
    switch (type) {
      case 'offer':
        // Navigate to offer details
        print('Navigate to offer: $id');
        break;
      case 'listing':
        // Navigate to listing details
        print('Navigate to listing: $id');
        break;
      case 'negotiation':
        // Navigate to negotiation thread
        print('Navigate to negotiation: $id');
        break;
      default:
        print('Unknown deep link type: $type');
    }
  }

  // Create notification event
  Future<void> createNotificationEvent({
    required String userId,
    required NotificationType type,
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    try {
      final notification = NotificationEvent(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        type: type,
        title: title,
        body: body,
        data: data,
        isRead: false,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('notifications')
          .doc(userId)
          .collection('events')
          .doc(notification.id)
          .set(notification.toJson());

      // Send push notification
      await _sendPushNotification(userId, title, body, data);
    } catch (e) {
      print('Error creating notification event: $e');
    }
  }

  // Send push notification
  Future<void> _sendPushNotification(
    String userId,
    String title,
    String body,
    Map<String, dynamic> data,
  ) async {
    try {
      // Get user's FCM token
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final fcmToken = userDoc.data()?['fcmToken'] as String?;
      
      if (fcmToken != null) {
        // In a real app, you would send this via your backend
        // For now, we'll just print it
        print('Would send push notification to $fcmToken');
        print('Title: $title');
        print('Body: $body');
        print('Data: $data');
      }
    } catch (e) {
      print('Error sending push notification: $e');
    }
  }

  // Mark notification as read
  Future<void> markAsRead(String userId, String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(userId)
          .collection('events')
          .doc(notificationId)
          .update({'read': true});
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  // Mark all notifications as read
  Future<void> markAllAsRead(String userId) async {
    try {
      final batch = _firestore.batch();
      final notifications = await _firestore
          .collection('notifications')
          .doc(userId)
          .collection('events')
          .where('read', isEqualTo: false)
          .get();

      for (final doc in notifications.docs) {
        batch.update(doc.reference, {'read': true});
      }

      await batch.commit();
    } catch (e) {
      print('Error marking all notifications as read: $e');
    }
  }

  // Get unread notification count
  Future<int> getUnreadCount(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('notifications')
          .doc(userId)
          .collection('events')
          .where('read', isEqualTo: false)
          .get();
      
      return snapshot.docs.length;
    } catch (e) {
      print('Error getting unread count: $e');
      return 0;
    }
  }

  // Get notifications for user
  Future<List<NotificationEvent>> getNotifications(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('notifications')
          .doc(userId)
          .collection('events')
          .orderBy('createdAt', descending: true)
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return NotificationEvent.fromJson(data);
      }).toList();
    } catch (e) {
      print('Error getting notifications: $e');
      return [];
    }
  }

  // Send notification for offer received
  Future<void> notifyOfferReceived({
    required String sellerId,
    required String developerName,
    required String listingTitle,
    required String offerId,
  }) async {
    await createNotificationEvent(
      userId: sellerId,
      type: NotificationType.offerReceived,
      title: 'New Offer Received',
      body: '$developerName sent an offer for $listingTitle',
      data: {
        'type': 'offer',
        'id': offerId,
        'developerName': developerName,
        'listingTitle': listingTitle,
      },
    );
  }

  // Send notification for offer response
  Future<void> notifyOfferResponse({
    required String developerId,
    required String sellerName,
    required String listingTitle,
    required String status,
    required String offerId,
  }) async {
    await createNotificationEvent(
      userId: developerId,
        type: NotificationType.offerAccepted,
      title: 'Offer $status',
      body: '$sellerName $status your offer for $listingTitle',
      data: {
        'type': 'offer',
        'id': offerId,
        'sellerName': sellerName,
        'listingTitle': listingTitle,
        'status': status,
      },
    );
  }

  // Send notification for new message
  Future<void> notifyNewMessage({
    required String recipientId,
    required String senderName,
    required String listingTitle,
    required String negotiationId,
  }) async {
    await createNotificationEvent(
      userId: recipientId,
      type: NotificationType.newMessage,
      title: 'New Message',
      body: '$senderName sent a message about $listingTitle',
      data: {
        'type': 'negotiation',
        'id': negotiationId,
        'senderName': senderName,
        'listingTitle': listingTitle,
      },
    );
  }

  // Send notification for KYC rejection
  Future<void> notifyKycRejection({
    required String recipientId,
    required String? rejectionReason,
  }) async {
    final title = 'KYC Application Rejected';
    final body = rejectionReason != null 
        ? 'Your KYC application has been rejected. Reason: $rejectionReason'
        : 'Your KYC application has been rejected. Please review your information and resubmit.';
    
    await createNotificationEvent(
      userId: recipientId,
      type: NotificationType.kycRejected,
      title: title,
      body: body,
      data: {
        'type': 'kyc_rejection',
        'reason': rejectionReason ?? '',
      },
    );
  }
}

// Background message handler
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling background message: ${message.messageId}');
  
  // Initialize Firebase if not already done
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp();
  }
  
  // Handle background message processing
  // This could include updating local storage, showing local notifications, etc.
}
