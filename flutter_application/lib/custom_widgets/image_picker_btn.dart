import 'package:flutter/foundation.dart'; 
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ImagePickerButton extends StatelessWidget {
  final Function(XFile) onImageSelected;
  final Widget icon;
  final ImagePicker _picker = ImagePicker();

  ImagePickerButton({
    super.key,
    required this.onImageSelected,
    required this.icon,
  });

  Future<void> _handleImageSelection(BuildContext context, ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        onImageSelected(pickedFile);
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  void _showSelectionSheet(BuildContext context) {
    // WEB SCENARIO: 
    if (kIsWeb) {
      _handleImageSelection(context, ImageSource.gallery);
      return;
    }

    // MOBILE SCENARIO:
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
                  _handleImageSelection(context, ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(ctx);
                  _handleImageSelection(context, ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: icon,
      onPressed: () => _showSelectionSheet(context),
    );
  }
}