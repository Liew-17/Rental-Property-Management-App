import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cross_file/cross_file.dart';
import 'package:flutter_application/custom_widgets/file_uploader.dart';
import 'package:flutter_application/custom_widgets/image_uploader.dart';
import 'package:flutter_application/custom_widgets/section.dart'; // Import the section widget
import 'package:flutter_application/models/user.dart';
import 'package:flutter_application/services/issue_service.dart';
import 'package:flutter_application/theme.dart';

class ReportIssuePage extends StatefulWidget {
  final int propertyId;
  const ReportIssuePage({super.key, required this.propertyId});

  @override
  State<ReportIssuePage> createState() => _ReportIssuePageState();
}

class _ReportIssuePageState extends State<ReportIssuePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  
  String _priority = 'medium';
  List<XFile> _selectedFiles = [];
  bool _isLoading = false;

  void _submitIssue() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    int tenantId = AppUser().id ?? 0; 
    
    if (tenantId == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error: User not logged in")),
      );
      setState(() => _isLoading = false);
      return;
    }

    // Call service
    final result = await IssueService.createIssue(
      propertyId: widget.propertyId,
      tenantId: tenantId,
      title: _titleController.text,
      description: _descController.text,
      priority: _priority,
      images: _selectedFiles,
    );

    setState(() => _isLoading = false);

    // Handle Result & Navigation
    if (result == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Issue reported successfully!"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return to previous page
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to report issue"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5), // Light grey background like Add Property
      appBar: AppBar(
        title: const Text("Report an Issue"),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section 1: Issue Details
              section(
                "Issue Details",
                Column(
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: "Issue Title",
                        hintText: "e.g., Leaking Pipe",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.title, color: AppTheme.primaryColor),
                      ),
                      validator: (v) => v == null || v.isEmpty ? "Required" : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: "Description",
                        hintText: "Describe the issue in detail...",
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                      validator: (v) => v == null || v.isEmpty ? "Required" : null,
                    ),
                  ],
                ),
              ),

              // Section 2: Priority
              section(
                "Priority Level",
                DropdownButtonFormField<String>(
                  value: _priority,
                  decoration: const InputDecoration(
                    labelText: "Select Priority",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.priority_high, color: AppTheme.primaryColor),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'low', child: Text("Low")),
                    DropdownMenuItem(value: 'medium', child: Text("Medium")),
                    DropdownMenuItem(value: 'high', child: Text("High")),
                  ],
                  onChanged: (val) => setState(() => _priority = val!),
                ),
              ),

              // Section 3: Attachments
              section(
                "Attachments",
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Attach photos to help owner understand the issue.",
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    ImageUploader(
                      maxFiles: 3,
                      onFilesChanged: (xFiles) {
                        setState(() {
                          _selectedFiles = xFiles;
                        });
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitIssue,
                  style: AppTheme.primaryButton,
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Submit Report", style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}