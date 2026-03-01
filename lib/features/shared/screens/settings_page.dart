import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:aradi/app/theme/app_theme.dart';
import 'package:aradi/core/models/user.dart';

/// Settings for sellers and developers: Terms & agreements, Contact admin.
class SettingsPage extends StatelessWidget {
  final UserRole userRole;

  const SettingsPage({super.key, required this.userRole});

  String get _settingsTitle => userRole == UserRole.seller ? 'Seller Settings' : 'Developer Settings';
  String get _basePath => userRole == UserRole.seller ? '/seller' : '/dev';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_settingsTitle),
        backgroundColor: AppTheme.accentColor,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.description, color: AppTheme.primaryColor),
                  title: const Text('Terms and Agreements'),
                  subtitle: const Text('Platform terms and conditions for UAE real estate'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => context.push('$_basePath/terms'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.contact_support, color: AppTheme.primaryColor),
                  title: const Text('Contact admin'),
                  subtitle: const Text('Send a message to administration'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => context.push('$_basePath/contact-admin'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
