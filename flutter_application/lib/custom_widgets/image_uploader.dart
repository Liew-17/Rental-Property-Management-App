import 'dart:io';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // using image_picker to match AddPropertyPage
import 'package:cross_file/cross_file.dart';

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

  Future<void> _pickFiles() async {
    if (_selectedFiles.length >= widget.maxFiles) {
      _showLimitWarning();
      return;
    }

    try {
      // Use pickMultiImage to allow selecting multiple images at once
      final List<XFile> pickedFiles = await _picker.pickMultiImage();

      if (pickedFiles.isNotEmpty) {
        // Calculate how many we can actually add
        int availableSlots = widget.maxFiles - _selectedFiles.length;
        List<XFile> filesToAdd = pickedFiles;

        if (pickedFiles.length > availableSlots) {
          filesToAdd = pickedFiles.take(availableSlots).toList();
          _showLimitWarning();
        }

        setState(() {
          _selectedFiles.addAll(filesToAdd);
        });
        
        widget.onFilesChanged?.call(_selectedFiles);
      }
    } catch (e) {
      debugPrint("Error picking images: $e");
    }
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

  /// Displays the image using the same logic as AddPropertyPage
  Widget _buildImagePreview(XFile file) {
    if (kIsWeb) {
      // On Web, ImagePicker gives a blob URL in the path, so we can use NetworkImage
      return Image.network(
        file.path,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) => 
            const Icon(Icons.broken_image, color: Colors.grey),
      );
    } else {
      // On Mobile, we use the File path
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
        // Upload Button
        ElevatedButton.icon(
          onPressed: _pickFiles,
          icon: const Icon(Icons.add_photo_alternate),
          label: Text("Add Images (${_selectedFiles.length}/${widget.maxFiles})"),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        const SizedBox(height: 16),

        // Grid View for Images
        if (_selectedFiles.isNotEmpty)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(), 
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3, // 3 Images per row
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1, // Square tiles
            ),
            itemCount: _selectedFiles.length,
            itemBuilder: (context, index) {
              final file = _selectedFiles[index];
              return Stack(
                children: [
                  // Image Preview
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      color: Colors.grey[200],
                      width: double.infinity,
                      height: double.infinity,
                      child: _buildImagePreview(file),
                    ),
                  ),
                  
                  // Delete Button (X)
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