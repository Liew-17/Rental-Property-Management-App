import 'dart:io';
import 'package:flutter/foundation.dart'; 
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; 

class ImageUploader extends StatefulWidget {
  final void Function(List<XFile>)? onFilesChanged;
  final int maxFiles;

  const ImageUploader({
    super.key,
    this.onFilesChanged,
    this.maxFiles = 5,
  });

  @override
  State<ImageUploader> createState() => _ImageUploaderState();
}

class _ImageUploaderState extends State<ImageUploader> {
  final List<XFile> _selectedFiles = [];
  final ImagePicker _picker = ImagePicker();


  void _showSelectionSheet() {

    if (_selectedFiles.length >= widget.maxFiles) {
      _showLimitWarning();
      return;
    }

    // WEB CASE: Browsers handle source selection automatically
    if (kIsWeb) {
      _pickFromGallery(); 
      return;
    }

    // MOBILE CASE: Show choice
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Take a Photo'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickFromCamera();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickFromGallery();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickFromCamera() async {
    try {
      final XFile? picked = await _picker.pickImage(source: ImageSource.camera);
      if (picked != null) {
        _processPickedFiles([picked]);
      }
    } catch (e) {
      debugPrint("Error picking from camera: $e");
    }
  }


  Future<void> _pickFromGallery() async {
    try {
      final List<XFile> picked = await _picker.pickMultiImage();
      if (picked.isNotEmpty) {
        _processPickedFiles(picked);
      }
    } catch (e) {
      debugPrint("Error picking from gallery: $e");
    }
  }

  void _processPickedFiles(List<XFile> newFiles) {
    int availableSlots = widget.maxFiles - _selectedFiles.length;
    
    
    if (availableSlots <= 0) {
      _showLimitWarning();
      return;
    }

    List<XFile> filesToAdd = newFiles;

    // Truncate if user selected too many
    if (newFiles.length > availableSlots) {
      filesToAdd = newFiles.take(availableSlots).toList();
      _showLimitWarning(); 
    }

    setState(() {
      _selectedFiles.addAll(filesToAdd);
    });
    
    widget.onFilesChanged?.call(_selectedFiles);
  }

  void _removeFile(int index) {
    setState(() => _selectedFiles.removeAt(index));
    widget.onFilesChanged?.call(_selectedFiles);
  }

  void _showLimitWarning() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Limit Reached"),
        content: Text("You can upload maximum ${widget.maxFiles} images."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK")
          )
        ],
      ),
    );
  }

  Widget _buildImagePreview(XFile file) {
    if (kIsWeb) {
      return Image.network(
        file.path,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) => 
            const Icon(Icons.broken_image, color: Colors.grey),
      );
    } else {
      return Image.file(
        File(file.path),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) => 
            const Icon(Icons.broken_image, color: Colors.grey),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
 
        ElevatedButton.icon(
          onPressed: _showSelectionSheet, 
          icon: const Icon(Icons.add_photo_alternate),
          label: Text("Add Images (${_selectedFiles.length}/${widget.maxFiles})"),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        const SizedBox(height: 16),

        if (_selectedFiles.isNotEmpty)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(), 
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3, 
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1, 
            ),
            itemCount: _selectedFiles.length,
            itemBuilder: (context, index) {
              final file = _selectedFiles[index];
              return Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      color: Colors.grey[200],
                      width: double.infinity,
                      height: double.infinity,
                      child: _buildImagePreview(file),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => _removeFile(index),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
      ],
    );
  }
}