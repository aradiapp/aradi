import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:aradi/app/theme/app_theme.dart';
import 'package:aradi/core/models/land_listing.dart';
import 'package:aradi/core/services/land_listing_service.dart';
import 'package:aradi/core/services/auth_service.dart';
import 'package:aradi/core/services/location_service.dart';
import 'package:aradi/app/providers/data_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DevBrowsePage extends ConsumerStatefulWidget {
  const DevBrowsePage({super.key});

  @override
  ConsumerState<DevBrowsePage> createState() => _DevBrowsePageState();
}

class _DevBrowsePageState extends ConsumerState<DevBrowsePage> {
  List<LandListing> _listings = [];
  List<LandListing> _filteredListings = [];
  bool _isLoading = true;
  
  // Filter states
  double? _minPrice;
  double? _maxPrice;
  double? _minGfa;
  double? _maxGfa;
  double? _minLandSize;
  double? _maxLandSize;
  String _selectedEmirate = '';
  String _selectedCity = '';
  String _selectedArea = '';
  List<PermissionType> _selectedPermissions = [];
  String _spaceUnit = 'sqm'; // 'sqm' or 'sqft'
  bool _showFilters = false;
  
  // Text controllers for filter fields
  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();
  final TextEditingController _minGfaController = TextEditingController();
  final TextEditingController _maxGfaController = TextEditingController();
  final TextEditingController _minLandSizeController = TextEditingController();
  final TextEditingController _maxLandSizeController = TextEditingController();
  
  final LandListingService _landListingService = LandListingService();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _minPriceController.dispose();
    _maxPriceController.dispose();
    _minGfaController.dispose();
    _maxGfaController.dispose();
    _minLandSizeController.dispose();
    _maxLandSizeController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get current user
      final authService = ref.read(authServiceProvider);
      final currentUser = await authService.getCurrentUser();
      
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Load all active listings
      final listings = await _landListingService.getActiveListings();
      
      print('Developer ${currentUser.id} found ${listings.length} listings');
      _listings = listings;
      
      // Apply initial filter
      _applyFilters();
      
      // Rebuild to update filters
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print('Error loading data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading listings: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _applyFilters() {
    final filteredListings = _listings.where((listing) {
      // Price range filter
      if (_minPrice != null && listing.askingPrice < _minPrice!) {
        return false;
      }
      if (_maxPrice != null && listing.askingPrice > _maxPrice!) {
        return false;
      }
      
      // GFA range filter
      if (_minGfa != null && listing.gfa < _minGfa!) {
        return false;
      }
      if (_maxGfa != null && listing.gfa > _maxGfa!) {
        return false;
      }
      
      // Land size range filter
      if (_minLandSize != null && listing.landSize < _minLandSize!) {
        return false;
      }
      if (_maxLandSize != null && listing.landSize > _maxLandSize!) {
        return false;
      }
      
      // Area filter
      if (_selectedEmirate.isNotEmpty && listing.emirate != _selectedEmirate) {
        return false;
      }
      if (_selectedCity.isNotEmpty && listing.city != _selectedCity) {
        return false;
      }
      if (_selectedArea.isNotEmpty && listing.area != _selectedArea) {
        return false;
      }
      
      // Permission filter
      if (_selectedPermissions.isNotEmpty) {
        bool hasMatchingPermission = false;
        for (final permission in _selectedPermissions) {
          if (listing.permissions.contains(permission)) {
            hasMatchingPermission = true;
            break;
          }
        }
        if (!hasMatchingPermission) {
          return false;
        }
      }
      
      return true;
    }).toList();
    
    // Only call setState if the filtered results actually changed
    if (_filteredListings.length != filteredListings.length || 
        !_listEquals(_filteredListings, filteredListings)) {
      setState(() {
        _filteredListings = filteredListings;
      });
    }
  }
  
  bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildFilterToggle(),
                if (_showFilters) _buildFilters(),
                Expanded(
                  child: _buildListingsFeed(),
                ),
              ],
            ),
    );
  }

  Widget _buildFilterToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Listings (${_filteredListings.length})',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Row(
            children: [
              if (_hasActiveFilters())
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_getActiveFilterCount()} filters',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              const SizedBox(width: 8),
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
        ],
      ),
    );
  }

  bool _hasActiveFilters() {
    return _minPrice != null ||
        _maxPrice != null ||
        _minGfa != null ||
        _maxGfa != null ||
        _minLandSize != null ||
        _maxLandSize != null ||
        _selectedEmirate.isNotEmpty ||
        _selectedCity.isNotEmpty ||
        _selectedArea.isNotEmpty ||
        _selectedPermissions.isNotEmpty;
  }

  int _getActiveFilterCount() {
    int count = 0;
    if (_minPrice != null || _maxPrice != null) count++;
    if (_minGfa != null || _maxGfa != null) count++;
    if (_minLandSize != null || _maxLandSize != null) count++;
    if (_selectedEmirate.isNotEmpty || _selectedCity.isNotEmpty || _selectedArea.isNotEmpty) count++;
    if (_selectedPermissions.isNotEmpty) count++;
    return count;
  }

  Widget _buildFilters() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 400),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filters',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton.icon(
                onPressed: _clearFilters,
                icon: const Icon(Icons.clear, size: 16),
                label: const Text('Clear All'),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Price Range Filter
          Text(
            'Price Range (AED)',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _minPriceController,
                  decoration: InputDecoration(
                    labelText: 'Min Price',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    final newMinPrice = double.tryParse(value);
                    if (_minPrice != newMinPrice) {
                      _minPrice = newMinPrice;
                      _applyFilters();
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _maxPriceController,
                  decoration: InputDecoration(
                    labelText: 'Max Price',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    final newMaxPrice = double.tryParse(value);
                    if (_maxPrice != newMaxPrice) {
                      _maxPrice = newMaxPrice;
                      _applyFilters();
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // GFA Range Filter with Unit Toggle
          Row(
            children: [
              Expanded(
                child: Text(
                  'GFA Range',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.borderColor),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildUnitToggle('sqm'),
                    _buildUnitToggle('sqft'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _minGfaController,
                  decoration: InputDecoration(
                    labelText: 'Min GFA',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    final newMinGfa = double.tryParse(value);
                    if (_minGfa != newMinGfa) {
                      _minGfa = newMinGfa;
                      _applyFilters();
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _maxGfaController,
                  decoration: InputDecoration(
                    labelText: 'Max GFA',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    final newMaxGfa = double.tryParse(value);
                    if (_maxGfa != newMaxGfa) {
                      _maxGfa = newMaxGfa;
                      _applyFilters();
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Land Size Range Filter
          Text(
            'Land Size Range ($_spaceUnit)',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _minLandSizeController,
                  decoration: InputDecoration(
                    labelText: 'Min Land Size',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    final newMinLandSize = double.tryParse(value);
                    if (_minLandSize != newMinLandSize) {
                      _minLandSize = newMinLandSize;
                      _applyFilters();
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _maxLandSizeController,
                  decoration: InputDecoration(
                    labelText: 'Max Land Size',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    final newMaxLandSize = double.tryParse(value);
                    if (_maxLandSize != newMaxLandSize) {
                      _maxLandSize = newMaxLandSize;
                      _applyFilters();
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Area Filter
          Text(
            'Area',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedEmirate.isEmpty ? null : _selectedEmirate,
                  decoration: InputDecoration(
                    labelText: 'Emirate',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: LocationService.getEmirates().map((emirate) {
                    return DropdownMenuItem(
                      value: emirate,
                      child: Text(emirate),
                    );
                  }).toList(),
                  onChanged: (String? emirate) {
                    setState(() {
                      _selectedEmirate = emirate ?? '';
                      _selectedCity = '';
                      _selectedArea = '';
                    });
                    _applyFilters();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedCity.isEmpty ? null : _selectedCity,
                  decoration: InputDecoration(
                    labelText: 'City',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: _selectedEmirate.isEmpty 
                      ? []
                      : LocationService.getCities(_selectedEmirate).map((city) {
                          return DropdownMenuItem(
                            value: city,
                            child: Text(city),
                          );
                        }).toList(),
                  onChanged: (String? city) {
                    setState(() {
                      _selectedCity = city ?? '';
                      _selectedArea = '';
                    });
                    _applyFilters();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedArea.isEmpty ? null : _selectedArea,
            decoration: InputDecoration(
              labelText: 'Area',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: (_selectedEmirate.isEmpty || _selectedCity.isEmpty)
                ? []
                : LocationService.getAreas(_selectedEmirate, _selectedCity).map((area) {
                    return DropdownMenuItem(
                      value: area,
                      child: Text(area),
                    );
                  }).toList(),
            onChanged: (String? area) {
              setState(() {
                _selectedArea = area ?? '';
              });
              _applyFilters();
            },
          ),
          const SizedBox(height: 16),
          
          // Permission Filter
          Text(
            'Permissions',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: PermissionType.values.map((permission) {
              final isSelected = _selectedPermissions.contains(permission);
              return FilterChip(
                label: Text(_getPermissionDisplayName(permission)),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedPermissions.add(permission);
                    } else {
                      _selectedPermissions.remove(permission);
                    }
                  });
                  _applyFilters();
                },
                selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                checkmarkColor: AppTheme.primaryColor,
              );
            }).toList(),
          ),
          ],
        ),
      ),
    );
  }



  void _clearFilters() {
    setState(() {
      _minPrice = null;
      _maxPrice = null;
      _minGfa = null;
      _maxGfa = null;
      _minLandSize = null;
      _maxLandSize = null;
      _selectedEmirate = '';
      _selectedCity = '';
      _selectedArea = '';
      _selectedPermissions = [];
      _spaceUnit = 'sqm';
      
      // Clear the text controllers
      _minPriceController.clear();
      _maxPriceController.clear();
      _minGfaController.clear();
      _maxGfaController.clear();
      _minLandSizeController.clear();
      _maxLandSizeController.clear();
      
      _applyFilters();
    });
  }

  Widget _buildListingsFeed() {
    if (_filteredListings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: AppTheme.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No listings found',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your filters',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredListings.length,
      itemBuilder: (context, index) {
        final listing = _filteredListings[index];
        return _buildListingCard(listing);
      },
    );
  }

  Widget _buildListingCard(LandListing listing) {
    // Check if current developer is preferred for this listing
    final authService = ref.read(authServiceProvider);
    final currentUser = authService.currentUser;
    final isPreferredDeveloper = currentUser != null && 
        listing.preferredDeveloperIds.contains(currentUser.uid);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => context.go('/dev/listing/${listing.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${listing.emirate}, ${listing.city}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (isPreferredDeveloper)
                    GestureDetector(
                      onTap: () => _showPreferredDeveloperInfo(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.amber, width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.workspace_premium,
                              color: Colors.amber[700],
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Preferred',
                              style: TextStyle(
                                color: Colors.amber[700],
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.successColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Active',
                      style: TextStyle(
                        color: AppTheme.successColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${listing.emirate}, ${listing.city}',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem('Size', '${listing.landSize.toStringAsFixed(0)} sqm'),
                  ),
                  Expanded(
                    child: _buildInfoItem('GFA', '${listing.gfa.toStringAsFixed(0)} sqm'),
                  ),
                  Expanded(
                    child: _buildInfoItem('Price', 'AED ${(listing.askingPrice / 1000000).toStringAsFixed(2)}M'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: listing.developmentPermissions.map((permission) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      permission,
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
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

  Widget _buildUnitToggle(String unit) {
    final isSelected = _spaceUnit == unit;
    return GestureDetector(
      onTap: () {
        setState(() {
          _spaceUnit = unit;
        });
        _applyFilters();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          unit.toUpperCase(),
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.textSecondary,
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  String _getPermissionDisplayName(PermissionType permission) {
    switch (permission) {
      case PermissionType.residential:
        return 'Residential';
      case PermissionType.commercial:
        return 'Commercial';
      case PermissionType.mix:
        return 'Mixed Use';
      case PermissionType.hotel:
        return 'Hotel';
    }
  }

  void _showPreferredDeveloperInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.workspace_premium,
              color: Colors.amber[700],
              size: 24,
            ),
            const SizedBox(width: 8),
            const Text('Preferred Developer'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Congratulations! You have been selected as a preferred developer for this listing.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'What this means:',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.amber[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• The seller has specifically chosen you for this project',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : AppTheme.borderColor,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

}

