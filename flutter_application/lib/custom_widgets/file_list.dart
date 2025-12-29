import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_application/custom_widgets/file_preview_page.dart';
import 'package:flutter_application/models/request.dart';
import 'package:flutter_application/services/api_service.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';


class FileList extends StatefulWidget {
  final List<RequestDocument> files;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  const FileList({
    super.key,
    required this.files,
    this.shrinkWrap = false,
    this.physics,
  });

  @override
  State<FileList> createState() => _FileListState();
}

class _FileListState extends State<FileList> {
  final Map<String, double> _progress = {};

  Future<void> _downloadFile(RequestDocument file) async {
    final fileName = file.originalFilename;
    final fileUrl = ApiService.buildFileUrl(file.fileUrl, download: true);

      if (kIsWeb) {
      final uri = Uri.parse(fileUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Download started for $fileName')),
        );
      }
    } else {
      try {
        Directory? downloadsDir;

        if (Platform.isAndroid) {
          downloadsDir = await getExternalStorageDirectory();
          if (downloadsDir != null) {

            final path = downloadsDir.path.split("Android")[0];
            downloadsDir = Directory('$path/Download');
            if (!await downloadsDir.exists()) {
               downloadsDir = await getExternalStorageDirectory();
            }
          }
        } else if (Platform.isIOS) {
          downloadsDir = await getApplicationDocumentsDirectory();
        }

        if (downloadsDir == null) throw Exception("Cannot access storage");

        final filePath = '${downloadsDir.path}/$fileName';
        final dio = Dio();

        await dio.download(
          fileUrl,
          filePath,
          onReceiveProgress: (received, total) {
            if (total != -1) {
              setState(() {
                _progress[file.fileUrl] = received / total;
              });
            }
          },
        );
        
        if (mounted) {
           setState(() {
            _progress.remove(file.fileUrl); // Clear progress when done
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Downloaded to ${downloadsDir.path}')),
          );
        }
      } catch (e) {
        debugPrint("Error downloading file: $e");
        if (mounted) {
           setState(() {
            _progress.remove(file.fileUrl);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to download file: $e')),
          );
        }
      }
    }
  }
  
  void _openPreview(RequestDocument file) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FilePreviewPage(
          fileUrl: file.fileUrl,
          fileName: file.originalFilename,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.files.isEmpty) {
      return const Center(child: Text("No files available."));
    }

    return Column(
      children: widget.files.map((file) {
        final progress = _progress[file.fileUrl];
        final isImage = ['jpg', 'jpeg', 'png', 'gif', 'webp']
            .contains(file.fileFormat.toLowerCase());

        return Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                isImage ? Icons.image : Icons.insert_drive_file,
                color: Colors.grey[700],
                size: 24,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  file.originalFilename,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
              
              // === Preview Button ===
              IconButton(
                icon: const Icon(Icons.visibility_outlined),
                color: Colors.blueGrey,
                tooltip: "Preview",
                onPressed: () => _openPreview(file),
              ),
              
              // === Download Button or Progress ===
              progress != null
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(value: progress, strokeWidth: 3),
                    )
                  : IconButton(
                      icon: const Icon(Icons.download_rounded),
                      color: Colors.blue,
                      tooltip: "Download",
                      onPressed: () => _downloadFile(file),
                    ),
            ],
          ),
        );
      }).toList(),
    );
  }
}