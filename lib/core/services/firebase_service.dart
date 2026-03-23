import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:aradi/core/config/app_env.dart';

class FirebaseService {
  static FirebaseApp? _app;
  static FirebaseAuth? _auth;
  static FirebaseFirestore? _firestore;
  static FirebaseStorage? _storage;
  static FirebaseMessaging? _messaging;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static FirebaseApp get app => _app!;
  static FirebaseAuth get auth => _auth!;
  static FirebaseFirestore get firestore => _firestore!;
  static FirebaseStorage get storage => _storage!;
  static FirebaseMessaging get messaging => _messaging!;

  static Future<void> initialize() async {
    try {
      if (!AppEnv.useFirebase) {
        print('Firebase disabled (USE_FIREBASE=false)');
        return;
      }

      // Prefer native config on Android/iOS (google-services.json / GoogleService-Info.plist).
      // This is required for Play Store builds because --dart-define values are not passed there.
      try {
        _app = await Firebase.initializeApp();
      } catch (e) {
        // Fallback for dev/CI runs that rely on --dart-define.
        if (!AppEnv.hasFirebaseConfig) {
          rethrow;
        }
        _app = await Firebase.initializeApp(
          options: FirebaseOptions(
            apiKey: AppEnv.firebaseApiKey,
            appId: AppEnv.firebaseAppId,
            messagingSenderId: AppEnv.firebaseMessagingSenderId,
            projectId: AppEnv.firebaseProjectId.isNotEmpty
                ? AppEnv.firebaseProjectId
                : 'aradi-app',
            storageBucket: AppEnv.firebaseStorageBucket.isNotEmpty
                ? AppEnv.firebaseStorageBucket
                : 'aradi-app.appspot.com',
          ),
        );
      }

      // Initialize services
      _auth = FirebaseAuth.instance;
      _firestore = FirebaseFirestore.instance;
      _storage = FirebaseStorage.instance;
      _messaging = FirebaseMessaging.instance;

      // Configure Firestore settings
      _firestore!.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );

      // Request notification permissions and store FCM token
      await _requestNotificationPermissions();

      // Init local notifications so we can show a heads-up when FCM arrives in foreground
      await _initLocalNotifications();

      // Handle foreground/background messages and open-from-notification
      await configureMessaging();

      // Store FCM token when we have a user (auth may restore after init)
      _listenAuthAndStoreFcmToken();

      // One-time store in case auth was already ready
      await _storeFcmTokenIfUser();

      print('Firebase initialized successfully');
    } catch (e) {
      print('Failed to initialize Firebase: $e');
      rethrow;
    }
  }

  static Future<void> _requestNotificationPermissions() async {
    try {
      final settings = await _messaging!.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('User granted notification permission');
        await _storeFcmTokenIfUser();
      } else {
        print('User declined notification permission');
      }
    } catch (e) {
      print('Failed to request notification permissions: $e');
    }
  }

  /// Store FCM token in Firestore when we have a signed-in user (so Cloud Function can send push).
  static Future<void> _storeFcmTokenIfUser() async {
    final uid = _auth?.currentUser?.uid;
    if (uid == null || _messaging == null || _firestore == null) return;
    try {
      final token = await _messaging!.getToken();
      if (token != null) {
        await _firestore!.collection('users').doc(uid).update({
          'fcmToken': token,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        print('FCM token stored for user $uid');
      }
    } catch (e) {
      print('Failed to store FCM token: $e');
    }
  }

  /// When auth state changes (e.g. user restored or just signed in), store FCM token so push works.
  static void _listenAuthAndStoreFcmToken() {
    _auth?.authStateChanges().listen((User? user) {
      if (user != null) {
        _storeFcmTokenIfUser();
      }
    });
  }

  static Future<void> _initLocalNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
    );
    const initSettings = InitializationSettings(android: android, iOS: ios);
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null && response.payload!.isNotEmpty) {
          try {
            final data = jsonDecode(response.payload!) as Map<String, dynamic>;
            _handleDeepLink(data);
          } catch (_) {}
        }
      },
    );
    // Use "default" channel to match Cloud Function and MainActivity
    const channel = AndroidNotificationChannel(
      'default',
      'Notifications',
      description: 'App and admin notifications',
      importance: Importance.high,
      playSound: true,
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  static Future<void> configureMessaging() async {
    try {
      // Handle background messages
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Handle foreground messages: show a local notification so user sees it
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('Got a message whilst in the foreground!');
        final title = message.notification?.title ?? 'Notification';
        final body = message.notification?.body ?? '';
        final payload = message.data.isNotEmpty
            ? jsonEncode(message.data)
            : null;
        _showForegroundNotification(title: title, body: body, payload: payload);
      });

      // Handle when app is opened from notification
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print('A new onMessageOpenedApp event was published!');
        print('Message data: ${message.data}');
        
        // Handle deep linking here
        _handleDeepLink(message.data);
      });

      // Check if app was opened from notification (cold start)
      final initialMessage = await _messaging!.getInitialMessage();
      if (initialMessage != null) {
        print('App opened from notification');
        _handleDeepLink(initialMessage.data);
      }

      // Refresh FCM token and keep it updated in Firestore
      _messaging!.onTokenRefresh.listen((token) async {
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid != null && _firestore != null) {
          try {
            await _firestore!.collection('users').doc(uid).update({
              'fcmToken': token,
              'updatedAt': FieldValue.serverTimestamp(),
            });
          } catch (_) {}
        }
      });
    } catch (e) {
      print('Failed to configure messaging: $e');
    }
  }

  /// Set when app is opened from a push; consumed by MainNavigation to navigate.
  static String? pendingDeepLink;

  static void clearPendingDeepLink() {
    pendingDeepLink = null;
  }

  static Future<void> _showForegroundNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const android = AndroidNotificationDetails(
      'default',
      'Notifications',
      channelDescription: 'App and admin notifications',
      importance: Importance.high,
      priority: Priority.high,
    );
    const ios = DarwinNotificationDetails();
    const details = NotificationDetails(android: android, iOS: ios);
    final id = DateTime.now().millisecondsSinceEpoch.remainder(0x7FFFFFFF);
    await _localNotifications.show(id, title, body, details, payload: payload);
  }

  static void _handleDeepLink(Map<String, dynamic>? data) {
    if (data == null) return;
    // Prefer explicit deepLink from Cloud Function / notification data
    final deepLink = data['deepLink'] as String?;
    if (deepLink != null && deepLink.isNotEmpty) {
      pendingDeepLink = deepLink;
      return;
    }
    final type = data['type'];
    final id = data['id'];
    switch (type) {
      case 'offer':
        if (id != null) pendingDeepLink = '/seller/negotiations';
        break;
      case 'listing':
        if (id != null) pendingDeepLink = '/dev/listing/$id';
        break;
      case 'negotiation':
        if (id != null) pendingDeepLink = '/neg/thread/$id';
        break;
      default:
        break;
    }
  }

  static Future<void> signOut() async {
    try {
      await _auth?.signOut();
      print('User signed out successfully');
    } catch (e) {
      print('Failed to sign out: $e');
      rethrow;
    }
  }

  static bool get isInitialized => _app != null;
  static bool get isEnabled => AppEnv.useFirebase;
}

// Background message handler
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling a background message: ${message.messageId}');
  
  // Initialize Firebase if not already done
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp();
  }
  
  // Handle background message processing
  // This could include updating local storage, showing local notifications, etc.
}
