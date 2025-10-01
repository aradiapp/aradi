import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

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
      // Check if Firebase should be enabled
      final useFirebase = dotenv.env['USE_FIREBASE'] == 'true';
      if (!useFirebase) {
        print('Firebase disabled via environment variable');
        return;
      }

      // Initialize Firebase
      _app = await Firebase.initializeApp(
        options: FirebaseOptions(
          apiKey: dotenv.env['FIREBASE_API_KEY'] ?? "your_api_key_here",
          appId: dotenv.env['FIREBASE_APP_ID'] ?? "your_app_id_here",
          messagingSenderId: dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ?? "your_sender_id_here",
          projectId: dotenv.env['FIREBASE_PROJECT_ID'] ?? "aradi-app",
          storageBucket: dotenv.env['FIREBASE_STORAGE_BUCKET'] ?? "aradi-app.appspot.com",
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

      // Request notification permissions
      await _requestNotificationPermissions();

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
        
        // Get FCM token
        final token = await _messaging!.getToken();
        if (token != null) {
          print('FCM Token: $token');
          // Store token in user profile or send to backend
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

      // Check if app was opened from notification
      final initialMessage = await _messaging!.getInitialMessage();
      if (initialMessage != null) {
        print('App opened from notification');
        _handleDeepLink(initialMessage.data);
      }
    } catch (e) {
      print('Failed to configure messaging: $e');
    }
  }

  static void _handleDeepLink(Map<String, dynamic> data) {
    // Handle deep linking based on notification data
    final type = data['type'];
    final id = data['id'];
    
    switch (type) {
      case 'offer':
        // Navigate to offer details
        break;
      case 'listing':
        // Navigate to listing details
        break;
      case 'negotiation':
        // Navigate to negotiation thread
        break;
      default:
        // Default navigation
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
  static bool get isEnabled => dotenv.env['USE_FIREBASE'] == 'true';
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
