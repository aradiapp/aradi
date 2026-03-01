import 'package:aradi/core/config/app_env.dart';

class FirebaseService {
  static Future<void> initialize() async {
    try {
      if (!AppEnv.useFirebase || !AppEnv.hasFirebaseConfig) {
        print('Firebase disabled or config not provided (use --dart-define)');
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
