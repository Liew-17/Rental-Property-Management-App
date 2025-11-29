import 'package:flutter/material.dart';

class ResidenceTypePicker extends StatefulWidget {
  final String? initialResidenceType;
  final ValueChanged<String>? onChanged;

  const ResidenceTypePicker({
    super.key,
    this.initialResidenceType,
    this.onChanged,
  });

  @override
  State<ResidenceTypePicker> createState() => _ResidenceTypePickerState();
}

class _ResidenceTypePickerState extends State<ResidenceTypePicker> {
  final List<String> residenceTypes = [
    'Apartment',
    'House',
    'Condo',
    'Townhouse',
    'Villa',
    'Penthouse',
    'Others'
  ];
  String selectedHouseType = '';

  @override
  void initState() {
    super.initState();
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
          widget.onChanged?.call(selectedHouseType);
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