import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:aradi/app/theme/app_theme.dart';
import 'package:aradi/core/models/user.dart';
import 'package:aradi/core/services/auth_service.dart';
import 'package:aradi/app/providers/data_providers.dart';
import 'package:aradi/features/admin/screens/kyc_review_page.dart';

class AdminHomePage extends ConsumerStatefulWidget {
  const AdminHomePage({super.key});

  @override
  ConsumerState<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends ConsumerState<AdminHomePage> {
  List<User> _pendingUsers = [];
  List<User> _filteredUsers = [];
  bool _isLoading = true;
  UserRole? _selectedFilter;
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    _loadPendingUsers();
  }

  Future<void> _loadPendingUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authService = ref.read(authServiceProvider);
      final users = await authService.getPendingKycUsers();
      if (mounted) {
        setState(() {
          _pendingUsers = users;
          _isLoading = false;
        });
        _applyFilter();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading pending users: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _approveUser(User user) async {
    try {
      final authService = ref.read(authServiceProvider);
      await authService.approveKycUser(user.id);
      
      setState(() {
        _pendingUsers.removeWhere((u) => u.id == user.id);
      });
      _applyFilter();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User approved successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );
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


  void _reviewKyc(User user) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => KycReviewPage(user: user),
      ),
    ).then((_) {
      // Refresh the list when returning from review
      _loadPendingUsers();
    });
  }

  void _applyFilter() {
    setState(() {
      if (_selectedFilter == null) {
        _filteredUsers = _pendingUsers;
      } else {
        _filteredUsers = _pendingUsers.where((user) => user.role == _selectedFilter).toList();
      }
    });
  }

  void _onFilterChanged(UserRole? filter) {
    setState(() {
      _selectedFilter = filter;
    });
    _applyFilter();
  }

  void _toggleFilters() {
    setState(() {
      _showFilters = !_showFilters;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('KYC Review'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _toggleFilters,
            icon: Icon(_showFilters ? Icons.filter_list_off : Icons.filter_list),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final authService = ref.read(authServiceProvider);
              await authService.signOut();
              // Small delay to ensure auth state change is processed
              await Future.delayed(const Duration(milliseconds: 100));
              if (mounted) {
                context.go('/auth');
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (_showFilters) _buildFilters(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredUsers.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        itemCount: _filteredUsers.length,
                        itemBuilder: (context, index) {
                          final user = _filteredUsers[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    if (user.profilePictureUrl != null && user.profilePictureUrl!.isNotEmpty) {
                                      // TODO: Show full screen image
                                    }
                                  },
                                  child: CircleAvatar(
                                    radius: 30,
                                    backgroundColor: AppTheme.primaryColor,
                                    backgroundImage: user.profilePictureUrl != null && user.profilePictureUrl!.isNotEmpty
                                        ? NetworkImage(user.profilePictureUrl!)
                                        : null,
                                    child: user.profilePictureUrl == null || user.profilePictureUrl!.isEmpty
                                        ? Text(
                                            user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          )
                                        : null,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        user.name,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        user.email,
                                        style: TextStyle(
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                      Text(
                                        'Role: ${user.role.name.toUpperCase()}',
                                        style: TextStyle(
                                          color: AppTheme.primaryColor,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () => _reviewKyc(user),
                                icon: const Icon(Icons.visibility),
                                label: const Text('Review KYC Details'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filter by Role:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              FilterChip(
                label: const Text('All'),
                selected: _selectedFilter == null,
                onSelected: (selected) {
                  if (selected) {
                    _onFilterChanged(null);
                  }
                },
                selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                checkmarkColor: AppTheme.primaryColor,
              ),
              FilterChip(
                label: const Text('Developer'),
                selected: _selectedFilter == UserRole.developer,
                onSelected: (selected) {
                  if (selected) {
                    _onFilterChanged(UserRole.developer);
                  }
                },
                selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                checkmarkColor: AppTheme.primaryColor,
              ),
              FilterChip(
                label: const Text('Seller'),
                selected: _selectedFilter == UserRole.seller,
                onSelected: (selected) {
                  if (selected) {
                    _onFilterChanged(UserRole.seller);
                  }
                },
                selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                checkmarkColor: AppTheme.primaryColor,
              ),
              FilterChip(
                label: const Text('Buyer'),
                selected: _selectedFilter == UserRole.buyer,
                onSelected: (selected) {
                  if (selected) {
                    _onFilterChanged(UserRole.buyer);
                  }
                },
                selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                checkmarkColor: AppTheme.primaryColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _selectedFilter == null ? Icons.check_circle_outline : Icons.filter_list_off,
            size: 64,
            color: _selectedFilter == null ? AppTheme.successColor : AppTheme.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            _selectedFilter == null 
                ? 'No pending KYC approvals'
                : 'No ${_selectedFilter!.name.toLowerCase()} users pending approval',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (_selectedFilter != null) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => _onFilterChanged(null),
              child: const Text('Show All'),
            ),
          ],
        ],
      ),
    );
  }
}
