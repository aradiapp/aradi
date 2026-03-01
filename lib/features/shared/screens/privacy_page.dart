import 'package:flutter/material.dart';
import 'package:aradi/app/theme/app_theme.dart';

/// Placeholder Privacy Policy for real estate platform in the UAE.
class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        backgroundColor: AppTheme.accentColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Privacy Policy – ARADI Real Estate Platform (UAE)',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              'Last updated: 2025. This privacy policy is placeholder content and must be reviewed by legal counsel before use.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
            ),
            const SizedBox(height: 24),
            _section(context, '1. Who we are', '''
ARADI operates a real estate platform in the United Arab Emirates. We are committed to protecting your personal data in line with UAE federal and emirate-level data protection requirements, including applicable laws and regulations.
'''),
            _section(context, '2. Data we collect', '''
We collect information you provide when you register (name, email, phone, role, profile and KYC documents), usage data (listings viewed, negotiations, preferences), device and log data (IP, device type, app usage), and communications with us or other users through the platform. We do not sell your personal data to third parties.
'''),
            _section(context, '3. How we use your data', '''
We use your data to provide and improve the platform, verify identity and KYC, match sellers with developers and buyers, send notifications (including push notifications with your consent), prevent fraud and comply with legal obligations, and communicate with you about your account and support requests.
'''),
            _section(context, '4. Legal basis and retention', '''
We process your data where necessary for contract performance, consent (e.g. marketing or optional features), legal obligation, or legitimate interests (e.g. security and platform integrity). We retain data only as long as needed for these purposes or as required by UAE law.
'''),
            _section(context, '5. Sharing and disclosure', '''
We may share data with service providers (hosting, analytics, push notifications) under strict agreements, with regulators or law enforcement when required by UAE law, and with other users only as necessary for the platform (e.g. listing and negotiation details). We do not sell your data.
'''),
            _section(context, '6. Your rights', '''
Subject to UAE law, you may have rights to access, correct, delete, or restrict processing of your data, and to withdraw consent where applicable. To exercise these rights or for questions, use "Contact admin" in Settings or contact us at the details provided in the app.
'''),
            _section(context, '7. Security and international transfer', '''
We implement appropriate technical and organisational measures to protect your data. If we transfer data outside the UAE, we ensure adequate safeguards as required by applicable law.
'''),
            _section(context, '8. Changes and contact', '''
We may update this Privacy Policy from time to time; we will notify you of material changes. Continued use after changes constitutes acceptance. For questions, use "Contact admin" in Settings.
'''),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _section(BuildContext context, String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            body.trim(),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textPrimary,
                  height: 1.5,
                ),
          ),
        ],
      ),
    );
  }
}
