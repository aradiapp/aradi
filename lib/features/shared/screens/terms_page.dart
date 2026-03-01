import 'package:flutter/material.dart';
import 'package:aradi/app/theme/app_theme.dart';

/// Placeholder Terms and Conditions for real estate in the UAE.
class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms and Agreements'),
        backgroundColor: AppTheme.accentColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Terms and Conditions – Real Estate Platform (UAE)',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              'Last updated: 2025. These terms are placeholder content and must be reviewed by legal counsel before use.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
            ),
            const SizedBox(height: 24),
            _section(context, '1. Scope and acceptance', '''
These Terms and Conditions ("Terms") govern your use of the ARADI real estate platform and related services in the United Arab Emirates. By registering as a developer, seller, or buyer, you accept these Terms and any applicable UAE and emirate-specific real estate and consumer protection laws.
'''),
            _section(context, '2. Eligibility and compliance', '''
You must be at least 21 years of age and legally capable of entering into binding contracts. You agree to comply with all applicable UAE federal and local laws, including but not limited to real estate regulations, anti-money laundering (AML) requirements, and data protection provisions. Non-compliance may result in suspension or termination of your account.
'''),
            _section(context, '3. Use of the platform', '''
The platform facilitates introductions between land sellers, developers, and buyers. ARADI does not act as a broker, agent, or legal advisor unless expressly agreed in writing. All listing information is provided by users; we do not guarantee its accuracy. You are responsible for conducting your own due diligence, including title checks, zoning, and permits, in line with UAE and emirate-level requirements.
'''),
            _section(context, '4. Listings and transactions', '''
Listings must comply with UAE advertising and real estate disclosure standards. Off-market or misleading information is prohibited. Transactions conducted as a result of the platform are solely between the parties; ARADI is not a party to any sale, joint venture, or development agreement unless otherwise agreed in a separate contract.
'''),
            _section(context, '5. Fees and payments', '''
Any fees for premium features or services will be disclosed before you commit. Payment terms are as set out in the relevant order or subscription. All amounts are in UAE Dirhams (AED) unless otherwise stated. Refunds are subject to our refund policy and applicable UAE consumer law.
'''),
            _section(context, '6. Intellectual property and data', '''
The platform, its design, and content are owned by ARADI or its licensors. You may not copy, scrape, or resell platform data without written permission. We process personal data in accordance with our Privacy Policy and applicable UAE data protection requirements.
'''),
            _section(context, '7. Limitation of liability', '''
To the fullest extent permitted by UAE law, ARADI and its affiliates shall not be liable for any indirect, incidental, or consequential damages arising from your use of the platform or any transaction. Our total liability is limited to the amount you paid to us in the twelve (12) months preceding the claim.
'''),
            _section(context, '8. Disputes and governing law', '''
These Terms are governed by the laws of the United Arab Emirates. Disputes shall be subject to the exclusive jurisdiction of the courts of the relevant emirate in which the dispute arises, or as required by UAE law.
'''),
            _section(context, '9. Changes and contact', '''
We may update these Terms from time to time; continued use of the platform after changes constitutes acceptance. For questions or to contact admin, use the "Contact admin" option in Settings.
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
