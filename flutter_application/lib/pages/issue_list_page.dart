import 'package:flutter/material.dart';
import 'package:flutter_application/models/reported_issue.dart';
import 'package:flutter_application/pages/issue_detail_page.dart';
import 'package:flutter_application/pages/report_issue_page.dart';
import 'package:flutter_application/services/api_service.dart';
import 'package:flutter_application/services/issue_service.dart';
import 'package:flutter_application/theme.dart';
import 'package:intl/intl.dart';

class IssueListPage extends StatefulWidget {
  final int propertyId;
  final bool isOwnerMode; 

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
 
    final activeIssues = _issues.where((i) => i.status != 'resolved' && i.status != 'cancelled').toList();
    final historyIssues = _issues.where((i) => i.status == 'resolved' || i.status == 'cancelled').toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: Text(widget.isOwnerMode ? "Reported Issues" : "My Reports"),
          centerTitle: true,
          backgroundColor: AppTheme.primaryColor,
          elevation: 0,
          scrolledUnderElevation: 0,
          foregroundColor: Colors.white,
    
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            indicatorSize: TabBarIndicatorSize.tab,
            indicatorWeight: 3,
            tabs: [
              Tab(text: "Active"),
              Tab(text: "History"),
            ],
          ),
        ),
        floatingActionButton: widget.isOwnerMode
            ? null
            : FloatingActionButton.extended(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ReportIssuePage(propertyId: widget.propertyId),
                    ),
                  ).then((_) => _loadIssues());
                },
                label: const Text("Report Issue"),
                icon: const Icon(Icons.add),
                foregroundColor: Colors.white,
                backgroundColor: AppTheme.primaryColor,
              ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage.isNotEmpty
                ? Center(child: Text("Error: $_errorMessage"))
                : TabBarView(
                    children: [
    
                      _buildIssueList(activeIssues, "No active issues."),
   
                      _buildIssueList(historyIssues, "No issue history."),
                    ],
                  ),
      ),
    );
  }

  Widget _buildIssueList(List<ReportedIssue> issues, String emptyMessage) {
    if (issues.isEmpty) {
      return _buildEmptyState(emptyMessage);
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      itemCount: issues.length,
      itemBuilder: (context, index) {
        final issue = issues[index];
        return _buildIssueCard(issue);
      },
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_turned_in_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(color: Colors.grey[500], fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildIssueCard(ReportedIssue issue) {
    final statusColor = AppTheme.getStatusColor(issue.status);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      surfaceTintColor: Colors.white,
      child: InkWell(
        onTap: () async {
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
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // --- Image Section (Matches RequestListPage profile pic size/style) ---
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  // Using rounded rect for issues as they are objects/scenes, not people
                  borderRadius: BorderRadius.circular(8), 
                  color: Colors.grey[200],
                ),
                clipBehavior: Clip.antiAlias,
                child: issue.thumbnail != null
                    ? Image.network(
                        ApiService.buildImageUrl(issue.thumbnail!),
                        fit: BoxFit.cover,
                        errorBuilder: (c, o, s) => const Icon(Icons.broken_image, size: 24, color: Colors.grey),
                      )
                    : const Icon(Icons.report_problem, color: Colors.grey, size: 28),
              ),

              const SizedBox(width: 16),

              // --- Info Section ---
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      issue.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Date
                    Text(
                      DateFormat('MMM dd, yyyy').format(issue.reportedAt),
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),

              // --- Status & Arrow ---
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      issue.status.toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}