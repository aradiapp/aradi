import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:aradi/app/app.dart';
import 'package:aradi/core/services/firebase_service.dart' if (dart.library.html) 'package:aradi/core/services/firebase_service_web.dart';
import 'dart:io' show Platform;

Future<void> main() async {
  print('Starting Aradi app...');
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  print('Loading environment variables...');
  try {
    await dotenv.load(fileName: ".env");
    print('Environment variables loaded');
  } catch (e) {
    print('Could not load .env file: $e');
    print('Using default configuration...');
  }
  
  // Initialize Firebase if enabled (skip for web due to compatibility issues)
  final useFirebase = dotenv.isInitialized ? dotenv.env['USE_FIREBASE'] == 'true' : true;
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
