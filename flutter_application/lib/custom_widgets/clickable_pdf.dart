import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

class ClickablePdf extends StatelessWidget {
  final String pdfUrl;
  final String fileName;

  const ClickablePdf({super.key, required this.pdfUrl, required this.fileName});

  Future<void> downloadPdf(BuildContext context) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final path = '${dir.path}/$fileName';
      await Dio().download(pdfUrl, path);
      if(!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Downloaded to $path')),
      );
    } catch (e) {
      if(!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Download failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(Icons.picture_as_pdf, color: Colors.red),
      title: Text(fileName),
      trailing: IconButton(
        icon: Icon(Icons.download),
        onPressed: () => downloadPdf(context),
      ),
      onTap: () {
        // Open the PDF file in the default PDF viewer (Implemented If have Time)
      },
    );
  }
}
