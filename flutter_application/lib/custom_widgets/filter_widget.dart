import 'package:flutter/material.dart';
import 'package:flutter_application/custom_widgets/location_picker.dart';

import 'package:flutter_application/custom_widgets/residence_type_picker.dart';
import 'package:flutter_application/models/user.dart';
import 'package:flutter_application/theme.dart';

class SearchFilterSheet extends StatefulWidget {
  final Map<String, dynamic> currentFilters;

  const SearchFilterSheet({super.key, required this.currentFilters});

  @override
  State<SearchFilterSheet> createState() => _SearchFilterSheetState();
}

class _SearchFilterSheetState extends State<SearchFilterSheet> {
  String? _state;
  String? _district;
  String? _city;
  String? _residenceType;
  
  final TextEditingController _minPriceCtrl = TextEditingController();
  final TextEditingController _maxPriceCtrl = TextEditingController();
  final TextEditingController _minSizeCtrl = TextEditingController();
  final TextEditingController _maxSizeCtrl = TextEditingController();
  final GlobalKey<LocationPickerState> _pickerKey = GlobalKey<LocationPickerState>();
  

  int _minBedrooms = 0;
  int _minBathrooms = 0;

  @override
  void initState() {
    super.initState();
    _loadCurrentFilters();
  }

  void _loadCurrentFilters() {
    final f = widget.currentFilters;
    bool isFreshStart = f.isEmpty;

    if (isFreshStart) {
      _state = AppUser().state;
      _district = AppUser().district;
      _city = AppUser().city;
    } else {
      _state = f['state'];
      _district = f['district'];
      _city = f['city'];
    }
    
    _residenceType = f['residenceType'];
    
    if (f['minPrice'] != null) _minPriceCtrl.text = f['minPrice'].toString();
    if (f['maxPrice'] != null) _maxPriceCtrl.text = f['maxPrice'].toString();
    if (f['minSize'] != null) _minSizeCtrl.text = f['minSize'].toString();
    if (f['maxSize'] != null) _maxSizeCtrl.text = f['maxSize'].toString();
    
    _minBedrooms = f['minBedrooms'] ?? 0;
    _minBathrooms = f['minBathrooms'] ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(20),
          child: ListView(
            controller: scrollController,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Filters", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: () {
                      _pickerKey.currentState?.reset();

                      setState(() {
                        
                        _state = null; _district = null; _city = null;
                        _residenceType = null;
                        _minPriceCtrl.clear(); _maxPriceCtrl.clear();
                        _minSizeCtrl.clear(); _maxSizeCtrl.clear();
                        _minBedrooms = 0; _minBathrooms = 0;
                        // location picker reset
                      });
                    }, 
                    child: const Text("Reset")
                  )
                ],
              ),
              const Divider(),

              // 1. Location
              const Text("Location", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              LocationPicker(
                key: _pickerKey,
                initialState: _state,
                initialDistrict: _district,
                initialCity: _city,
                onChanged: (s, d, c) => setState(() {
                  _state = s; _district = d; _city = c;
                }),
              ),

              const SizedBox(height: 20),

              // 2. Residence Type
              const Text("Property Type", style: TextStyle(fontWeight: FontWeight.bold)),
              ResidenceTypePicker(
                initialResidenceType: _residenceType,
                onChanged: (val) => setState(() => _residenceType = val),
                showAll: true,
              ),

              const SizedBox(height: 20),

              // 3. Price Range
              const Text("Price Range (RM)", style: TextStyle(fontWeight: FontWeight.bold)),
              Row(
                children: [
                  Expanded(child: _buildNumberInput(_minPriceCtrl, "Min")),
                  const SizedBox(width: 10),
                  const Text("-"),
                  const SizedBox(width: 10),
                  Expanded(child: _buildNumberInput(_maxPriceCtrl, "Max")),
                ],
              ),

              const SizedBox(height: 20),

              // 4. Rooms
              const Text("Rooms", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _buildCounter("Bedrooms", _minBedrooms, (v) => setState(() => _minBedrooms = v))),
                  const SizedBox(width: 16),
                  Expanded(child: _buildCounter("Bathrooms", _minBathrooms, (v) => setState(() => _minBathrooms = v))),
                ],
              ),

              const SizedBox(height: 20),

              // 5. Land Size
              const Text("Land Size (sqft)", style: TextStyle(fontWeight: FontWeight.bold)),
              Row(
                children: [
                  Expanded(child: _buildNumberInput(_minSizeCtrl, "Min Sqft")),
                  const SizedBox(width: 10),
                  const Text("-"),
                  const SizedBox(width: 10),
                  Expanded(child: _buildNumberInput(_maxSizeCtrl, "Max Sqft")),
                ],
              ),

              const SizedBox(height: 30),

              // Apply Button
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  style: AppTheme.primaryButton,
                  onPressed: () {
                    Navigator.pop(context, {
                      'state': _state,
                      'district': _district,
                      'city': _city,
                      'residenceType': _residenceType,
                      'minPrice': double.tryParse(_minPriceCtrl.text),
                      'maxPrice': double.tryParse(_maxPriceCtrl.text),
                      'minSize': double.tryParse(_minSizeCtrl.text),
                      'maxSize': double.tryParse(_maxSizeCtrl.text),
                      'minBedrooms': _minBedrooms > 0 ? _minBedrooms : null,
                      'minBathrooms': _minBathrooms > 0 ? _minBathrooms : null,
                    });
                  },
                  child: const Text("Show Results"),
                ),
              ),
            ],
          ),
        );
      }
    );
  }

  Widget _buildNumberInput(TextEditingController ctrl, String hint) {
    return TextField(
      controller: ctrl,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0)
      ),
    );
  }

  Widget _buildCounter(String label, int value, Function(int) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.remove, size: 16),
                onPressed: () => value > 0 ? onChanged(value - 1) : null,
              ),
              Text(value == 0 ? "Any" : "$value+", style: const TextStyle(fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.add, size: 16),
                onPressed: () => onChanged(value + 1),
              ),
            ],
          ),
        )
      ],
    );
  }
}

