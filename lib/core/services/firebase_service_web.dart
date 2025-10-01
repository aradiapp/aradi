import 'package:flutter_dotenv/flutter_dotenv.dart';

class FirebaseService {
  static Future<void> initialize() async {
    try {
      // Check if Firebase should be enabled
      final useFirebase = dotenv.env['USE_FIREBASE'] == 'true';
      if (!useFirebase) {
        print('Firebase disabled via environment variable');
        return;
      }

      print('Firebase initialization skipped on web platform');
      print('Firebase features are not available in web mode');
    } catch (e) {
      print('Firebase initialization error: $e');
    }
  }

  static Future<void> configureMessaging() async {
    print('Firebase messaging not available on web platform');
  }
}
