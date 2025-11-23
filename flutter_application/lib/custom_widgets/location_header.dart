import 'package:flutter/material.dart';
import 'package:flutter_application/models/user.dart';
import 'package:flutter_application/theme.dart';
import 'location_picker.dart';


class LocationHeader extends StatefulWidget {
  const LocationHeader({super.key});

  @override
  State<LocationHeader> createState() => _LocationHeaderState();
}

class _LocationHeaderState extends State<LocationHeader> {
  late String _state;
  late String _district;
  late String _city;

  @override
  void initState() {
    super.initState();
    _state = AppUser().state ?? '';
    _district = AppUser().district ?? '';
    _city = AppUser().city ?? '';
  }

  void _showLocationPopup() {
    String tempState = _state;
    String tempDistrict = _district;
    String tempCity = _city;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Change Location"),
          content: LocationPicker(
            initialState: _state,
            initialDistrict: _district,
            initialCity: _city,
            onChanged: (state, district, city) {
              tempState = state ?? '';
              tempDistrict = district ?? '';
              tempCity = city ?? '';
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _state = tempState;
                  _district = tempDistrict;
                  _city = tempCity;
                }); // refresh header display
                //TODO: update user state
                Navigator.of(context).pop();
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: _showLocationPopup,
          borderRadius: BorderRadius.circular(8),
          splashColor: AppTheme.primaryColor.withAlpha(80),
          highlightColor: AppTheme.primaryColor.withAlpha(50),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.location_on, color: AppTheme.primaryColor, size: 36),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _state,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _district.isNotEmpty && _city.isNotEmpty
                            ? "$_district, $_city"
                            : "",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}