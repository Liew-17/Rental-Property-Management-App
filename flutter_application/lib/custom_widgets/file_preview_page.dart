import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application/services/api_service.dart';
import 'package:flutter_application/theme.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:url_launcher/url_launcher.dart'; // Import url_launcher
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
// For web download support


class FilePreviewPage extends StatefulWidget {
  final String fileUrl;
  final String fileName;

  const FilePreviewPage({
    super.key,
    required this.fileUrl,
    required this.fileName,
  });

  @override
  State<FilePreviewPage> createState() => _FilePreviewPageState();
}

class _FilePreviewPageState extends State<FilePreviewPage> {
  bool _isDownloading = false;
  String? _errorMessage; // To store loading errors

  // === Open in Browser (Fail-Safe) ===
  Future<void> _openInBrowser() async {
    final url = Uri.parse(ApiService.buildFileUrl(widget.fileUrl));
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open file in browser')),
      );
    }
  }

  // === Permanent Download Logic ===
  Future<void> _downloadFile() async {
    setState(() => _isDownloading = true);
    final url = ApiService.buildFileUrl(widget.fileUrl,download: true);

    try {
      if (kIsWeb) {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          

        }
      } else {
        Directory? downloadsDir;
        if (Platform.isAndroid) {
          downloadsDir = await getExternalStorageDirectory();
          if (downloadsDir != null) {
             final path = downloadsDir.path.split("Android")[0];
             downloadsDir = Directory('$path/Download');
             if (!await downloadsDir.exists()) downloadsDir = await getExternalStorageDirectory();
          }
        } else {
          downloadsDir = await getApplicationDocumentsDirectory();
        }
        
        final filePath = '${downloadsDir!.path}/${widget.fileName}';
        await Dio().download(url, filePath);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Saved to $filePath')),
          );
        }
      }
    } catch (e) {
      debugPrint("Download Error: $e");
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fullUrl = ApiService.buildImageUrl(widget.fileUrl);
    final ext = widget.fileName.split('.').last.toLowerCase();
    final isPdf = ext == 'pdf';
    final isImage = ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent, 
        elevation: 0,
        automaticallyImplyLeading: false, 
        title: Text(widget.fileName, style: const TextStyle(color: Colors.black)),
        actions: [
          _isDownloading 
            ? const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator())
            : IconButton(
                icon: const Icon(Icons.download_rounded, color: AppTheme.primaryColor),
                onPressed: _downloadFile,
                tooltip: "Download",
              ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.black54),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: Center(
        child: isImage
            ? InteractiveViewer(child: Image.network(fullUrl))
            : isPdf
                ? _errorMessage != null
                    ? _buildErrorState() // Show fallback if loading failed
                    : SfPdfViewer.network(
                        fullUrl,
                        onDocumentLoadFailed: (details) {
                          setState(() {
                            // Capture the error to show the fallback UI
                            _errorMessage = details.description;
                          });
                        },
                      )
                : const Text("Preview not supported."),
      ),
    );
  }

  // === Fallback UI when PDF fails to load (Common on Web) ===
  Widget _buildErrorState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.error_outline, color: Colors.red, size: 60),
        const SizedBox(height: 16),
        const Text(
          "Preview could not be loaded.",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          "Browser blocked the preview due to security settings.",
          style: TextStyle(color: Colors.grey[600]),
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: _openInBrowser,
          icon: const Icon(Icons.open_in_new),
          label: const Text("Open in New Tab"),
          style: AppTheme.primaryButton,
        ),
      ],
    );
  }
}