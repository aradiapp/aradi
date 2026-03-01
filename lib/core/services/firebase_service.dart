import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:aradi/core/config/app_env.dart';

class FirebaseService {
  static FirebaseApp? _app;
  static FirebaseAuth? _auth;
  static FirebaseFirestore? _firestore;
  static FirebaseStorage? _storage;
  static FirebaseMessaging? _messaging;

  static FirebaseApp get app => _app!;
  static FirebaseAuth get auth => _auth!;
  static FirebaseFirestore get firestore => _firestore!;
  static FirebaseStorage get storage => _storage!;
  static FirebaseMessaging get messaging => _messaging!;

  static Future<void> initialize() async {
    try {
      if (!AppEnv.useFirebase || !AppEnv.hasFirebaseConfig) {
        print('Firebase disabled or config not provided (use --dart-define)');
        return;
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

      // Handle foreground/background messages and open-from-notification
      await configureMessaging();

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
        final token = await _messaging!.getToken();
        if (token != null) {
          final uid = _auth!.currentUser?.uid;
          if (uid != null) {
            await _firestore!.collection('users').doc(uid).update({
              'fcmToken': token,
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }
        }
      } else {
        print('User declined notification permission');
      }
    } catch (e) {
      print('Failed to request notification permissions: $e');
    }
  }

  static Future<void> configureMessaging() async {
    try {
      // Handle background messages
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('Got a message whilst in the foreground!');
        print('Message data: ${message.data}');

        if (message.notification != null) {
          print('Message also contained a notification: ${message.notification}');
        }
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
  static bool get isEnabled => AppEnv.useFirebase && AppEnv.hasFirebaseConfig;
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
