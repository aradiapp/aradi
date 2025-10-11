import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aradi/app/theme/app_theme.dart';
import 'package:aradi/core/models/user.dart';
import 'package:aradi/app/providers/data_providers.dart';
import 'package:aradi/core/config/app_config.dart';

class MainNavigation extends ConsumerStatefulWidget {
  final Widget child;
  final UserRole userRole; // Keep for backward compatibility, but will be overridden

  const MainNavigation({
    super.key,
    required this.child,
    required this.userRole,
  });

  @override
  ConsumerState<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends ConsumerState<MainNavigation> {
  int _currentIndex = 0;
  UserRole? _currentUserRole;
  bool _isLoadingRole = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserRole();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Only refresh user role if we don't have one yet
    if (_currentUserRole == null) {
      refreshUserRole();
    }
  }

  Future<void> _loadCurrentUserRole() async {
    try {
      final authService = ref.read(authServiceProvider);
      final currentUser = await authService.getCurrentUser();
      
      if (mounted) {
        setState(() {
          _currentUserRole = currentUser?.role ?? widget.userRole;
          _isLoadingRole = false;
        });
      }
    } catch (e) {
      print('Error loading user role: $e');
      if (mounted) {
        setState(() {
          _currentUserRole = widget.userRole;
          _isLoadingRole = false;
        });
      }
    }
  }

  // Method to refresh user role when needed
  Future<void> refreshUserRole() async {
    setState(() {
      _isLoadingRole = true;
      _currentUserRole = null; // Clear current role to force refresh
    });
    await _loadCurrentUserRole();
  }

