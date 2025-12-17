import 'package:flutter/material.dart';
import 'package:flutter_application/models/reported_issue.dart';
import 'package:flutter_application/pages/issue_detail_page.dart';
import 'package:flutter_application/services/api_service.dart';
import 'package:flutter_application/services/issue_service.dart';
import 'package:flutter_application/theme.dart';
import 'package:intl/intl.dart';

class IssueListPage extends StatefulWidget {
  final int propertyId;
  final bool isOwnerMode; // <--- Controlled by parent widget

  const IssueListPage({
    super.key, 
    required this.propertyId,
    required this.isOwnerMode, 
  });

  @override
  State<IssueListPage> createState() => _IssueListPageState();
}

class _IssueListPageState extends State<IssueListPage> {
  List<ReportedIssue> _issues = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadIssues();
  }

  Future<void> _loadIssues() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      List<ReportedIssue> fetchedIssues;

      // Use widget variable instead of role check
      if (widget.isOwnerMode) {
        fetchedIssues = await IssueService.getIssues(propertyId: widget.propertyId);
      } else {
        fetchedIssues = await IssueService.getTenantIssues(propertyId: widget.propertyId);
      }

      if (mounted) {
        setState(() {
          _issues = fetchedIssues;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isOwnerMode ? "Reported Issues" : "My Reports"),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty) {
      return Center(child: Text("Error: $_errorMessage"));
    }

    if (_issues.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_turned_in_outlined, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text("No issues found.", style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: _issues.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final issue = _issues[index];
        return _buildIssueCard(issue);
      },
    );
  }

  Widget _buildIssueCard(ReportedIssue issue) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: issue.thumbnail != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  ApiService.buildFileUrl(issue.thumbnail!),
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (c, o, s) => Container(
                    width: 60, 
                    height: 60, 
                    color: Colors.grey[300], 
                    child: const Icon(Icons.broken_image),
                  ),
                ),
              )
            : Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.report_problem, color: Colors.grey),
              ),
        title: Text(
          issue.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
          maxLines: 1, 
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                _buildStatusChip(issue.status),
                const SizedBox(width: 8),
                Text(
                  DateFormat('MMM dd, yyyy').format(issue.reportedAt),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () async {
          // Pass the same mode to the detail page
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => IssueDetailPage(
                issueId: issue.id,
                isOwnerMode: widget.isOwnerMode, 
              ),
            ),
          );
          _loadIssues();
        },
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color = AppTheme.getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold),
      ),
    );
  }
}