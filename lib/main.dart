import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aradi/app/app.dart';
import 'package:aradi/core/config/app_env.dart';
import 'package:aradi/core/services/firebase_service.dart' if (dart.library.html) 'package:aradi/core/services/firebase_service_web.dart';
import 'dart:io' show Platform;

Future<void> main() async {
  print('Starting Aradi app...');
  WidgetsFlutterBinding.ensureInitialized();

  // Config is from --dart-define only (no .env file bundled)
  final useFirebase = AppEnv.useFirebase;
  final isWeb = !Platform.isAndroid && !Platform.isIOS;
  
  print('Firebase enabled: $useFirebase, Is Web: $isWeb');
  
  if (useFirebase && !isWeb) {
    try {
      print('Initializing Firebase...');
      await FirebaseService.initialize();
      print('Firebase initialized successfully');
    } catch (e) {
      print('Firebase initialization failed: $e');
      print('Continuing without Firebase');
    }
  } else if (isWeb) {
    print('Firebase disabled for web builds due to compatibility issues');
  }
  
  print('Starting app...');
  runApp(
    const ProviderScope(
      child: AradiApp(),
    ),
  );
}
