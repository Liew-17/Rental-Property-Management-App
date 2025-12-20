import 'dart:io';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_application/custom_widgets/section.dart';
import 'package:flutter_application/services/furniture_service.dart';
import 'package:flutter_application/theme.dart';

class AddFurniturePage extends StatefulWidget {
  final int propertyId;

  const AddFurniturePage({super.key, required this.propertyId});

  @override
  State<AddFurniturePage> createState() => _AddFurniturePageState();
}

class _AddFurniturePageState extends State<AddFurniturePage> {
  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  // State Variables
  String _selectedStatus = "Good";
  final List<String> _statusOptions = ["Good", "Damaged", "Repaired", "Disposed"];
  
  XFile? _image;
  final ImagePicker _picker = ImagePicker();
  bool _isSubmitting = false;

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() => _image = pickedFile);
      }
    } catch (e) {
      debugPrint("Image pick error: $e");
    }
  }

  Future<void> _submit() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Furniture name is required")),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final success = await FurnitureService.createFurniture(
        propertyId: widget.propertyId,
        name: _nameController.text.trim(),
        status: _selectedStatus,
        purchasePrice: double.tryParse(_priceController.text) ?? 0.0,
        note: _noteController.text.trim(),
        image: _image,
      );

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Furniture added successfully")),
          );
          Navigator.pop(context, true); 
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Failed to add furniture")),
          );
        }
      }
    } catch (e) {
      debugPrint("Exception: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text("Error: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "Add Furniture",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: AppTheme.primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
    
          Center(
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Container(
                      width: double.infinity,
                      height: 250,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                        image: _image != null
                            ? DecorationImage(
                                image: kIsWeb
                                    ? NetworkImage(_image!.path)
                                    : FileImage(File(_image!.path)) as ImageProvider,
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: _image == null
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
                        onPressed: _pickImage,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Basic Info Section
            section(
              "Item Details",
              Column(
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: "Item Name (e.g., Master Bed)",
                      prefixIcon: Icon(Icons.label_outline, color: AppTheme.primaryColor),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _priceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                    ],
                    decoration: const InputDecoration(
                      labelText: "Purchase Price",
                      prefixIcon: Icon(Icons.attach_money, color: AppTheme.primaryColor),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedStatus,
                    decoration: const InputDecoration(
                      labelText: "Status",
                      prefixIcon: Icon(Icons.info_outline, color: AppTheme.primaryColor),
                    ),
                    items: _statusOptions.map((status) {
                      return DropdownMenuItem(
                        value: status,
                        child: Text(status),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedStatus = val!),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Notes Section
            section(
              "Notes",
              TextField(
                controller: _noteController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: "Description, Brand, or Model...",
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: AppTheme.primaryButton,
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Add Furniture", style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}