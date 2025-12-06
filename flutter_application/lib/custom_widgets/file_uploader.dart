import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cross_file/cross_file.dart';

class XFileUploadWidget extends StatefulWidget {
  final void Function(List<XFile>)? onFilesChanged;

  const XFileUploadWidget({super.key, this.onFilesChanged});

  @override
  // ignore: library_private_types_in_public_api
  _XFileUploadWidgetState createState() => _XFileUploadWidgetState();
}

class _XFileUploadWidgetState extends State<XFileUploadWidget> {
  final List<XFile> _selectedFiles = [];

  Future<void> _pickFiles() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['jpg', 'png', 'pdf'],
      withData: true, // important for web to get bytes
    );

    if (result != null) {
      // Convert PlatformFile -> XFile
      List<XFile> files = result.files.map((pf) {
        if (pf.bytes != null) {
          return XFile.fromData(pf.bytes!, name: pf.name);
        } else if (pf.path != null) {
          return XFile(pf.path!);
        } else {
          throw Exception("Cannot convert PlatformFile to XFile");
        }
      }).toList();

      setState(() {
        _selectedFiles.addAll(files);
      });

      if (widget.onFilesChanged != null) {
        widget.onFilesChanged!(_selectedFiles);
      }
    }
  }

  void _removeFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
    });
    if (widget.onFilesChanged != null) {
      widget.onFilesChanged!(_selectedFiles);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ElevatedButton.icon(
          onPressed: _pickFiles,
          icon: const Icon(Icons.upload_file),
          label: const Text("Pick Files"),
        ),
        const SizedBox(height: 8),
        ..._selectedFiles.asMap().entries.map((entry) {
          int index = entry.key;
          XFile file = entry.value;
          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.insert_drive_file),
            title: Text(file.name),
            trailing: IconButton(
              icon: const Icon(Icons.close, color: Colors.red),
              onPressed: () => _removeFile(index),
            ),
          );
        }).toList(),
      ],
    );
  }
}
