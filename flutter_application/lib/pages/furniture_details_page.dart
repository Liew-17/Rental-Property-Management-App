import 'package:flutter/material.dart';
import 'package:flutter_application/pages/add_furniture_log_page.dart';
import 'package:flutter_application/pages/edit_furniture_page.dart';
import 'package:intl/intl.dart';
import 'package:flutter_application/models/furniture.dart';
import 'package:flutter_application/services/api_service.dart';
import 'package:flutter_application/services/furniture_service.dart';
import 'package:flutter_application/theme.dart';


class FurnitureDetailPage extends StatefulWidget {
  final int furnitureId;

  const FurnitureDetailPage({super.key, required this.furnitureId});

  @override
  State<FurnitureDetailPage> createState() => _FurnitureDetailPageState();
}

class _FurnitureDetailPageState extends State<FurnitureDetailPage> {
  Furniture? _furniture;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final data = await FurnitureService.getFurnitureDetails(widget.furnitureId);

      if (data != null && data.logs.isNotEmpty) {
        data.logs.sort((a, b) => b.date.compareTo(a.date));
      }

      if (mounted) {
        setState(() {
          _furniture = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading details: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteLog(int logId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Log"),
        content: const Text("Are you sure you want to delete this record?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final success = await FurnitureService.deleteLog(logId);
    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Log deleted successfully")),
        );
        _loadData(); 
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to delete log")),
        );
      }
    }
  }

  void _showLogDetails(FurnitureLog log) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (log.imageUrl != null && log.imageUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: Image.network(
                  ApiService.buildImageUrl(log.imageUrl!),
                  height: 250,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(height: 50, color: Colors.grey[200]),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(_getLogIcon(log.logType), color: _getLogColor(log.logType), size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(log.logType,
                            style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: _getLogColor(log.logType))),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(DateFormat('MMMM dd, yyyy').format(log.date),
                      style: TextStyle(color: Colors.grey[500], fontSize: 14)),
                  const SizedBox(height: 20),
                  Text(log.description, style: const TextStyle(fontSize: 16, height: 1.5)),
                ],
              ),
            ),
             Padding(
              padding: const EdgeInsets.only(bottom: 16, right: 16),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context), 
                  child: const Text("Close", style: TextStyle(fontSize: 16))
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Good': return Colors.green;
      case 'Damaged': return Colors.red;
      case 'Repaired': return Colors.orange;
      case 'Disposed': return Colors.grey;
      default: return AppTheme.primaryColor;
    }
  }

  Color _getLogColor(String type) {
    switch (type) {
      case 'Damage': return Colors.red;
      case 'Repair': return Colors.green;
      case 'Dispose': return Colors.grey;
      case 'Maintenance': return AppTheme.primaryColor;
      default: return AppTheme.primaryColor;
    }
  }

  IconData _getLogIcon(String type) {
    switch (type) {
      case 'Damage': return Icons.warning_amber_rounded;
      case 'Repair': return Icons.build_circle_outlined;
      case 'Dispose': return Icons.delete_outline;
      case 'Maintenance': return Icons.cleaning_services_outlined;
      default: return Icons.notes;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_furniture == null) return const Scaffold(body: Center(child: Text("Furniture not found")));

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Furniture Details", style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // Only show edit button if data is loaded
          if (_furniture != null)
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.white),
              onPressed: () async {
                // Navigate to Edit Page
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditFurniturePage(furniture: _furniture!),
                  ),
                );
                
                // Refresh data if changes were saved
                if (result == true) {
                  _loadData();
                }
              },
            ),
        ],
      ),
      floatingActionButton: _furniture!.status == "Disposed" 
        ? null 
        : FloatingActionButton.extended(
            backgroundColor: AppTheme.primaryColor,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text("Add Log", style: TextStyle(color: Colors.white)),
            onPressed: () async {
               Navigator.push(
                context, 
                MaterialPageRoute(
                  builder: (_) => AddFurnitureLogPage(
                    furnitureId: widget.furnitureId,
                    currentStatus: _furniture!.status,
                  )
                )
               ).then(
                (_) => _loadData()
               );
            
        
             
            }, 
          ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image Section (Centered)
                  Center(
                    child: Container(
                      height: 200, // Fixed height for image area
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 20),
                      child: _furniture!.imageUrl != null && _furniture!.imageUrl!.isNotEmpty
                          ? Image.network(
                              ApiService.buildImageUrl(_furniture!.imageUrl!),
                              fit: BoxFit.contain, // Ensures image isn't cropped
                            )
                          : Icon(Icons.chair_outlined, size: 100, color: Colors.grey[200]),
                    ),
                  ),

                  // Name and Price Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          _furniture!.name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                            height: 1.2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        "\$${_furniture!.purchasePrice.toStringAsFixed(0)}",
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w300,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(_furniture!.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _getStatusColor(_furniture!.status).withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle, size: 8, color: _getStatusColor(_furniture!.status)),
                        const SizedBox(width: 8),
                        Text(
                          _furniture!.status.toUpperCase(),
                          style: TextStyle(
                            color: _getStatusColor(_furniture!.status),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Notes Section
                  if (_furniture!.note != null && _furniture!.note!.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "NOTES",
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _furniture!.note!,
                            style: TextStyle(color: Colors.grey[700], fontSize: 14, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

     
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  const Text(
                    "Activity History",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    "${_furniture!.logs.length} Records",
                    style: TextStyle(color: Colors.grey[500], fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

      
            if (_furniture!.logs.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 40),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.history_toggle_off, size: 48, color: Colors.grey[300]),
                      const SizedBox(height: 12),
                      Text("No activity yet", style: TextStyle(color: Colors.grey[400])),
                    ],
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _furniture!.logs.length,
                itemBuilder: (context, index) {
                  final log = _furniture!.logs[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _getLogColor(log.logType).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _getLogIcon(log.logType),
                          color: _getLogColor(log.logType),
                          size: 20,
                        ),
                      ),
                      title: Text(
                        log.logType,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          "${DateFormat('MMM dd').format(log.date)} • ${log.description}",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                      trailing: PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, color: Colors.grey),
                        onSelected: (value) {
                          if (value == 'view') _showLogDetails(log);
                          if (value == 'delete') _deleteLog(log.id);
                        },
                        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                          const PopupMenuItem<String>(
                            value: 'view',
                            child: Row(
                              children: [
                                Icon(Icons.visibility, size: 18),
                                SizedBox(width: 8),
                                Text('View Details'),
                              ],
                            ),
                          ),

                          const PopupMenuItem<String>(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, size: 18, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Delete', style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            const SizedBox(height: 100), // Space for FAB
          ],
        ),
      ),
    );
  }
}