import 'dart:io';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application/custom_widgets/image_picker_btn.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_application/custom_widgets/section.dart';
import 'package:flutter_application/models/furniture.dart';
import 'package:flutter_application/services/api_service.dart';
import 'package:flutter_application/services/furniture_service.dart';
import 'package:flutter_application/theme.dart';

class EditFurniturePage extends StatefulWidget {
  final Furniture furniture;

  const EditFurniturePage({super.key, required this.furniture});

  @override
  State<EditFurniturePage> createState() => _EditFurniturePageState();
}

class _EditFurniturePageState extends State<EditFurniturePage> {
  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _noteController;

  // State Variables
  late String _selectedStatus;
  final List<String> _statusOptions = ["Good", "Damaged", "Repaired", "Disposed"];
  
  XFile? _newImage;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Initialize with existing data
    _nameController = TextEditingController(text: widget.furniture.name);
    _priceController = TextEditingController(text: widget.furniture.purchasePrice.toString());
    _noteController = TextEditingController(text: widget.furniture.note ?? "");
    _selectedStatus = widget.furniture.status;
    
    // Validate status match
    if (!_statusOptions.contains(_selectedStatus)) {
      _selectedStatus = "Good";
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _noteController.dispose();
    super.dispose();
  }


  Future<void> _deleteFurniture() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Furniture"),
        content: const Text(
          "Are you sure you want to delete this item? This will also permanently delete all associated logs. This action cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isSubmitting = true);
    
    try {
      final success = await FurnitureService.deleteFurniture(widget.furniture.id);
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Furniture deleted successfully")),
          );
   
          Navigator.pop(context); 
          Navigator.pop(context, true); 
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Failed to delete furniture")),
          );
        }
      }
    } catch (e) {
      debugPrint("Delete error: $e");
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _submitUpdates() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Furniture name is required")),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      Map<String, dynamic> fields = {
        'name': _nameController.text.trim(),
        'status': _selectedStatus,
        'purchase_price': double.tryParse(_priceController.text) ?? 0.0,
        'note': _noteController.text.trim(),
      };

      final success = await FurnitureService.updateFurniture(
        furnitureId: widget.furniture.id,
        fields: fields,
        image: _newImage,
      );

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Furniture updated successfully")),
          );
          Navigator.pop(context, true); // Return true to refresh details
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Failed to update furniture")),
          );
        }
      }
    } catch (e) {
      debugPrint("Exception: $e");
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Image Logic: New Local Image > Existing Network Image > Placeholder
    ImageProvider? displayImage;
    if (_newImage != null) {
      displayImage = kIsWeb 
          ? NetworkImage(_newImage!.path) 
          : FileImage(File(_newImage!.path)) as ImageProvider;
    } else if (widget.furniture.imageUrl != null && widget.furniture.imageUrl!.isNotEmpty) {
      displayImage = NetworkImage(ApiService.buildImageUrl(widget.furniture.imageUrl!));
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "Edit Furniture",
          style: TextStyle(color: Colors.white,),
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
            // Image Picker

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
                        // Logic: Show New Image -> Show Existing URL -> Show Null
                        image: displayImage != null
                            ? DecorationImage(
                                image: displayImage,
                                fit: BoxFit.cover, 
                              )
                            : null,
                      ),
                      child: displayImage == null
                          ? const Icon(Icons.image, size: 50, color: Colors.grey)
                          : null,
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    right: 24,
                    child: Container(
                      decoration: BoxDecoration(
             
                        color: Colors.white.withValues(alpha: .8),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: .1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      // REPLACE the old IconButton with this:
                      child: ImagePickerButton(
                        icon: const Icon(Icons.add_a_photo, color: AppTheme.primaryColor),
                        onImageSelected: (XFile file) {
                          setState(() => _newImage = file);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Item Details
            section(
              "Item Details",
              Column(
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: "Item Name",
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

            // Notes
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

            // Bottom Buttons (Delete & Save)
            Row(
              children: [
                // Delete Button (Secondary/Red)
                Expanded(
                  flex: 1,
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _isSubmitting ? null : _deleteFurniture,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[50],
                        foregroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: const BorderSide(color: Colors.red),
                        ),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.delete_outline),
                      label: const Text("Delete"),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                
                // Save Button (Primary)
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitUpdates,
                      style: AppTheme.primaryButton,
                      child: _isSubmitting
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("Save Changes", style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}