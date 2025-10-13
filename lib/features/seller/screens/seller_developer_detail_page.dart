import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:aradi/app/theme/app_theme.dart';
import 'package:aradi/core/models/developer_profile.dart';
import 'package:aradi/core/services/auth_service.dart';

class SellerDeveloperDetailPage extends StatefulWidget {
  final String developerId;

  const SellerDeveloperDetailPage({
    super.key,
    required this.developerId,
  });

  @override
  State<SellerDeveloperDetailPage> createState() => _SellerDeveloperDetailPageState();
}

class _SellerDeveloperDetailPageState extends State<SellerDeveloperDetailPage> {
  final AuthService _authService = AuthService();
  
  DeveloperProfile? _developer;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDeveloper();
  }

  Future<void> _loadDeveloper() async {
    try {
      setState(() => _isLoading = true);
      print('=== LOADING DEVELOPER DETAIL DEBUG ===');
      print('Developer ID: ${widget.developerId}');
      
      final developer = await _authService.getDeveloperById(widget.developerId);
      
      if (developer != null) {
        print('Developer loaded successfully:');
        print('  - Company: ${developer.companyName}');
        print('  - Logo URL: ${developer.logoUrl}');
        print('  - Logo URL is null: ${developer.logoUrl == null}');
        print('  - Logo URL is empty: ${developer.logoUrl?.isEmpty ?? true}');
        print('  - Logo URL length: ${developer.logoUrl?.length ?? 0}');
      } else {
        print('Developer not found for ID: ${widget.developerId}');
      }
      
      setState(() {
        _developer = developer;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      print('Error loading developer: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading developer: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _downloadCatalog() async {
    if (_developer?.catalogDocumentUrl == null) return;
    
    try {
      final uri = Uri.parse(_developer!.catalogDocumentUrl!);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Unable to open catalog'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening catalog: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Developer Details'),
        backgroundColor: AppTheme.accentColor,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            print('Back button pressed');
            context.go('/seller/browse');
          },
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _developer == null
              ? _buildErrorState()
              : _buildDeveloperDetails(),
    );
  }

  Widget _buildErrorState() {
    return Center(
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
            'Developer Not Found',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'The developer you\'re looking for could not be found.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.pop(),
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  Widget _buildDeveloperDetails() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildHeader(),
          _buildCompanyInfo(),
          _buildBusinessDetails(),
          _buildAreasOfInterest(),
          _buildPortfolio(),
          _buildContactInfo(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColor.withOpacity(0.8),
          ],
        ),
      ),
      child: Column(
        children: [
          // Company logo
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white.withOpacity(0.2),
            ),
            child: _developer!.logoUrl != null && _developer!.logoUrl!.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      _developer!.logoUrl!,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                : null,
                            color: Colors.white,
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        print('Error loading developer logo in detail for ${_developer!.companyName}: $error');
                        print('Logo URL: ${_developer!.logoUrl}');
                        return Icon(
                          Icons.business,
                          color: Colors.white,
                          size: 40,
                        );
                      },
                    ),
                  )
                : Builder(
                    builder: (context) {
                      print('No logo URL for ${_developer!.companyName}: ${_developer!.logoUrl}');
                      return Icon(
                        Icons.business,
                        color: Colors.white,
                        size: 40,
                      );
                    },
                  ),
          ),
          const SizedBox(height: 16),
          // Company name
          Text(
            _developer!.companyName,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          // Verification badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.successColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.verified,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  'Verified Developer',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompanyInfo() {
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Company Information',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Company Name', _developer!.companyName),
            _buildInfoRow('Email', _developer!.companyEmail),
            _buildInfoRow('Phone', _developer!.companyPhone),
            _buildInfoRow('Business Model', _developer!.businessModel.toString().split('.').last),
            _buildInfoRow('Team Size', '${_developer!.teamSize} members'),
            _buildInfoRow('Projects Delivered', '${_developer!.deliveredProjects}'),
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessDetails() {
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Business Details',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Under Construction', '${_developer!.underConstruction} projects'),
            _buildInfoRow('Total Value', 'AED ${_developer!.totalValue.toStringAsFixed(0)}'),
          ],
        ),
      ),
    );
  }

  Widget _buildAreasOfInterest() {
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Areas of Interest',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _developer!.areasInterested.map((area) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppTheme.primaryColor.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    area,
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPortfolio() {
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Portfolio',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            if (_developer!.catalogDocumentUrl != null) ...[
              Row(
                children: [
                  Icon(
                    Icons.download,
                    color: AppTheme.primaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Company Catalog',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _downloadCatalog,
                    icon: const Icon(Icons.download, size: 16),
                    label: const Text('Download'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ] else ...[
              Text(
                'No catalog available',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildContactInfo() {
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Contact Information',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Email', _developer!.companyEmail),
            _buildInfoRow('Phone', _developer!.companyPhone),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
