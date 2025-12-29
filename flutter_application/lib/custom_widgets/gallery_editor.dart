import 'package:flutter/material.dart';
import 'package:flutter_application/custom_widgets/image_picker_btn.dart';
import 'package:flutter_application/services/api_service.dart';
import 'package:image_picker/image_picker.dart';

class GalleryEditor extends StatefulWidget {
  final List<String> urls;
  final Future<List<String>> Function() fetchGallery;
  final Future<void> Function(XFile file) uploadImage;
  final Future<void> Function(String url) deleteImage;

  const GalleryEditor({
    super.key,
    required this.urls,
    required this.fetchGallery,
    required this.uploadImage,
    required this.deleteImage,
  });

  @override
  State<GalleryEditor> createState() => _GalleryEditorState();
}

class _GalleryEditorState extends State<GalleryEditor> {
  late List<String> _urls;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _urls = widget.urls;
  }

  Future<void> _refreshGallery() async {
    setState(() => _isLoading = true);
    final updated = await widget.fetchGallery();
    setState(() {
      _urls = updated;
      _isLoading = false;
    });
  }

  Future<void> _handleAdd(XFile picked) async {
    setState(() => _isLoading = true); 
    try {
      await widget.uploadImage(picked); 
      await _refreshGallery();           
    } catch (e, stack) {
      debugPrint("Failed to add image: $e");
      debugPrintStack(stackTrace: stack);
      setState(() => _isLoading = false); 
    }
  }

  Future<void> _handleDelete(String url) async {
    setState(() => _isLoading = true);
    await widget.deleteImage(url);
    await Future.delayed(Duration(milliseconds: 500));
    await _refreshGallery();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _isLoading
            ? const LinearProgressIndicator()
            : const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ..._urls.map(  //iterate urls
              (url) => Stack(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    color: Colors.grey[200],
                    child: Image.network(
                      ApiService.buildImageUrl(url),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.broken_image),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () => _handleDelete(url),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(4),
                        child: const Icon(Icons.close,
                            color: Colors.white, size: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
           ImagePickerButton(
              onImageSelected: (XFile file) => _handleAdd(file),

              icon: Container(
                width: 100,
                height: 100,
                color: Colors.grey[300],
                child: const Icon(Icons.add, size: 40, color: Colors.white),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
