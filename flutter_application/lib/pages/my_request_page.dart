import 'package:flutter/material.dart';
import 'package:flutter_application/models/request.dart';
import 'package:flutter_application/models/user.dart';
import 'package:flutter_application/pages/request_page.dart';
import 'package:flutter_application/services/api_service.dart';
import 'package:flutter_application/services/user_service.dart';
import 'package:flutter_application/theme.dart';

class MyRequestPage extends StatefulWidget {
  const MyRequestPage({super.key});

  @override
  State<MyRequestPage> createState() => _MyRequestPageState();
}

class _MyRequestPageState extends State<MyRequestPage> {
  List<Request> activeRequests = [];
  List<Request> historicalRequests = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() {
      isLoading = true;
    });

    try {
      final userId = AppUser().id ?? 0;
      final allRequests = await UserService.getUserRentRequests(userId);

      // Active: Pending or Renting (if you have that status)
      final active = allRequests.where((r) {
        return (r.status == "pending" || r.status == "renting") && r.currentStep >= 1;
      }).toList();

      // History: Rejected, Terminated, Completed
      final historical = allRequests.where((r) {
        return r.status == "rejected" ||
            r.status == "terminated" ||
            r.status == "completed";
      }).toList();

      if (mounted) {
        setState(() {
          activeRequests = active;
          historicalRequests = historical;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
      debugPrint("Error loading requests: $e");
    }
  }

  Widget _buildRequestCard(Request req) {
    final statusColor = AppTheme.getStatusColor(req.status);
    final prop = req.property; // Access the embedded property info

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      color: Colors.white,
      surfaceTintColor: Colors.white,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RequestPage(requestId: req.id),
            ),
          ).then((_) {
            _loadRequests();
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Property Image ---
              Container(
                width: 80, 
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey[200],
                  image: (prop?.thumbnailUrl != null)
                      ? DecorationImage(
                          image: NetworkImage(ApiService.buildImageUrl(prop!.thumbnailUrl!)),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: prop?.thumbnailUrl == null 
                    ? const Icon(Icons.home, color: Colors.grey, size: 30) 
                    : null,
              ),
              
              const SizedBox(width: 14),

              // --- Info Column ---
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Top Row: Name + Status Badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Property Name
                        Expanded(
                          child: Text(
                            prop?.name ?? "Unknown Property",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Status Chip
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            req.status.toUpperCase(),
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // Location
                    if (prop?.fullLocation != null)
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              prop!.fullLocation,
                              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    
                    const SizedBox(height: 8),
                    
                    // Date & Duration (Plain text style)
                    Text(
                      "${_formatDate(req.startDate)} • ${_calculateDuration(req.startDate, req.endDate)}",
                      style: TextStyle(
                        fontSize: 12, 
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _calculateDuration(DateTime start, DateTime end) {
    final diff = end.difference(start).inDays;
    final months = (diff / 30).round();
    return "$months Months";
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(color: Colors.grey[500], fontSize: 16),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text("My Rent Requests"),
          centerTitle: true,
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: "Active"),
              Tab(text: "History"),
            ],
          ),
        ),
        body: isLoading
            ? Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
            : TabBarView(
                children: [
                  activeRequests.isEmpty
                      ? _buildEmptyState("No active requests", Icons.pending_actions)
                      : ListView.builder(
                          padding: const EdgeInsets.only(top: 12, bottom: 20),
                          itemCount: activeRequests.length,
                          itemBuilder: (context, index) =>
                              _buildRequestCard(activeRequests[index]),
                        ),
                  historicalRequests.isEmpty
                      ? _buildEmptyState("No history found", Icons.history)
                      : ListView.builder(
                          padding: const EdgeInsets.only(top: 12, bottom: 20),
                          itemCount: historicalRequests.length,
                          itemBuilder: (context, index) =>
                              _buildRequestCard(historicalRequests[index]),
                        ),
                ],
              ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }
}
