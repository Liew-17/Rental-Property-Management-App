import 'package:flutter/material.dart';
import 'package:flutter_application/models/user.dart';
import 'package:flutter_application/services/user_service.dart';
import 'package:flutter_application/theme.dart';
import 'location_picker.dart';


class LocationHeader extends StatefulWidget {
  final void Function()? onChanged;

  const LocationHeader({super.key, this.onChanged});
  
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
            initialState: AppUser().state,
            initialDistrict: AppUser().district, // if issue, check here first
            initialCity: AppUser().city,
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
              onPressed: () async {
                if(await UserService.updateLocation( state: tempState, city: tempCity, district: tempDistrict)){

                  setState(() {
                    _state = tempState;
                    _district = tempDistrict;
                    _city = tempCity;
                  }); // refresh header display

                  widget.onChanged?.call();
                }

                if(context.mounted){
                  Navigator.of(context).pop();
                }
                
                
                
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
                          _district.isNotEmpty?
                             (_city.isNotEmpty ? "$_district, $_city" : _district)
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