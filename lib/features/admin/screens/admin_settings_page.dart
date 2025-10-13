import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:aradi/app/theme/app_theme.dart';
import 'package:aradi/core/services/auth_service.dart';
import 'package:aradi/app/providers/data_providers.dart';
import 'package:aradi/core/config/app_config.dart';

class AdminSettingsPage extends ConsumerWidget {
  const AdminSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            
            // Admin Info Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Admin Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Row(
                      children: [
                        Icon(Icons.admin_panel_settings, color: AppTheme.primaryColor),
                        SizedBox(width: 8),
                        Text('Administrator Account'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Row(
                      children: [
                        Icon(Icons.email, color: Colors.grey),
                        SizedBox(width: 8),
                        Text(AppConfig.adminEmail),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Row(
                      children: [
                        Icon(Icons.security, color: Colors.green),
                        SizedBox(width: 8),
                        Text('Full System Access'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Quick Actions
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.verified_user, color: AppTheme.primaryColor),
                    title: const Text('KYC Verification'),
                    subtitle: const Text('Review and approve user documents'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () => context.go('/admin/verification'),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.assignment, color: AppTheme.primaryColor),
                    title: const Text('Contract Queue'),
                    subtitle: const Text('Manage pending contracts'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () => context.go('/admin/contract-queue'),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.dashboard, color: AppTheme.primaryColor),
                    title: const Text('Dashboard'),
                    subtitle: const Text('View system overview'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () => context.go('/admin'),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // System Status
            const Text(
              'System Status',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.cloud_done, color: Colors.green),
                        SizedBox(width: 8),
                        Text('Firebase Connected'),
                        Spacer(),
                        Icon(Icons.check_circle, color: Colors.green),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Row(
                      children: [
                        Icon(Icons.storage, color: Colors.green),
                        SizedBox(width: 8),
                        Text('Database Online'),
                        Spacer(),
                        Icon(Icons.check_circle, color: Colors.green),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Row(
                      children: [
                        Icon(Icons.security, color: Colors.green),
                        SizedBox(width: 8),
                        Text('Security Rules Active'),
                        Spacer(),
                        Icon(Icons.check_circle, color: Colors.green),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Sign Out Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  try {
                    final authService = ref.read(authServiceProvider);
                    await authService.signOut();
                    // Small delay to ensure auth state change is processed
                    await Future.delayed(const Duration(milliseconds: 100));
                    if (context.mounted) {
                      context.go('/auth');
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error signing out: $e'),
                          backgroundColor: AppTheme.errorColor,
                        ),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.logout),
                label: const Text('Sign Out'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.errorColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
