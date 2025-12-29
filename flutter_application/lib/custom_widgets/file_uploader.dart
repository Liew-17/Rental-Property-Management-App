import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cross_file/cross_file.dart';
import 'dart:typed_data';

class XFileUploadWidget extends StatefulWidget {
  final void Function(List<XFile>)? onFilesChanged;
  final int maxFiles; 

  const XFileUploadWidget({
    super.key,
    this.onFilesChanged,
    this.maxFiles = 5, // default max = 5
  });

  @override
  State<XFileUploadWidget> createState() => _XFileUploadWidgetState();
}

class _XFileUploadWidgetState extends State<XFileUploadWidget> {
  final List<XFile> _selectedFiles = [];

  Future<void> _pickFiles() async {
    if (_selectedFiles.length >= widget.maxFiles) {
      _showLimitWarning();
      return;
    }

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['jpg', 'png', 'pdf'],
        withData: kIsWeb, 
      );

      if (result != null) {
        List<XFile> files = result.files.map((pf) {
          if (kIsWeb) {
            return XFile.fromData(pf.bytes!, name: pf.name);
          } else {

            if (pf.path != null) {
              return XFile(pf.path!, name: pf.name);
            } else {
              return XFile.fromData(pf.bytes ?? Uint8List(0), name: pf.name);
            }
          }
        }).toList();

        int availableSlots = widget.maxFiles - _selectedFiles.length;
        if (files.length > availableSlots) {
          files = files.take(availableSlots).toList();
          _showLimitWarning();
        }

        setState(() => _selectedFiles.addAll(files));
        
        widget.onFilesChanged?.call(_selectedFiles);
      }
    } catch (e) {
      print("Error picking files: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error picking files: $e")),
      );
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
        title: const Text("File Limit Reached"),
        content: Text("You can upload maximum ${widget.maxFiles} files."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK")
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ElevatedButton.icon(
          onPressed: _pickFiles,
          icon: const Icon(Icons.upload_file),
          label: Text("Pick Files (${_selectedFiles.length}/${widget.maxFiles})"),
        ),
        const SizedBox(height: 10),

        ..._selectedFiles.asMap().entries.map((entry) {
          int index = entry.key;
          XFile file = entry.value;

          return Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.insert_drive_file, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(file.name, overflow: TextOverflow.ellipsis),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.red),
                  onPressed: () => _removeFile(index),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
