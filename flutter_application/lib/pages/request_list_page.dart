import 'package:flutter/material.dart';
import 'package:flutter_application/models/request.dart';
import 'package:flutter_application/pages/request_page.dart';
import 'package:flutter_application/services/api_service.dart';
import 'package:flutter_application/services/rent_service.dart';
import 'package:flutter_application/theme.dart';

class RequestListPage extends StatefulWidget {
  final int propertyId;

  const RequestListPage({super.key, required this.propertyId});

  @override
  State<RequestListPage> createState() => _RequestListPageState();
}

class _RequestListPageState extends State<RequestListPage> {
  List<Request> _requests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    try {
      final requests = await RentService.getAllRentRequests(widget.propertyId);
      if (mounted) {
        setState(() {
          _requests = requests;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading requests: $e");
      if (mounted) {
        setState(() {
          _requests = [];
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Separate the requests based on status
    final pendingRequests = _requests.where((r) => r.status == 'pending').toList();
    final pastRequests = _requests.where((r) => r.status != 'pending').toList();

    return DefaultTabController(
      length: 2, // Number of tabs
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text(
            "Rent Requests",
            style: TextStyle(color: Colors.white),
          ),
          centerTitle: true,
          backgroundColor: AppTheme.primaryColor,
          elevation: 0,
          scrolledUnderElevation: 0,
          foregroundColor: Colors.white,
          // 2. Add TabBar
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            indicatorSize: TabBarIndicatorSize.tab,
            indicatorWeight: 3,
            tabs: [
              Tab(text: "Pending"),
              Tab(text: "History"),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  // Tab 1: Pending List
                  _buildRequestList(pendingRequests, "No pending requests."),
                  
                  // Tab 2: History List (All other statuses)
                  _buildRequestList(pastRequests, "No request history."),
                ],
              ),
      ),
    );
  }

  // 3. Reusable helper to build the list or empty state
  Widget _buildRequestList(List<Request> requests, String emptyMessage) {
    if (requests.isEmpty) {
      return _buildEmptyState(emptyMessage);
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final req = requests[index];
        return _buildRequestCard(req);
      },
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(color: Colors.grey[500], fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(Request request) {
    final tenant = request.tenant;
    final statusColor = AppTheme.getStatusColor(request.status);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      surfaceTintColor: Colors.white,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RequestPage(requestId: request.id),
            ),
          ).then((_) => _loadRequests()); // Refresh on return
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // --- Tenant Profile Image ---
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey[200],
                  image: (tenant?.profileUrl != null)
                      ? DecorationImage(
                          image: NetworkImage(
                              ApiService.buildImageUrl(tenant!.profileUrl!)),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: (tenant?.profileUrl == null)
                    ? const Icon(Icons.person, color: Colors.grey, size: 28)
                    : null,
              ),

              const SizedBox(width: 16),

              // --- Info Section ---
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tenant Name
                    Text(
                      tenant?.name ?? "Unknown Tenant",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Date / Duration info
                    Text(
                      "${_formatDate(request.startDate)} • ${_calculateMonths(request.startDate, request.endDate)} Months",
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
                      request.status.toUpperCase(),
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

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }

  int _calculateMonths(DateTime start, DateTime end) {
    final difference = end.difference(start).inDays;
    return (difference / 30).round();
  }
}