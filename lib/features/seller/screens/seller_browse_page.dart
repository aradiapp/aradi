import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:aradi/app/theme/app_theme.dart';
import 'package:aradi/core/models/developer_profile.dart';
import 'package:aradi/core/services/auth_service.dart';

class SellerBrowsePage extends StatefulWidget {
  const SellerBrowsePage({super.key});

  @override
  State<SellerBrowsePage> createState() => _SellerBrowsePageState();
}

class _SellerBrowsePageState extends State<SellerBrowsePage> {
  final AuthService _authService = AuthService();
  
  List<DeveloperProfile> _developers = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedArea = 'All Areas';
  String _selectedTeamSize = 'All Sizes';
  String _selectedProjects = 'All Projects';
  String _selectedBusinessModel = 'All Models';
  bool _showFilters = false;

  final List<String> _areas = [
    'All Areas',
    'Dubai Marina',
    'Downtown Dubai',
    'Business Bay',
    'Jumeirah',
    'Palm Jumeirah',
    'Dubai Hills',
    'Dubai Creek Harbour',
    'JBR',
    'DIFC',
  ];

  final List<String> _teamSizes = [
    'All Sizes',
    '1-10',
    '11-25',
    '26-50',
    '51-100',
    '100+',
  ];

  final List<String> _projectRanges = [
    'All Projects',
    '0-5',
    '6-15',
    '16-30',
    '31-50',
    '50+',
  ];

  final List<String> _businessModels = [
    'All Models',
    'Business',
    'Venture',
    'Both',
  ];

  @override
  void initState() {
    super.initState();
    _loadDevelopers();
  }

