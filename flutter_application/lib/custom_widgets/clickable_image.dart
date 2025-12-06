import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

class ClickableImage extends StatelessWidget {
  final String imageUrl;
  final String fileName;

  const ClickableImage({super.key, required this.imageUrl, required this.fileName});

  Future<void> downloadImage(BuildContext context) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final path = '${dir.path}/$fileName';
      await Dio().download(imageUrl, path);
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
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FullScreenImage(imageUrl: imageUrl, fileName: fileName),
          ),
        );
      },
      child: Image.network(
        imageUrl,
        width: 150,
        height: 150,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const Icon(Icons.broken_image),
      ),
    );
  }
}

class FullScreenImage extends StatelessWidget {
  final String imageUrl;
  final String fileName;

  const FullScreenImage({super.key, required this.imageUrl, required this.fileName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.download),
            onPressed: () => ClickableImage(imageUrl: imageUrl, fileName: fileName).downloadImage(context),
          ),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          child: Image.network(imageUrl),
        ),
      ),
    );
  }
}
