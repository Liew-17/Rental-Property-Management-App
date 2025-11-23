import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_application/custom_widgets/location_picker.dart';
import 'package:flutter_application/theme.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';                                         
import 'package:flutter_application/services/api_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AddPropertyPage extends StatefulWidget {

  const AddPropertyPage({super.key});

  @override
  State<AddPropertyPage> createState() => _AddPropertyPageState();
}

class _AddPropertyPageState extends State<AddPropertyPage> {
  final _formKey = GlobalKey<FormState>();
  
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


  XFile? _thumbnail;
  final picker = ImagePicker();

  Future<void> _pickThumbnail() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _thumbnail = pickedFile;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;

    final uri = ApiService.buildUri("/property/add_residence_property");

    try {
      final request = http.MultipartRequest('POST', uri);

      request.fields['uid'] = uid.toString();
      request.fields['name'] = _nameController.text;
      request.fields['title'] = _titleController.text;
      request.fields['description'] = _descriptionController.text;
      request.fields['state'] = _selectedState ?? "";
      request.fields['district'] = _selectedDistrict ?? "";
      request.fields['city'] = _selectedCity ?? "";
      request.fields['address'] = _addressController.text;
      request.fields['num_bedrooms'] = int.tryParse(_numBedroomsController.text)?.toString() ?? "0";
      request.fields['num_bathrooms'] = int.tryParse(_numBathroomsController.text)?.toString() ?? "0";
      request.fields['land_size'] = double.tryParse(_landSizeController.text)?.toString() ?? "0"; 
      request.fields['features'] = ""; // optional
      request.fields['rules'] = "";    // optional

      // Add thumbnail if exist
      if (_thumbnail != null) {
        final bytes = await _thumbnail!.readAsBytes(); // read the XFile as bytes
        final fileName = _thumbnail!.name; 

        request.files.add(http.MultipartFile.fromBytes(
          'thumbnail', 
          bytes,
          filename: fileName, 
        ));
      }

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        final thumbnailUrl = responseData["thumbnail_url"]; // if backend returns it
        debugPrint("Thumbnail URL: $thumbnailUrl");
      } else {
        final error = jsonDecode(response.body);
        debugPrint("Error adding property: ${error['error_message']}");
      }
    } catch (e) {
      debugPrint("Exception: $e");
      debugPrint("Failed to submit property");
    }
  }

  @override
  Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text(
          "New Property",
          style: TextStyle(
            color: Colors.white, 
            fontWeight: FontWeight.bold,
          ),
      ),
        centerTitle: true, 
        backgroundColor: AppTheme.primaryColor,
      ),

    body: SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
                  horizontal: 24.0, // more padding left & right
                  vertical: 16.0,   // keep same top & bottom
                ),
      child: Form(
        key: _formKey,
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
                        image: _thumbnail != null?
                                DecorationImage(
                                  image: kIsWeb?
                                    NetworkImage(_thumbnail!.path) // allows preview for website
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
                    bottom: 4, 
                    right: 20, 
                    child: IconButton(
                      icon: const Icon(Icons.add_a_photo, color: AppTheme.primaryColor),
                      onPressed: _pickThumbnail,
                    ),
                  ),
                ],
              ),
          ),
            const SizedBox(height: 20),

            // Property Name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: "Property Name"),
              validator: (value) =>
                  value == null || value.isEmpty ? "Name is required" : null,
            ),
            const SizedBox(height: 10),

            // Title
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: "Title"),
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: "Description",
                alignLabelWithHint: true, // makes label align to top-left
                border: OutlineInputBorder(), // optional: makes it look like a textbox
              ),
              keyboardType: TextInputType.multiline,
              maxLines: 8, // <-- text area height (adjust as you want)
              minLines: 3, // optional
            ),

            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _numBedroomsController,
                    decoration: const InputDecoration(
                      labelText: "Bedrooms",
                      prefixIcon: Icon(Icons.bed, color: AppTheme.primaryColor),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly, 
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _numBathroomsController,
                    decoration: const InputDecoration(
                      labelText: "Bathrooms",
                      prefixIcon: Icon(Icons.bathtub, color: AppTheme.primaryColor),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly, 
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _landSizeController,
                    decoration: const InputDecoration(
                      labelText: "Area (sqft)",
                      prefixIcon: Icon(Icons.square_foot, color: AppTheme.primaryColor),
                    ),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),  // allows decimal
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),

            // Location picker for State/District/City 
            LocationPicker(
              onChanged: (state, district, city) {
                _selectedState = state ?? '';
                _selectedDistrict = district ?? '';
                _selectedCity = city ?? '';
              }, 
            
            ),

            const SizedBox(height: 10),

            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: "Address (Street, etc.)",
                prefixIcon: Icon(Icons.location_on, color: AppTheme.primaryColor),
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
    ),
  );
}

}
