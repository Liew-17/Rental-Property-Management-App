import 'package:flutter/material.dart';
import 'package:flutter_application/data/location_data.dart';

class LocationPicker extends StatefulWidget {
  final String? initialState;
  final String? initialDistrict;
  final String? initialCity;

  final Function(String? state, String? district, String? city) onChanged;

  const LocationPicker({
    super.key,
    this.initialState,
    this.initialDistrict,
    this.initialCity,
    required this.onChanged,
  });

  @override
  State<LocationPicker> createState() => _LocationPickerState();
}

class _LocationPickerState extends State<LocationPicker> {
  String? _state;
  String? _district;
  String? _city;

  List<String> _districts = [];
  List<String> _cities = [];

  @override
  void initState() {
    super.initState();
    _validateAndInitialize();
  }


  void _validateAndInitialize() {

    if (widget.initialState != null &&
        LocationData.states.contains(widget.initialState)) {
      _state = widget.initialState;
      _districts = LocationData.locationData[_state!]!.keys.toList();
    } else {
        _state = null;
        _districts = [];
        _district = null;
        _cities = [];
        _city = null;
      return;
    }

    if (widget.initialDistrict != null &&
        _districts.contains(widget.initialDistrict)) {
      _district = widget.initialDistrict;
      _cities = LocationData.locationData[_state!]![_district!]!;
    } else {
      _district = null;
      _cities = [];
      _city = null;
      return;
    }


    if (widget.initialCity != null &&
        _cities.contains(widget.initialCity)) {
      _city = widget.initialCity;
    } else {
      _city = null;
    }
  }

  void _triggerCallback() {
    widget.onChanged(_state, _district, _city);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
       mainAxisSize: MainAxisSize.min,
      children: [
        // state
        DropdownButtonFormField<String>(
          initialValue: _state,
          decoration: const InputDecoration(labelText: "State"),
          menuMaxHeight: 350,
          items: LocationData.states
              .map((s) => DropdownMenuItem(value: s, child: Text(s)))
              .toList(),
          onChanged: (value) {
            setState(() {
              _state = value;

              if (value == null) {
                _district = null;
                _city = null;
                _districts = [];
                _cities = [];
              } else {
                _districts = LocationData.locationData.containsKey(value)?
                              LocationData.locationData[value]!.keys.toList()
                              :[];
                _district = null;
                _cities = [];
                _city = null;
              }

              _triggerCallback();
            });
          },
        ),

        const SizedBox(height: 10),

        // district
        DropdownButtonFormField<String>(
          initialValue: _district,
          decoration: const InputDecoration(labelText: "District"),
          menuMaxHeight: 350,
          items: _districts
              .map((d) => DropdownMenuItem(value: d, child: Text(d)))
              .toList(),
          onChanged: _state == null
              ? null
              : (value) {
                  setState(() {
                    _district = value;

                    if (value == null) {
                      _city = null;
                      _cities = [];
                    } else {
                      if(LocationData.locationData.containsKey(_state) && LocationData.locationData[_state]!.containsKey(value)){
                        _cities = LocationData.locationData[_state!]![value]!;
                      }               
                      else{
                        _cities = [];
                      }



                      _city = null;
                    }

                    _triggerCallback();
                  });
                },
        ),

        const SizedBox(height: 10),

        // city
        DropdownButtonFormField<String>(
          initialValue: _city,
          decoration: const InputDecoration(labelText: "City"),
          menuMaxHeight: 350,
          items: _cities
              .map((c) => DropdownMenuItem(value: c, child: Text(c)))
              .toList(),
          onChanged: _district == null
              ? null
              : (value) {
                  setState(() {
                    _city = value;
                    _triggerCallback();
                  });
                },
        ),
      ],
    );
  }
}


