import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_application/custom_widgets/location_picker.dart';
import 'package:flutter_application/custom_widgets/residence_type_picker.dart';
import 'package:flutter_application/custom_widgets/section.dart';
import 'package:flutter_application/theme.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application/services/api_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AddPropertyPage extends StatefulWidget {
  const AddPropertyPage({super.key});

  @override
  State<AddPropertyPage> createState() => _AddPropertyPageState();
}

class _AddPropertyPageState extends State<AddPropertyPage> {
  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _numBedroomsController = TextEditingController();
  final TextEditingController _numBathroomsController = TextEditingController();
  final TextEditingController _landSizeController = TextEditingController();

  String? _selectedState;
  String? _selectedDistrict;
  String? _selectedCity;
  String? _selectedResidenceType;

  XFile? _thumbnail;
  final picker = ImagePicker();

  Future<void> _pickThumbnail() async {
    try {
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() => _thumbnail = pickedFile);
      }
    } catch (e) {
      debugPrint("Thumbnail pick error: $e");
    }
  }

  Future<void> _submit() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Property name is required")),
      );
      return;
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;
    final uri = ApiService.buildUri("/property/add_residence_property");

    try {
      final request = http.MultipartRequest('POST', uri);

      request.fields['uid'] = uid ?? '';
      request.fields['name'] = _nameController.text;
      request.fields['title'] = _titleController.text;
      request.fields['description'] = _descriptionController.text;
      request.fields['state'] = _selectedState ?? '';
      request.fields['district'] = _selectedDistrict ?? '';
      request.fields['city'] = _selectedCity ?? '';
      request.fields['address'] = _addressController.text;
      request.fields['num_bedrooms'] = int.tryParse(_numBedroomsController.text)?.toString() ?? '0';
      request.fields['num_bathrooms'] = int.tryParse(_numBathroomsController.text)?.toString() ?? '0';
      request.fields['land_size'] = double.tryParse(_landSizeController.text)?.toString() ?? '0';
      request.fields['residence_type'] = _selectedResidenceType ?? 'Apartment';
      request.fields['features'] = '';
      request.fields['rules'] = '';

      if (_thumbnail != null) {
        final bytes = await _thumbnail!.readAsBytes();
        request.files.add(
          http.MultipartFile.fromBytes('thumbnail', bytes, filename: _thumbnail!.name),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
          if(mounted){
            Navigator.pop(context, true); 
          }
      } else {
        final error = jsonDecode(response.body);
        debugPrint("Error adding property: ${error['error_message']}");
      }
    } catch (e) {
      debugPrint("Exception: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "New Property",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: AppTheme.primaryColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail picker
            Center(
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Container(
                      width: double.infinity,
                      height: 300,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                        image: _thumbnail != null
                            ? DecorationImage(
                                image: kIsWeb
                                    ? NetworkImage(_thumbnail!.path)
                                    : FileImage(File(_thumbnail!.path)) as ImageProvider,
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: _thumbnail == null
                          ? const Icon(Icons.image, size: 50, color: Colors.grey)
                          : null,
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    right: 24,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .8), // Transparent white background
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: .1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.add_a_photo, color: AppTheme.primaryColor),
                        onPressed: _pickThumbnail,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Property Info Section
            section(
              "Property Info",
              Column(
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: "Property Name"),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: "Title"),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: "Description",
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.multiline,
                    maxLines: 5,
                  ),
                ],
              ),
            ),

            // House Details Section
            section(
              "House Details",
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _numBedroomsController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: "Bedrooms",
                        prefixIcon: Icon(Icons.bed, color: AppTheme.primaryColor),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _numBathroomsController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: "Bathrooms",
                        prefixIcon: Icon(Icons.bathtub, color: AppTheme.primaryColor),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _landSizeController,
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                      ],
                      decoration: const InputDecoration(
                        labelText: "Area (sqft)",
                        prefixIcon: Icon(Icons.square_foot, color: AppTheme.primaryColor),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            
            const SizedBox(height: 30),

            section(
              "Residence Type",
              ResidenceTypePicker(
              onChanged: (value) {
                  setState(() {
                    _selectedResidenceType = value;
                  });
                },
              )
            ),

            // Location Section
            section(
              "Location",
              Column(
                children: [
                  LocationPicker(
                    onChanged: (state, district, city) {
                      _selectedState = state;
                      _selectedDistrict = district;
                      _selectedCity = city;
                    },
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _addressController,
                    decoration: const InputDecoration(
                      labelText: "Address (Street, etc.)",
                      prefixIcon: Icon(Icons.location_on, color: AppTheme.primaryColor),
                    ),
                  ),
                ],
              ),
            ),

            

            const SizedBox(height: 30),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submit,
                style: AppTheme.primaryButton,
                child: const Text("Add Property"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