  @override
  Widget build(BuildContext context) {
    // Listen to auth state changes to refresh role
    ref.listen(authStateProvider, (previous, next) {
      if (previous != next) {
        // Auth state changed, refresh the role
        refreshUserRole();
      }
    });

    // Show loading indicator while determining user role
    if (_isLoadingRole) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Loading navigation...',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Update current index based on current route
    _updateCurrentIndex();
    
    return WillPopScope(
      onWillPop: () async {
        // Handle back button navigation
        final currentRoute = GoRouterState.of(context).matchedLocation;
        
        // If we're on a main dashboard page, show exit confirmation
        if (currentRoute == '/dev' || currentRoute == '/buyer' || currentRoute == '/seller' || currentRoute == '/admin') {
          final shouldExit = await _showExitConfirmation();
          if (shouldExit == true) {
            return true; // Allow app to exit
          }
          return false; // Stay in app
        }
        
        // For other pages, use normal navigation
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
          return false; // Prevent default back behavior
        }
        
        // If can't pop, navigate to appropriate dashboard
        _navigateToDashboard();
        return false; // Prevent default back behavior
      },
      child: Scaffold(
        body: widget.child,
        bottomNavigationBar: _buildBottomNavigationBar(),
        appBar: _buildAppBar(),
      ),
    );
  }

  Future<bool?> _showExitConfirmation() async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit App'),
        content: const Text('Are you sure you want to exit the app?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Exit'),
          ),
        ],
      ),
    );
  }

  void _navigateToDashboard() {
    final currentRoute = GoRouterState.of(context).matchedLocation;
    
    // Navigate to appropriate dashboard based on current route
    if (currentRoute.startsWith('/dev')) {
      context.go('/dev');
    } else if (currentRoute.startsWith('/buyer')) {
      context.go('/buyer');
    } else if (currentRoute.startsWith('/seller')) {
      context.go('/seller');
    } else if (currentRoute.startsWith('/admin')) {
      context.go('/admin');
    } else {
      // Default to auth page if no clear role
      context.go('/auth');
    }
  }

  void _updateCurrentIndex() {
    final currentRoute = GoRouterState.of(context).matchedLocation;
    final navItems = _getNavigationItems();
    
    print('Current route: $currentRoute');
    print('Navigation items: ${navItems.map((item) => item.route).toList()}');
    
    // Find the matching route and set the current index
    for (int i = 0; i < navItems.length; i++) {
      final navRoute = navItems[i].route;
      
      // Exact match first
      if (currentRoute == navRoute) {
        _currentIndex = i;
        print('Exact match found: $navRoute at index $i');
        break;
      }
      
      // Handle negotiations routes - match any negotiations route to the negotiations tab
      if (navRoute.contains('negotiations') && currentRoute.contains('negotiations')) {
        _currentIndex = i;
        print('Negotiations route match found: $navRoute at index $i');
        break;
      }
      
      // Handle buyer negotiations (uses /neg)
      if (navRoute == '/neg' && currentRoute.startsWith('/neg')) {
        _currentIndex = i;
        print('Buyer negotiations route match found: $navRoute at index $i');
        break;
      }
      
      // Handle browse routes - match any browse route to the browse tab
      if (navRoute.contains('/browse') && currentRoute.contains('/browse')) {
        _currentIndex = i;
        print('Browse route match found: $navRoute at index $i');
        break;
      }
      
      // Handle notifications routes
      if (navRoute == '/notifications' && currentRoute == '/notifications') {
        _currentIndex = i;
        print('Notifications route match found: $navRoute at index $i');
        break;
      }
      
      // Handle home routes (only exact matches or routes that don't contain /browse or /profile or /negotiations)
      if ((navRoute == '/buyer' && (currentRoute == '/buyer' || (currentRoute.startsWith('/buyer') && !currentRoute.contains('/browse') && !currentRoute.contains('/profile') && !currentRoute.contains('/land/add')))) ||
          (navRoute == '/seller' && (currentRoute == '/seller' || (currentRoute.startsWith('/seller') && !currentRoute.contains('/browse') && !currentRoute.contains('/profile') && !currentRoute.contains('/land/add') && !currentRoute.contains('/negotiations'))))) {
        _currentIndex = i;
        print('Home route match found: $navRoute at index $i');
        break;
      }
      
      // Handle developer default route - redirect to listings (but NOT for negotiations)
      if (currentRoute == '/dev' || (currentRoute.startsWith('/dev') && !currentRoute.contains('/browse') && !currentRoute.contains('/profile') && !currentRoute.contains('/analytics') && !currentRoute.contains('/negotiations'))) {
        // Default to listings for developers
        if (navRoute == '/dev/browse') {
          _currentIndex = i;
          print('Developer default route redirected to listings: $navRoute at index $i');
          break;
        }
      }
    }
    
    print('Final current index: $_currentIndex');
  }

  PreferredSizeWidget? _buildAppBar() {
    final currentRoute = GoRouterState.of(context).matchedLocation;
    
    // Don't show AppBar for profile pages as they have their own headers
    final isProfilePage = currentRoute.contains('/profile');
    
    // Show AppBar for all other pages
    if (isProfilePage) return null;
    
    return AppBar(
      title: Text(_getAppBarTitle()),
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      automaticallyImplyLeading: false,
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      actions: _getAppBarActions(),
    );
  }

  String _getAppBarTitle() {
    final currentRoute = GoRouterState.of(context).matchedLocation;
        if (currentRoute.contains('/buyer/listing/')) return ''; // Remove duplicate title for buyer listing pages
        if (currentRoute.contains('/seller/listing/') && currentRoute.contains('/edit')) return '';
        if (currentRoute.contains('/seller/listing/')) return ''; // Remove duplicate title for seller listing pages
    if (currentRoute.contains('/dev/listing/')) return ''; // Remove duplicate title for developer listing pages
    if (currentRoute.contains('/thread/')) return 'Negotiation';
    if (currentRoute.contains('/agreement/')) return 'Agreement';
    if (currentRoute.contains('/land/add')) return 'Add Listing';
    if (currentRoute.contains('/notifications')) return 'Notifications';
    if (currentRoute.contains('/neg') || currentRoute.contains('/negotiations')) return 'Negotiations';
    if (currentRoute == '/dev') return 'Listings'; // Redirected to browse
    if (currentRoute == '/buyer') return 'Buyer Dashboard';
    if (currentRoute == '/seller') return 'Seller Dashboard';
    if (currentRoute == '/admin') return '';
    if (currentRoute == '/admin/verification') return '';
    if (currentRoute == '/admin/settings') return '';
    if (currentRoute == '/admin/contract-queue') return '';
    if (currentRoute.contains('/dev/browse')) return 'Listings';
    if (currentRoute.contains('/seller/browse')) return 'Developers';
    if (currentRoute.contains('/analytics')) return 'Analytics';
    return AppConfig.appName;
  }

  String _getHomeRoute() {
    // Use dynamically loaded role or fallback to passed role
    final userRole = _currentUserRole ?? widget.userRole;
    
    switch (userRole) {
      case UserRole.developer:
        return '/dev/browse'; // Default to listings
      case UserRole.buyer:
        return '/buyer';
      case UserRole.seller:
        return '/seller';
      case UserRole.admin:
        return '/admin';
    }
  }

  List<Widget>? _getAppBarActions() {
    final currentRoute = GoRouterState.of(context).matchedLocation;
    if (currentRoute.contains('/notifications')) {
      return [
        IconButton(
          icon: const Icon(Icons.mark_email_read),
          onPressed: () {
            // This would trigger the mark all as read functionality
            // For now, just show a snackbar
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('All notifications marked as read'),
                backgroundColor: AppTheme.successColor,
              ),
            );
          },
        ),
      ];
    }
    return null;
  }

  Widget _buildBottomNavigationBar() {
    final navItems = _getNavigationItems();
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: navItems.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isSelected = _currentIndex == index;
              
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _currentIndex = index;
                    });
                    context.go(item.route);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          item.icon,
                          color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
                          size: 22,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.label,
                          style: TextStyle(
                            color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
                            fontSize: 10,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  List<NavigationItem> _getNavigationItems() {
    // Use dynamically loaded role or fallback to passed role
    final userRole = _currentUserRole ?? widget.userRole;
    
    List<NavigationItem> result;
    switch (userRole) {
      case UserRole.developer:
        result = [
          NavigationItem(
            icon: Icons.list_alt,
            label: 'Listings',
            route: '/dev/browse',
          ),
          NavigationItem(
            icon: Icons.analytics,
            label: 'Analytics',
            route: '/dev/analytics',
          ),
          NavigationItem(
            icon: Icons.chat,
            label: 'Negotiations',
            route: '/dev/negotiations',
          ),
          NavigationItem(
            icon: Icons.notifications,
            label: 'Alerts',
            route: '/notifications',
          ),
          NavigationItem(
            icon: Icons.person,
            label: 'Profile',
            route: '/dev/profile',
          ),
        ];
        break;
      case UserRole.buyer:
        result = [
          NavigationItem(
            icon: Icons.home,
            label: 'Home',
            route: '/buyer',
          ),
          NavigationItem(
            icon: Icons.search,
            label: 'Browse',
            route: '/buyer/browse',
          ),
          NavigationItem(
            icon: Icons.chat,
            label: 'Negotiations',
            route: '/neg',
          ),
          NavigationItem(
            icon: Icons.notifications,
            label: 'Alerts',
            route: '/notifications',
          ),
          NavigationItem(
            icon: Icons.person,
            label: 'Profile',
            route: '/buyer/profile',
          ),
        ];
        break;
      case UserRole.seller:
        result = [
          NavigationItem(
            icon: Icons.home,
            label: 'Home',
            route: '/seller',
          ),
          NavigationItem(
            icon: Icons.search,
            label: 'Browse',
            route: '/seller/browse',
          ),
          NavigationItem(
            icon: Icons.chat,
            label: 'Negotiations',
            route: '/seller/negotiations',
          ),
          NavigationItem(
            icon: Icons.notifications,
            label: 'Alerts',
            route: '/notifications',
          ),
          NavigationItem(
            icon: Icons.person,
            label: 'Profile',
            route: '/seller/profile',
          ),
        ];
        break;
      case UserRole.admin:
        result = [
          NavigationItem(
            icon: Icons.person,
            label: 'KYC',
            route: '/admin',
          ),
          NavigationItem(
            icon: Icons.list_alt,
            label: 'Listings',
            route: '/admin/verification',
          ),
          NavigationItem(
            icon: Icons.queue,
            label: 'Contract Queue',
            route: '/admin/contract-queue',
          ),
          NavigationItem(
            icon: Icons.settings,
            label: 'Settings',
            route: '/admin/settings',
          ),
        ];
        break;
    }
    
    return result;
  }
}

class NavigationItem {
  final IconData icon;
  final String label;
  final String route;

  NavigationItem({
    required this.icon,
    required this.label,
    required this.route,
  });
}
