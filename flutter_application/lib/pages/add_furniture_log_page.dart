import 'dart:io';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:flutter_application/services/furniture_service.dart';
import 'package:flutter_application/theme.dart';
import 'package:flutter_application/custom_widgets/section.dart'; 

class AddFurnitureLogPage extends StatefulWidget {
  final int furnitureId;
  final String currentStatus;

  const AddFurnitureLogPage({
    super.key, 
    required this.furnitureId,
    required this.currentStatus,
  });

  @override
  State<AddFurnitureLogPage> createState() => _AddFurnitureLogPageState();
}

class _AddFurnitureLogPageState extends State<AddFurnitureLogPage> {
  // Controllers
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  
  // State
  String _selectedType = "Maintenance";
  DateTime _selectedDate = DateTime.now();
  XFile? _image;
  bool _isSubmitting = false;

  final ImagePicker _picker = ImagePicker();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _dateController.text = DateFormat('yyyy-MM-dd').format(_selectedDate);
    
    // Smart Default: If item is broken, user likely wants to Repair or Dispose it
    if (widget.currentStatus == 'Damaged') {
      _selectedType = "Repair";
    }
  }

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

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000), 
      lastDate: DateTime.now(),  
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // Special Warning for Disposal
    if (_selectedType == 'Dispose') {
       final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Confirm Disposal"),
          content: const Text("Marking this item as Disposed is permanent. You won't be able to add new logs to it."),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
            TextButton(
              onPressed: () => Navigator.pop(context, true), 
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text("Confirm")
            ),
          ],
        ),
      );
      if (confirm != true) return;
    }

    setState(() => _isSubmitting = true);

    try {
      final logId = await FurnitureService.addLog(
        furnitureId: widget.furnitureId,
        logType: _selectedType,
        description: _descriptionController.text.trim(),
        date: _selectedDate,
        image: _image,
      );


        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Log added successfully")),
          );
          Navigator.pop(context, true); // Return true to refresh previous page
        }
      
    } catch (e) {
      debugPrint("Error: $e");
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Add Log", style: TextStyle(color: Colors.white, )),
        centerTitle: true,
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Form(
          key: _formKey,
          child: Column(
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
              
              const SizedBox(height: 32),

              section(
                "Event Details",
                Column(
                  children: [

                    DropdownButtonFormField<String>(
                      initialValue: _selectedType,
                      decoration: const InputDecoration(
                        labelText: "Log Event Type",
                        prefixIcon: Icon(Icons.category_outlined, color: AppTheme.primaryColor),
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      items: ["Maintenance", "Damage", "Repair", "Dispose"]
                          .map((type) => DropdownMenuItem(
                                value: type,
                                child: Text(type),
                              ))
                          .toList(),
                      onChanged: (val) => setState(() => _selectedType = val!),
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _dateController,
                      readOnly: true,
                      onTap: _pickDate,
                      decoration: const InputDecoration(
                        labelText: "Date",
                        prefixIcon: Icon(Icons.calendar_today_outlined, color: AppTheme.primaryColor),
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 3,
                      validator: (value) => value == null || value.isEmpty ? "Please enter a description" : null,
                      decoration: const InputDecoration(
                        labelText: "Description",
                        hintText: "What happened? e.g., 'Fixed loose leg'",
                        alignLabelWithHint: true,
                        prefixIcon: Padding(
                          padding: EdgeInsets.only(bottom: 48), 
                          child: Icon(Icons.description_outlined, color: AppTheme.primaryColor),
                        ),
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: AppTheme.primaryButton,
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Save Log"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}