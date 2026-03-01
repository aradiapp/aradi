/// App configuration from compile-time --dart-define only.
/// Values are in env.example. Use: dart run scripts/run_with_env.dart
///
/// Or pass explicitly, e.g.:
///   flutter run --dart-define=USE_FIREBASE=true --dart-define=FIREBASE_PROJECT_ID=aradi-app-ed624 --dart-define=FIREBASE_API_KEY=AIzaSyCiq_6o977MK_jlJXdKDmhzDrtBMViBFJY --dart-define=FIREBASE_APP_ID=1:766361317085:android:b753416f89fb5b805ef534 --dart-define=FIREBASE_MESSAGING_SENDER_ID=766361317085 --dart-define=FIREBASE_STORAGE_BUCKET=aradi-app-ed624.firebasestorage.app
class AppEnv {
  AppEnv._();

  static const String _useFirebase =
      String.fromEnvironment('USE_FIREBASE', defaultValue: 'true');
  static const String _firebaseApiKey =
      String.fromEnvironment('FIREBASE_API_KEY', defaultValue: '');
  static const String _firebaseAppId =
      String.fromEnvironment('FIREBASE_APP_ID', defaultValue: '');
  static const String _firebaseMessagingSenderId =
      String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID', defaultValue: '');
  static const String _firebaseProjectId =
      String.fromEnvironment('FIREBASE_PROJECT_ID', defaultValue: '');
  static const String _firebaseStorageBucket =
      String.fromEnvironment('FIREBASE_STORAGE_BUCKET', defaultValue: '');

  static bool get useFirebase => _useFirebase == 'true';

  static String get firebaseApiKey => _firebaseApiKey;
  static String get firebaseAppId => _firebaseAppId;
  static String get firebaseMessagingSenderId => _firebaseMessagingSenderId;
  static String get firebaseProjectId => _firebaseProjectId;
  static String get firebaseStorageBucket => _firebaseStorageBucket;

  /// True if Firebase config was provided (non-empty apiKey).
  static bool get hasFirebaseConfig => _firebaseApiKey.isNotEmpty;
}
