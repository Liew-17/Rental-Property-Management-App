import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_application/models/request.dart';
import 'package:flutter_application/services/api_service.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:web/web.dart' as html;
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'dart:js_interop'; // For JSArray
import 'dart:typed_data'; // For Uint8List
import 'package:web/web.dart' as web;




class FileList extends StatefulWidget {
  final List<RequestDocument> files;
  final bool shrinkWrap; // new
  final ScrollPhysics? physics; // new

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
    final fileUrl = ApiService.buildImageUrl(file.fileUrl);

    if (kIsWeb) {
      final anchor = html.HTMLAnchorElement()
        ..href = fileUrl 
        ..setAttribute("download", fileName)          
        ..click();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$fileName download started (web)')),
      );
    } else {
        try {
          Directory? downloadsDir;

          if (Platform.isAndroid) {
            downloadsDir = await getExternalStorageDirectory();

            if (downloadsDir != null) {
              downloadsDir = Directory('${downloadsDir.parent.parent.parent.parent.path}/Download');
              if (!await downloadsDir.exists()) {
                await downloadsDir.create(recursive: true);
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
                debugPrint("Progress: ${(received / total * 100).toStringAsFixed(0)}%");
              }
            },
          );

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Downloaded $fileName to ${downloadsDir.path}')),
            );
          }

        } catch (e) {
          debugPrint("Error downloading file: $e");
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to download file: $e')),
            );
          }
        }

      
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.files.isEmpty) {
      return const Center(child: Text("No files available."));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: widget.files.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      shrinkWrap: widget.shrinkWrap,
      physics: widget.physics,
      itemBuilder: (context, index) {
        final file = widget.files[index];
        final progress = _progress[file.fileUrl];

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: (0.05)),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  file.originalFilename,
                  style: const TextStyle(fontSize: 16),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              progress != null
                  ? SizedBox(
                      width: 80,
                      child: LinearProgressIndicator(value: progress),
                    )
                  : IconButton(
                      icon: const Icon(Icons.download),
                      color: Colors.blue,
                      onPressed: () => _downloadFile(file),
                    ),
            ],
          ),
        );
      },
    );
  }
}