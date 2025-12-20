import 'package:flutter/material.dart';

class ResidenceTypePicker extends StatefulWidget {
  final String? initialResidenceType;
  final ValueChanged<String?>? onChanged; 
  final bool showAll;

  const ResidenceTypePicker({
    super.key,
    this.initialResidenceType,
    this.onChanged,
    this.showAll = false, // Default set to false
  });

  @override
  State<ResidenceTypePicker> createState() => _ResidenceTypePickerState();
}

class _ResidenceTypePickerState extends State<ResidenceTypePicker> {
  final List<String> _baseResidenceTypes = [
    'Apartment',
    'House',
    'Condo',
    'Townhouse',
    'Villa',
    'Penthouse',
    'Others'
  ];

  late List<String> residenceTypes;
  String selectedHouseType = '';

  @override
  void initState() {
    super.initState();
    _initializeState();
  }

  @override
  void didUpdateWidget(ResidenceTypePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialResidenceType != oldWidget.initialResidenceType || 
        widget.showAll != oldWidget.showAll) {
      _initializeState();
    }
  }

  void _initializeState() {
    residenceTypes = List.from(_baseResidenceTypes);
    if (widget.showAll) {
      residenceTypes.insert(0, 'All');
    }

    if (widget.initialResidenceType != null &&
        residenceTypes.contains(widget.initialResidenceType)) {
      selectedHouseType = widget.initialResidenceType!;
    } else {
      selectedHouseType = residenceTypes.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: DropdownButton<String>(
        isExpanded: true,
        value: selectedHouseType,
        onChanged: (String? newValue) {
          if (newValue == null) return;

          setState(() {
            selectedHouseType = newValue;
            
            if (widget.showAll && newValue == 'All') {
              widget.onChanged?.call(null);
            } else {
              widget.onChanged?.call(newValue);
            }
          });
        },
        items: residenceTypes.map((String type) {
          return DropdownMenuItem<String>(
            value: type,
            child: Text(type),
          );
        }).toList(),
      ),
    );
  }
}