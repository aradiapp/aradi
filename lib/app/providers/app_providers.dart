// Export all data providers
export 'data_providers.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:aradi/app/router/app_router.dart';

// Theme Mode Provider
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

// App Router Provider
final appRouterProvider = Provider<GoRouter>((ref) => AppRouter.router);
