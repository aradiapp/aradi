import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:aradi/app/theme/app_theme.dart';
import 'package:aradi/core/models/user.dart';
import 'package:aradi/core/models/developer_profile.dart';
import 'package:aradi/core/models/buyer_profile.dart';
import 'package:aradi/core/models/seller_profile.dart';
import 'package:aradi/core/services/auth_service.dart';
import 'package:aradi/app/providers/data_providers.dart';
import 'package:aradi/features/admin/widgets/kyc_rejection_dialog.dart';

class KycReviewPage extends ConsumerStatefulWidget {
  final User user;

  const KycReviewPage({
    super.key,
    required this.user,
  });

  @override
  ConsumerState<KycReviewPage> createState() => _KycReviewPageState();
}

class _KycReviewPageState extends ConsumerState<KycReviewPage> {
  bool _isLoading = true;
  dynamic _profileData;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authService = ref.read(authServiceProvider);
      
      switch (widget.user.role) {
        case UserRole.developer:
          _profileData = await authService.getDeveloperProfile(widget.user.id);
          break;
        case UserRole.buyer:
          _profileData = await authService.getBuyerProfile(widget.user.id);
          break;
        case UserRole.seller:
          _profileData = await authService.getSellerProfile(widget.user.id);
          break;
        default:
          _profileData = null;
      }
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading profile data: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _approveUser() async {
    try {
      final authService = ref.read(authServiceProvider);
      await authService.approveKycUser(widget.user.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User approved successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error approving user: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _rejectUser() async {
    showDialog(
      context: context,
      builder: (context) => KycRejectionDialog(
        userName: widget.user.name,
        userEmail: widget.user.email,
        onReject: (rejectionReason) async {
          try {
            final authService = ref.read(authServiceProvider);
            await authService.rejectKycUser(widget.user.id, rejectionReason: rejectionReason);
            
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('User rejected'),
                  backgroundColor: AppTheme.warningColor,
                ),
              );
              context.pop();
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error rejecting user: $e'),
                  backgroundColor: AppTheme.errorColor,
                ),
              );
            }
            rethrow;
          }
        },
      ),
    );
  }

  Widget _buildDocumentImage(String? imageUrl, String title) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(Icons.image_not_supported, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 8),
              Text(
                'No $title uploaded',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => _showImageDialog(imageUrl, title),
            child: Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(imageUrl),
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                ),
                child: const Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(
                      Icons.zoom_in,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showImageDialog(String imageUrl, String title) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: Text(title),
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            Expanded(
              child: InteractiveViewer(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeveloperProfile() {
    if (_profileData is! DeveloperProfile) return const SizedBox();
    
    final profile = _profileData as DeveloperProfile;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Company Information',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 16),
        _buildInfoCard([
          _buildInfoRow('Company Name', profile.companyName),
          _buildInfoRow('Company Email', profile.companyEmail),
          _buildInfoRow('Company Phone', profile.companyPhone),
          _buildInfoRow('Business Model', profile.businessModel.toString().split('.').last),
          _buildInfoRow('Areas Interested', profile.areasInterested.join(', ')),
        ]),
        const SizedBox(height: 24),
        const Text(
          'Company Statistics',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 16),
        _buildInfoCard([
          _buildInfoRow('Delivered Projects', profile.deliveredProjects.toString()),
          _buildInfoRow('Under Construction', profile.underConstruction.toString()),
          _buildInfoRow('Team Size', profile.teamSize.toString()),
          _buildInfoRow('Total Value', '${profile.totalValue.toString()} AED'),
        ]),
        const SizedBox(height: 24),
        const Text(
          'Documents',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 16),
        _buildDocumentImage(profile.tradeLicense, 'Trade License'),
        const SizedBox(height: 16),
        _buildDocumentImage(profile.signatoryPassport, 'Signatory Passport'),
        if (profile.catalogDocumentUrl != null && profile.catalogDocumentUrl!.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildDocumentImage(profile.catalogDocumentUrl, 'Company Catalog'),
        ],
        if (profile.logoUrl != null && profile.logoUrl!.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildDocumentImage(profile.logoUrl, 'Company Logo'),
        ],
        if (profile.portfolioPdfUrl != null && profile.portfolioPdfUrl!.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildDocumentImage(profile.portfolioPdfUrl, 'Portfolio PDF'),
        ],
      ],
    );
  }

  Widget _buildBuyerProfile() {
    if (_profileData is! BuyerProfile) return const SizedBox();
    
    final profile = _profileData as BuyerProfile;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Buyer Information',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 16),
        _buildInfoCard([
          _buildInfoRow('Phone', profile.phone),
          _buildInfoRow('Areas Interested', profile.areasInterested.join(', ')),
          _buildInfoRow('GFA Range', profile.gfaRange != null 
            ? '${profile.gfaRange!['min']} - ${profile.gfaRange!['max']} sqm'
            : 'Not specified'),
          _buildInfoRow('Budget Range', profile.budgetRange != null 
            ? '${profile.budgetRange!['min']} - ${profile.budgetRange!['max']} AED'
            : 'Not specified'),
          _buildInfoRow('Has Active Subscription', profile.hasActiveSubscription ? 'Yes' : 'No'),
        ]),
        const SizedBox(height: 24),
        const Text(
          'Documents',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 16),
        _buildDocumentImage(profile.passport, 'Passport'),
      ],
    );
  }

  Widget _buildSellerProfile() {
    if (_profileData is! SellerProfile) return const SizedBox();
    
    final profile = _profileData as SellerProfile;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Seller Information',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 16),
        _buildInfoCard([
          _buildInfoRow('Phone', profile.phone),
          _buildInfoRow('Email', profile.email),
          _buildInfoRow('Total Listings', profile.totalListings.toString()),
          _buildInfoRow('Active Listings', profile.activeListings.toString()),
          _buildInfoRow('Completed Deals', profile.completedDeals.toString()),
          _buildInfoRow('Is Verified', profile.isVerified ? 'Yes' : 'No'),
        ]),
        const SizedBox(height: 24),
        const Text(
          'Documents',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 16),
        _buildDocumentImage(profile.passportOrEmiratesId, 'Passport or Emirates ID'),
        if (profile.tradeLicenseDocumentUrl != null && profile.tradeLicenseDocumentUrl!.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildDocumentImage(profile.tradeLicenseDocumentUrl, 'Trade License Document'),
        ],
        if (profile.tradeLicense != null && profile.tradeLicense!.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildDocumentImage(profile.tradeLicense, 'Trade License'),
        ],
        if (profile.companyTradeLicense != null && profile.companyTradeLicense!.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildDocumentImage(profile.companyTradeLicense, 'Company Trade License'),
        ],
        if (profile.logoUrl != null && profile.logoUrl!.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildDocumentImage(profile.logoUrl, 'Company Logo'),
        ],
      ],
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: children,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text('KYC Review - ${widget.user.name}'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _approveUser,
            tooltip: 'Approve',
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: _rejectUser,
            tooltip: 'Reject',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User Basic Info
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  if (widget.user.profilePictureUrl != null && widget.user.profilePictureUrl!.isNotEmpty) {
                                    _showImageDialog(widget.user.profilePictureUrl!, 'Profile Picture');
                                  }
                                },
                                child: CircleAvatar(
                                  radius: 30,
                                  backgroundColor: AppTheme.primaryColor,
                                  backgroundImage: widget.user.profilePictureUrl != null && widget.user.profilePictureUrl!.isNotEmpty
                                      ? NetworkImage(widget.user.profilePictureUrl!)
                                      : null,
                                  child: widget.user.profilePictureUrl == null || widget.user.profilePictureUrl!.isEmpty
                                      ? Text(
                                          widget.user.name.isNotEmpty ? widget.user.name[0].toUpperCase() : 'U',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.user.name,
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      widget.user.email,
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                    Text(
                                      'Role: ${widget.user.role.name.toUpperCase()}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: AppTheme.primaryColor,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Role-specific profile information
                  if (widget.user.role == UserRole.developer) _buildDeveloperProfile(),
                  if (widget.user.role == UserRole.buyer) _buildBuyerProfile(),
                  if (widget.user.role == UserRole.seller) _buildSellerProfile(),
                  
                  const SizedBox(height: 32),
                  
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _approveUser,
                          icon: const Icon(Icons.check),
                          label: const Text('Approve'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.successColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _rejectUser,
                          icon: const Icon(Icons.close),
                          label: const Text('Reject'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.errorColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}