  Future<void> _loadDevelopers() async {
    try {
      setState(() => _isLoading = true);
      final developers = await _authService.getVerifiedDevelopers();
      
      print('=== LOADING DEVELOPERS DEBUG ===');
      print('Total developers loaded: ${developers.length}');
      
      for (int i = 0; i < developers.length; i++) {
        final dev = developers[i];
        print('Developer $i:');
        print('  - Company: ${dev.companyName}');
        print('  - Logo URL: ${dev.logoUrl}');
        print('  - Logo URL is null: ${dev.logoUrl == null}');
        print('  - Logo URL is empty: ${dev.logoUrl?.isEmpty ?? true}');
        print('  - Logo URL length: ${dev.logoUrl?.length ?? 0}');
      }
      
      setState(() {
        _developers = developers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      print('Error loading developers: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading developers: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  List<DeveloperProfile> get _filteredDevelopers {
    var filtered = _developers.where((dev) {
      final matchesSearch = _searchQuery.isEmpty ||
          dev.companyName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          dev.areasInterested.any((area) => 
              area.toLowerCase().contains(_searchQuery.toLowerCase()));
      
      final matchesArea = _selectedArea == 'All Areas' ||
          dev.areasInterested.contains(_selectedArea);
      
      final matchesTeamSize = _matchesTeamSize(dev.teamSize);
      final matchesProjects = _matchesProjects(dev.deliveredProjects);
      final matchesBusinessModel = _matchesBusinessModel(dev.businessModel);
      
      return matchesSearch && matchesArea && matchesTeamSize && matchesProjects && matchesBusinessModel;
    }).toList();

    // Sort by company name
    filtered.sort((a, b) => a.companyName.compareTo(b.companyName));
    return filtered;
  }

  bool _matchesTeamSize(int teamSize) {
    if (_selectedTeamSize == 'All Sizes') return true;
    
    switch (_selectedTeamSize) {
      case '1-10':
        return teamSize >= 1 && teamSize <= 10;
      case '11-25':
        return teamSize >= 11 && teamSize <= 25;
      case '26-50':
        return teamSize >= 26 && teamSize <= 50;
      case '51-100':
        return teamSize >= 51 && teamSize <= 100;
      case '100+':
        return teamSize > 100;
      default:
        return true;
    }
  }

  bool _matchesProjects(int projects) {
    if (_selectedProjects == 'All Projects') return true;
    
    switch (_selectedProjects) {
      case '0-5':
        return projects >= 0 && projects <= 5;
      case '6-15':
        return projects >= 6 && projects <= 15;
      case '16-30':
        return projects >= 16 && projects <= 30;
      case '31-50':
        return projects >= 31 && projects <= 50;
      case '50+':
        return projects > 50;
      default:
        return true;
    }
  }

  bool _matchesBusinessModel(BusinessModel businessModel) {
    if (_selectedBusinessModel == 'All Models') return true;
    
    final modelString = businessModel.toString().split('.').last;
    return modelString.toLowerCase() == _selectedBusinessModel.toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: Column(
        children: [
          _buildSearchAndFilters(),
          if (_showFilters) _buildFilters(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _developers.isEmpty
                    ? _buildEmptyState()
                    : _buildDevelopersList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Filter toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                onPressed: () {
                  setState(() {
                    _showFilters = !_showFilters;
                  });
                },
                icon: Icon(
                  _showFilters ? Icons.keyboard_arrow_up : Icons.filter_list,
                  color: AppTheme.primaryColor,
                ),
                tooltip: _showFilters ? 'Hide Filters' : 'Show Filters',
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Search bar
          TextField(
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: InputDecoration(
              hintText: 'Search developers...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: AppTheme.backgroundLight,
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
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Filter dropdowns - single column to avoid overflow
          DropdownButtonFormField<String>(
            value: _selectedArea,
            decoration: InputDecoration(
              labelText: 'Filter by Area',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: AppTheme.backgroundLight,
            ),
            items: _areas.map((area) {
              return DropdownMenuItem(
                value: area,
                child: Text(area),
              );
            }).toList(),
            onChanged: (value) => setState(() => _selectedArea = value!),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _selectedTeamSize,
            decoration: InputDecoration(
              labelText: 'Filter by Team Size',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: AppTheme.backgroundLight,
            ),
            items: _teamSizes.map((size) {
              return DropdownMenuItem(
                value: size,
                child: Text(size),
              );
            }).toList(),
            onChanged: (value) => setState(() => _selectedTeamSize = value!),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _selectedProjects,
            decoration: InputDecoration(
              labelText: 'Filter by Projects Delivered',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: AppTheme.backgroundLight,
            ),
            items: _projectRanges.map((range) {
              return DropdownMenuItem(
                value: range,
                child: Text(range),
              );
            }).toList(),
            onChanged: (value) => setState(() => _selectedProjects = value!),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _selectedBusinessModel,
            decoration: InputDecoration(
              labelText: 'Filter by Business Model',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: AppTheme.backgroundLight,
            ),
            items: _businessModels.map((model) {
              return DropdownMenuItem(
                value: model,
                child: Text(model),
              );
            }).toList(),
            onChanged: (value) => setState(() => _selectedBusinessModel = value!),
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
            Icons.business,
            size: 64,
            color: AppTheme.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            'No Developers Found',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No verified developers match your search criteria.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDevelopersList() {
    final filteredDevelopers = _filteredDevelopers;
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredDevelopers.length,
      itemBuilder: (context, index) {
        final developer = filteredDevelopers[index];
        return _buildDeveloperCard(developer);
      },
    );
  }

  Widget _buildDeveloperCard(DeveloperProfile developer) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => context.go('/seller/developer/${developer.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Company logo or placeholder
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: AppTheme.primaryColor.withOpacity(0.1),
                    ),
                    child: developer.logoUrl != null && developer.logoUrl!.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              developer.logoUrl!,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                        : null,
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                print('Error loading developer logo for ${developer.companyName}: $error');
                                print('Logo URL: ${developer.logoUrl}');
                                return Icon(
                                  Icons.business,
                                  color: AppTheme.primaryColor,
                                  size: 24,
                                );
                              },
                            ),
                          )
                        : Builder(
                            builder: (context) {
                              print('No logo URL for ${developer.companyName}: ${developer.logoUrl}');
                              return Icon(
                                Icons.business,
                                color: AppTheme.primaryColor,
                                size: 24,
                              );
                            },
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          developer.companyName,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          developer.companyEmail,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.successColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Verified',
                      style: TextStyle(
                        color: AppTheme.successColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Areas of interest
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: developer.areasInterested.map((area) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      area,
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              // Business model and team size
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem('Business Model', developer.businessModel.toString().split('.').last),
                  ),
                  Expanded(
                    child: _buildInfoItem('Team Size', '${developer.teamSize}'),
                  ),
                  Expanded(
                    child: _buildInfoItem('Projects', '${developer.deliveredProjects}'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
