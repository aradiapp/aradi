import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aradi/app/theme/app_theme.dart';
import 'package:aradi/app/navigation/main_navigation.dart';
import 'package:aradi/core/models/user.dart';
import 'package:aradi/app/providers/data_providers.dart';
import 'package:aradi/features/onboarding/screens/splash_page.dart';
import 'package:aradi/features/onboarding/screens/role_select_page.dart';
import 'package:aradi/features/onboarding/screens/kyc_page.dart';
import 'package:aradi/features/auth/screens/auth_page.dart';
import 'package:aradi/features/developer/screens/dev_home_page.dart';
import 'package:aradi/features/developer/screens/dev_browse_page.dart';
import 'package:aradi/features/developer/screens/dev_analytics_page.dart';
import 'package:aradi/features/developer/screens/listing_detail_page.dart';
import 'package:aradi/features/developer/screens/dev_profile_form_page.dart';
import 'package:aradi/features/developer/screens/dev_profile_edit_page.dart';
import 'package:aradi/features/buyer/screens/buyer_paywall_page.dart';
import 'package:aradi/features/buyer/screens/buyer_home_page.dart';
import 'package:aradi/features/buyer/screens/buyer_browse_page.dart';
import 'package:aradi/features/buyer/screens/buyer_listing_detail_page.dart';
import 'package:aradi/features/buyer/screens/buyer_profile_page.dart';
import 'package:aradi/features/buyer/screens/buyer_profile_edit_page.dart';
import 'package:aradi/features/seller/screens/seller_home_page.dart';
import 'package:aradi/features/seller/screens/land_form_page.dart';
import 'package:aradi/features/seller/screens/seller_land_listing_page.dart';
import 'package:aradi/features/seller/screens/edit_listing_page.dart';
import 'package:aradi/features/seller/screens/seller_browse_page.dart';
import 'package:aradi/features/seller/screens/seller_developer_detail_page.dart';
import 'package:aradi/features/seller/screens/seller_negotiations_page.dart';
import 'package:aradi/features/seller/screens/seller_profile_page.dart';
import 'package:aradi/features/seller/screens/seller_profile_edit_page.dart';
import 'package:aradi/features/developer/screens/developer_negotiations_page.dart';
import 'package:aradi/features/negotiations/screens/inbox_page.dart';
import 'package:aradi/features/negotiations/screens/thread_page.dart';
import 'package:aradi/features/negotiations/screens/agreement_page.dart';
import 'package:aradi/features/admin/screens/contract_queue_page.dart';
import 'package:aradi/features/admin/screens/admin_home_page.dart';
import 'package:aradi/features/admin/screens/admin_verification_page.dart';
import 'package:aradi/features/admin/screens/admin_settings_page.dart';
import 'package:aradi/features/notifications/screens/notifications_page.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/',
    // Add redirect logic to handle navigation
    redirect: (context, state) {
      // Get the current auth state
      final container = ProviderScope.containerOf(context);
      final authState = container.read(authStateProvider);
      
      // Wait for auth state to be determined
      return authState.when(
        data: (user) {
          // If user is authenticated, redirect to appropriate dashboard
          if (user != null) {
            // If trying to access auth/onboarding pages while logged in, redirect to dashboard
            if (state.matchedLocation == '/' || 
                state.matchedLocation == '/role' || 
                state.matchedLocation == '/auth' ||
                state.matchedLocation.startsWith('/kyc/')) {
              switch (user.role) {
                case UserRole.developer:
                  return '/dev';
                case UserRole.buyer:
                  return '/buyer';
                case UserRole.seller:
                  return '/seller';
                case UserRole.admin:
                  return '/admin';
              }
            }
            return null; // Allow navigation to protected routes
          } else {
            // User not authenticated - ALWAYS redirect to auth for any protected route
            if (state.matchedLocation != '/' && 
                state.matchedLocation != '/role' && 
                state.matchedLocation != '/auth' &&
                !state.matchedLocation.startsWith('/kyc/')) {
              return '/auth';
            }
            return null; // Allow navigation to public routes
          }
        },
        loading: () {
          // While loading, if trying to access protected routes, redirect to auth
          if (state.matchedLocation != '/' && 
              state.matchedLocation != '/role' && 
              state.matchedLocation != '/auth' &&
              !state.matchedLocation.startsWith('/kyc/')) {
            return '/auth';
          }
          return null; // Don't redirect while loading for public routes
        },
        error: (error, stack) => '/auth', // Redirect to auth on error
      );
    },
    routes: [
      // Onboarding Routes
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: '/role',
        builder: (context, state) => const RoleSelectPage(),
      ),
      GoRoute(
        path: '/kyc/:role',
        builder: (context, state) {
          final role = state.pathParameters['role']!;
          return KYCPage(role: role);
        },
      ),
      
      // Auth Routes
      GoRoute(
        path: '/auth',
        builder: (context, state) => const AuthPage(),
      ),
      
      // Developer Routes
      GoRoute(
        path: '/dev',
        redirect: (context, state) => '/dev/browse', // Redirect to listings
      ),
      GoRoute(
        path: '/dev/listing/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ListingDetailPage(listingId: id);
        },
      ),
        GoRoute(
          path: '/dev/profile',
          builder: (context, state) => MainNavigation(
            userRole: UserRole.developer,
            child: const DevProfileFormPage(),
          ),
        ),
        GoRoute(
          path: '/dev/profile/edit',
          builder: (context, state) => MainNavigation(
            userRole: UserRole.developer,
            child: const DevProfileEditPage(),
          ),
        ),
      GoRoute(
        path: '/dev/browse',
        builder: (context, state) => MainNavigation(
          userRole: UserRole.developer,
          child: const DevBrowsePage(),
        ),
      ),
      GoRoute(
        path: '/dev/analytics',
        builder: (context, state) => MainNavigation(
          userRole: UserRole.developer,
          child: const DevAnalyticsPage(),
        ),
      ),
      GoRoute(
        path: '/dev/negotiations',
        builder: (context, state) => MainNavigation(
          userRole: UserRole.developer,
          child: const DeveloperNegotiationsPage(),
        ),
      ),
      
      // Buyer Routes
      GoRoute(
        path: '/buyer',
        builder: (context, state) => MainNavigation(
          userRole: UserRole.buyer,
          child: const BuyerHomePage(),
        ),
      ),
      GoRoute(
        path: '/buyer/paywall',
        builder: (context, state) => const BuyerPaywallPage(),
      ),
        GoRoute(
          path: '/buyer/profile',
          builder: (context, state) => MainNavigation(
            userRole: UserRole.buyer,
            child: const BuyerProfilePage(),
          ),
        ),
        GoRoute(
          path: '/buyer/profile/edit',
          builder: (context, state) => MainNavigation(
            userRole: UserRole.buyer,
            child: const BuyerProfileEditPage(),
          ),
        ),
      GoRoute(
        path: '/buyer/browse',
        builder: (context, state) => MainNavigation(
          userRole: UserRole.buyer,
          child: const BuyerBrowsePage(),
        ),
      ),
      GoRoute(
        path: '/buyer/listing/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return MainNavigation(
            userRole: UserRole.buyer,
            child: BuyerListingDetailPage(listingId: id),
          );
        },
      ),
      
      // Seller Routes
      GoRoute(
        path: '/seller',
        builder: (context, state) => MainNavigation(
          userRole: UserRole.seller,
          child: const SellerHomePage(),
        ),
      ),
      GoRoute(
        path: '/seller/land/add',
        builder: (context, state) => MainNavigation(
          userRole: UserRole.seller,
          child: const LandFormPage(),
        ),
      ),
      GoRoute(
        path: '/seller/listing/:id/edit',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          print('Edit route matched with id: $id');
          return MainNavigation(
            userRole: UserRole.seller,
            child: EditListingPage(listingId: id),
          );
        },
      ),
      GoRoute(
        path: '/seller/listing/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return MainNavigation(
            userRole: UserRole.seller,
            child: SellerLandListingPage(listingId: id),
          );
        },
      ),
      GoRoute(
        path: '/seller/browse',
        builder: (context, state) => MainNavigation(
          userRole: UserRole.seller,
          child: const SellerBrowsePage(),
        ),
      ),
      GoRoute(
        path: '/seller/developer/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return MainNavigation(
            userRole: UserRole.seller,
            child: SellerDeveloperDetailPage(developerId: id),
          );
        },
      ),
        GoRoute(
          path: '/seller/profile',
          builder: (context, state) => MainNavigation(
            userRole: UserRole.seller,
            child: const SellerProfilePage(),
          ),
        ),
        GoRoute(
          path: '/seller/profile/edit',
          builder: (context, state) => MainNavigation(
            userRole: UserRole.seller,
            child: const SellerProfileEditPage(),
          ),
        ),
        GoRoute(
          path: '/seller/negotiations',
          builder: (context, state) => MainNavigation(
            userRole: UserRole.seller,
            child: const SellerNegotiationsPage(),
          ),
        ),
      
      // Negotiation Routes
      GoRoute(
        path: '/neg',
        builder: (context, state) => MainNavigation(
          userRole: UserRole.developer, // Will be overridden by MainNavigation
          child: const InboxPage(),
        ),
      ),
      GoRoute(
        path: '/neg/thread/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return MainNavigation(
            userRole: UserRole.developer, // Will be overridden by MainNavigation
            child: ThreadPage(threadId: id),
          );
        },
      ),
      GoRoute(
        path: '/agreement/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return MainNavigation(
            userRole: UserRole.developer, // Will be overridden by MainNavigation
            child: AgreementPage(threadId: id),
          );
        },
      ),
      
      // Admin Routes
      GoRoute(
        path: '/admin',
        builder: (context, state) => MainNavigation(
          userRole: UserRole.admin,
          child: const AdminHomePage(),
        ),
      ),
      GoRoute(
        path: '/admin/contract-queue',
        builder: (context, state) => MainNavigation(
          userRole: UserRole.admin,
          child: const ContractQueuePage(),
        ),
      ),
      GoRoute(
        path: '/admin/verification',
        builder: (context, state) => MainNavigation(
          userRole: UserRole.admin,
          child: const AdminVerificationPage(),
        ),
      ),
      GoRoute(
        path: '/admin/settings',
        builder: (context, state) => MainNavigation(
          userRole: UserRole.admin,
          child: const AdminSettingsPage(),
        ),
      ),
      
      // Notifications Routes
      GoRoute(
        path: '/notifications',
        builder: (context, state) => MainNavigation(
          userRole: UserRole.developer, // Will be overridden by MainNavigation
          child: const NotificationsPage(),
        ),
      ),
      
      // Profile Routes (role-specific)
      GoRoute(
        path: '/profile',
        builder: (context, state) {
          // This would redirect to the appropriate profile based on user role
          // For now, default to developer profile
          return MainNavigation(
            userRole: UserRole.developer,
            child: const DevProfileFormPage(),
          );
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(
        title: const Text('Page Not Found'),
        backgroundColor: AppTheme.surfaceColor,
        foregroundColor: AppTheme.textPrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              context.go('/');
            }
          },
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppTheme.errorColor,
            ),
            const SizedBox(height: 16),
            Text(
              'Page Not Found',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'The page you are looking for does not exist.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/'),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );
}
