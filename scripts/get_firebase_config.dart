import 'dart:io';

void main() {
  print('🔥 Firebase Configuration Helper');
  print('================================');
  print('');
  print('Follow these steps to get your Firebase configuration:');
  print('');
  print('1. Go to Firebase Console: https://console.firebase.google.com/');
  print('2. Select your project (or create one)');
  print('3. Go to Project Settings (gear icon) → General');
  print('4. Scroll down to "Your apps" section');
  print('5. Click on your Android app (or add one if not exists)');
  print('');
  print('You need these values:');
  print('----------------------');
  print('• Project ID: Found in Project Settings → General');
  print('• Web API Key: Found in Project Settings → General');
  print('• App ID: Found in your app configuration');
  print('• Messaging Sender ID: Found in your app configuration');
  print('• Storage Bucket: Usually {project-id}.appspot.com');
  print('');
  print('Values are in env.example. Run with:  dart run scripts/run_with_env.dart');
  print('Or pass at build/run time:');
  print('');
  print('  flutter run --dart-define=USE_FIREBASE=true \\');
  print('    --dart-define=FIREBASE_PROJECT_ID=aradi-app-ed624 \\');
  print('    --dart-define=FIREBASE_API_KEY=AIzaSyCiq_6o977MK_jlJXdKDmhzDrtBMViBFJY \\');
  print('    --dart-define=FIREBASE_APP_ID=1:766361317085:android:b753416f89fb5b805ef534 \\');
  print('    --dart-define=FIREBASE_MESSAGING_SENDER_ID=766361317085 \\');
  print('    --dart-define=FIREBASE_STORAGE_BUCKET=aradi-app-ed624.firebasestorage.app');
  print('');
  print('Don\'t forget to:');
  print('• Download google-services.json for Android');
  print('• Download GoogleService-Info.plist for iOS');
  print('• Enable Authentication, Firestore, and Storage');
  print('• Deploy security rules: firebase deploy --only firestore:rules');
}
