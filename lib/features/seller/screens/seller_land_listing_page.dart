import 'package:flutter/material.dart';
import 'package:aradi/app/theme/app_theme.dart';

class SellerLandListingPage extends StatelessWidget {
  final String listingId;

  const SellerLandListingPage({super.key, required this.listingId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Land Listing'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.location_on,
                size: 80,
                color: AppTheme.accentColor.withOpacity(0.5),
              ),
              const SizedBox(height: 24),
              Text(
                'Land Listing Details',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Listing ID: $listingId\n\nThis feature is not yet implemented. In a real app, this would show detailed land listing information for sellers.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
