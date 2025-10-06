import 'package:flutter/material.dart';
import '../services/location_service.dart';

class LocationSelector extends StatefulWidget {
  final String selectedEmirate;
  final String selectedCity;
  final String selectedArea;
  final Function(String emirate, String city, String area) onLocationChanged;
  final String? emirateError;
  final String? cityError;
  final String? areaError;

  const LocationSelector({
    super.key,
    required this.selectedEmirate,
    required this.selectedCity,
    required this.selectedArea,
    required this.onLocationChanged,
    this.emirateError,
    this.cityError,
    this.areaError,
  });

  @override
  State<LocationSelector> createState() => _LocationSelectorState();
}

class _LocationSelectorState extends State<LocationSelector> {
  String? _selectedEmirate;
  String? _selectedCity;
  String? _selectedArea;

  @override
  void initState() {
    super.initState();
    _selectedEmirate = widget.selectedEmirate.isEmpty ? null : widget.selectedEmirate;
    _selectedCity = widget.selectedCity.isEmpty ? null : widget.selectedCity;
    _selectedArea = widget.selectedArea.isEmpty ? null : widget.selectedArea;
  }

  @override
  void didUpdateWidget(covariant LocationSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedEmirate != widget.selectedEmirate ||
        oldWidget.selectedCity != widget.selectedCity ||
        oldWidget.selectedArea != widget.selectedArea) {
      _selectedEmirate = widget.selectedEmirate.isEmpty ? null : widget.selectedEmirate;
      _selectedCity = widget.selectedCity.isEmpty ? null : widget.selectedCity;
      _selectedArea = widget.selectedArea.isEmpty ? null : widget.selectedArea;
    }
  }

  void _onEmirateChanged(String? emirate) {
    setState(() {
      _selectedEmirate = emirate;
      _selectedCity = null;
      _selectedArea = null;
    });
    widget.onLocationChanged(emirate ?? '', '', '');
  }

  void _onCityChanged(String? city) {
    setState(() {
      _selectedCity = city;
      _selectedArea = null;
    });
    widget.onLocationChanged(
      _selectedEmirate ?? '',
      city ?? '',
      '',
    );
  }

  void _onAreaChanged(String? area) {
    setState(() {
      _selectedArea = area;
    });
    widget.onLocationChanged(
      _selectedEmirate ?? '',
      _selectedCity ?? '',
      area ?? '',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Emirate Dropdown
        DropdownButtonFormField<String>(
          value: _selectedEmirate,
          decoration: InputDecoration(
            labelText: 'Emirate',
            hintText: 'Select Emirate',
            errorText: widget.emirateError,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          items: LocationService.getEmirates().map((emirate) {
            return DropdownMenuItem<String>(
              value: emirate,
              child: Text(emirate),
            );
          }).toList(),
          onChanged: _onEmirateChanged,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select an Emirate';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // City Dropdown
        DropdownButtonFormField<String>(
          value: _selectedCity,
          decoration: InputDecoration(
            labelText: 'City',
            hintText: 'Select City',
            errorText: widget.cityError,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          items: _selectedEmirate != null
              ? LocationService.getCities(_selectedEmirate!).map((city) {
                  return DropdownMenuItem<String>(
                    value: city,
                    child: Text(city),
                  );
                }).toList()
              : [],
          onChanged: _selectedEmirate != null ? _onCityChanged : null,
          validator: (value) {
            if (_selectedEmirate != null && (value == null || value.isEmpty)) {
              return 'Please select a City';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // Area Dropdown
        DropdownButtonFormField<String>(
          value: _selectedArea,
          decoration: InputDecoration(
            labelText: 'Area',
            hintText: 'Select Area',
            errorText: widget.areaError,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          items: (_selectedEmirate != null && _selectedCity != null)
              ? LocationService.getAreas(_selectedEmirate!, _selectedCity!).map((area) {
                  return DropdownMenuItem<String>(
                    value: area,
                    child: Text(area),
                  );
                }).toList()
              : [],
          onChanged: (_selectedEmirate != null && _selectedCity != null) ? _onAreaChanged : null,
          validator: (value) {
            if (_selectedEmirate != null && _selectedCity != null && (value == null || value.isEmpty)) {
              return 'Please select an Area';
            }
            return null;
          },
        ),
      ],
    );
  }
}