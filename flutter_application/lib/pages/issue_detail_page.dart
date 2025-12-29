import 'package:flutter/material.dart';
import 'package:flutter_application/models/reported_issue.dart';
import 'package:flutter_application/services/api_service.dart';
import 'package:flutter_application/services/issue_service.dart';
import 'package:flutter_application/theme.dart';
import 'package:galleryimage/galleryimage.dart';
import 'package:intl/intl.dart';

class IssueDetailPage extends StatefulWidget {
  final int issueId;
  final bool isOwnerMode;

  const IssueDetailPage({
    super.key, 
    required this.issueId,
    required this.isOwnerMode,
  });

  @override
  State<IssueDetailPage> createState() => _IssueDetailPageState();
}

class _IssueDetailPageState extends State<IssueDetailPage> {
  ReportedIssue? _issue;
  bool _isLoading = true;
  String _errorMessage = '';
  List<String> _imgUrls = [];

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final issue = await IssueService.getIssueDetail(widget.issueId);

      if (mounted) {
        setState(() {
          _issue = issue;

          if(issue !=null){
            _imgUrls = _issue!.images?.map((img) => ApiService.buildImageUrl(img)).toList()?? [];
          }
           
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Failed to load details";
          _isLoading = false;
        });
      }
    }
  }

  void _updateStatus(String status) async {
    setState(() => _isLoading = true);
    final success = await IssueService.updateStatus(widget.issueId, status);
    
    if (success) {
      await _fetchDetail();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Status updated to $status")),
        );
      }
    } else {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to update status")),
        );
      }
    }
  }

  void _showResolveDialog() {
    final noteController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Resolve Issue"),
        content: TextField(
          controller: noteController,
          decoration: const InputDecoration(
            labelText: "Resolution Notes",
            hintText: "How was this fixed?",
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text("Cancel")
          ),
          ElevatedButton(
            style: AppTheme.primaryButton,
            onPressed: () async {
              Navigator.pop(context); 
              
              setState(() => _isLoading = true);
              final success = await IssueService.resolveIssue(widget.issueId, noteController.text);
              
              if (success) {
                await _fetchDetail();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Issue resolved successfully!")),
                  );
                }
              } else {
                setState(() => _isLoading = false);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Failed to resolve issue")),
                  );
                }
              }
            },
            child: const Text("Resolve"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text("Issue Details"), backgroundColor: AppTheme.primaryColor),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_issue == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Issue Details"), backgroundColor: AppTheme.primaryColor),
        body: Center(child: Text(_errorMessage.isNotEmpty ? _errorMessage : "Issue not found")),
      );
    }

    final issue = _issue!;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Issue Details"),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    issue.title,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                _buildStatusBadge(issue.status),
              ],
            ),
            const SizedBox(height: 8),
            
            // Meta Info
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  DateFormat.yMMMd().format(issue.reportedAt),
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.flag, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  "Priority: ${issue.priority.toUpperCase()}",
                  style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                ),
              ],
            ),

            const Divider(height: 30),

            // Description
            const Text("Description", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              issue.description ?? "No description provided.",
              style: const TextStyle(fontSize: 15, height: 1.4),
            ),

            const SizedBox(height: 20),

            // Images
            if (issue.images != null && issue.images!.isNotEmpty) ...[
              const Text("Attached Images", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              GalleryImage(
                imageUrls: _imgUrls,
                numOfShowImages: _imgUrls.length,
                galleryBackgroundColor: Colors.white,
                titleGallery: "",
              ),
              const SizedBox(height: 20),
            ],

            // Resolution Info
            if (issue.status == 'resolved' && issue.resolutionNotes != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withValues(alpha: 0.5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 20),
                        SizedBox(width: 8),
                        Text("Resolution Notes", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(issue.resolutionNotes!),
                    if (issue.resolvedAt != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          "Resolved on: ${DateFormat.yMMMd().format(issue.resolvedAt!)}", 
                          style: const TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
            ],

     // Owner Action Buttons (Strictly controlled by widget.isOwnerMode)
        if (widget.isOwnerMode && issue.status != 'resolved') ...[
          const Divider(),
          const SizedBox(height: 10),
          const Text(
            "Actions",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Show "In Progress" button only if status is pending
              if (issue.status == 'pending')
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () => _updateStatus('in_progress'),
                      icon: const Icon(Icons.play_arrow),
                      label: const Text("Mark As Progress"),
                      style: AppTheme.secondaryButton,
                
                    ),
                  ),
                ),
              
              if (issue.status == 'pending') const SizedBox(width: 12),

              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _showResolveDialog,
                    icon: const Icon(Icons.check),
                    label: const Text("Resolve"),
                    style: AppTheme.primaryButton,
                  ),
                ),
              ),
            ],
          ),
        ],
                

          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = AppTheme.getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
      child: Text(
        status.toUpperCase(), 
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }
}