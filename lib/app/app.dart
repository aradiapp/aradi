import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aradi/app/theme/app_theme.dart';
import 'package:aradi/app/router/app_router.dart';
import 'package:aradi/app/providers/app_providers.dart';
import 'package:aradi/core/config/app_config.dart';

class AradiApp extends ConsumerWidget {
  const AradiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    
    return MaterialApp.router(
      title: AppConfig.appName,
      // Force light theme only - ignore device theme completely
      theme: AppTheme.lightTheme.copyWith(
        // Ensure all text is visible by overriding text colors globally
        textTheme: AppTheme.lightTheme.textTheme.apply(
          bodyColor: AppTheme.textPrimary,
          displayColor: AppTheme.textPrimary,
        ),
        // Force all text to be visible
        primaryTextTheme: AppTheme.lightTheme.textTheme.apply(
          bodyColor: AppTheme.textPrimary,
          displayColor: AppTheme.textPrimary,
        ),
      ),
      // Completely disable dark theme - always use light theme
      darkTheme: AppTheme.lightTheme.copyWith(
        // Use light theme colors even for dark theme
        textTheme: AppTheme.lightTheme.textTheme.apply(
          bodyColor: AppTheme.textPrimary,
          displayColor: AppTheme.textPrimary,
        ),
        primaryTextTheme: AppTheme.lightTheme.textTheme.apply(
          bodyColor: AppTheme.textPrimary,
          displayColor: AppTheme.textPrimary,
        ),
      ),
      // Force light theme mode - ignore system settings
      themeMode: ThemeMode.light,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
