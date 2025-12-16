import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_application/models/lease.dart';
import 'package:flutter_application/models/tenant_record.dart';
import 'package:flutter_application/services/api_service.dart';
import 'package:flutter_application/services/property_service.dart';
import 'package:flutter_application/theme.dart';

class TenantRecordPage extends StatefulWidget {
  final Lease lease;

  const TenantRecordPage({super.key, required this.lease});

  @override
  State<TenantRecordPage> createState() => _TenantRecordPageState();
}

class _TenantRecordPageState extends State<TenantRecordPage> {
  bool _isLoading = true;
  List<TenantRecord> _records = [];

  @override
  void initState() {
    super.initState();
    _fetchRecords();
  }

  Future<void> _fetchRecords() async {
    setState(() => _isLoading = true);
    try {
      final records = await PropertyService.getTenantRecords(leaseId: widget.lease.id);
      
      if (mounted) {
        setState(() {
          records.sort((a, b) => b.startDate.compareTo(a.startDate));
          _records = records;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching tenant records: $e");
      if (mounted) {
        setState(() {
          _records = [];
          _isLoading = false;
        });
      }
    }
  }

Map<String, dynamic> _getStatusStyle(TenantRecord record) {
    // Directly use the status from the backend
    switch (record.status.toLowerCase()) {
      case 'paid':
        return {
          'text': 'PAID',
          'color': Colors.green,
          'bg': Colors.green.withOpacity(0.1),
          'icon': Icons.check_circle
        };
      case 'overdue':
        return {
          'text': 'OVERDUE',
          'color': Colors.red,
          'bg': Colors.red.withOpacity(0.1),
          'icon': Icons.warning_rounded
        };
      case 'unpaid':
      default:
        return {
          'text': 'UNPAID',
          'color': Colors.orange,
          'bg': Colors.orange.withOpacity(0.1),
          'icon': Icons.access_time_filled
        };
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return "-";
    return DateFormat('dd MMM yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Lease & Records"),
        centerTitle: true,
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            _buildLeaseHeader(widget.lease),
            
            const SizedBox(height: 24),

            Text(
              "Payment History",
              style: TextStyle(
                fontSize: 18, 
                fontWeight: FontWeight.bold, 
                color: Colors.grey[800]
              ),
            ),
            const SizedBox(height: 12),

            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _records.isEmpty
                    ? _buildEmptyState()
                    : ListView.separated(
                        shrinkWrap: true, 
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _records.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          return _buildRecordCard(_records[index]);
                        },
                      ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaseHeader(Lease lease) {
    final statusColor = AppTheme.getStatusColor(lease.status);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Tenant Row
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey[200],
                  image: (lease.tenantProfile != null && lease.tenantProfile!.isNotEmpty)
                      ? DecorationImage(
                          image: NetworkImage(ApiService.buildImageUrl(lease.tenantProfile!)),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: (lease.tenantProfile == null || lease.tenantProfile!.isEmpty)
                    ? const Icon(Icons.person, color: Colors.grey)
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lease.tenantName ?? "Unknown Tenant",
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Tenant",
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  lease.status.toUpperCase(),
                  style: TextStyle(
                    color: statusColor, 
                    fontWeight: FontWeight.bold, 
                    fontSize: 11
                  ),
                ),
              )
            ],
          ),
          
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),

          // Details Grid
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _headerInfoItem(Icons.calendar_today, "Start Date", _formatDate(lease.startDate)),
              _headerInfoItem(Icons.event, "End Date", _formatDate(lease.endDate)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
               _headerInfoItem(Icons.monetization_on, "Monthly Rent", "RM ${lease.monthlyRent.toStringAsFixed(0)}"),
               _headerInfoItem(Icons.security, "Deposit", lease.depositAmount != null ? "RM ${lease.depositAmount!.toStringAsFixed(0)}" : "-"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerInfoItem(IconData icon, String label, String value) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[400]),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
              Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.receipt_long_rounded, size: 50, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text(
            "No records yet.",
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordCard(TenantRecord record) {
    final statusStyle = _getStatusStyle(record);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  record.month,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusStyle['bg'],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Icon(statusStyle['icon'], size: 12, color: statusStyle['color']),
                      const SizedBox(width: 4),
                      Text(
                        statusStyle['text'],
                        style: TextStyle(
                          color: statusStyle['color'],
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Due: ${_formatDate(record.dueDate)}",
                  style: TextStyle(
                    fontSize: 13, 
                    color: (statusStyle['text'] == 'OVERDUE') ? Colors.red : Colors.grey[600]
                  ),
                ),
                if (record.paidAt != null)
                  Text(
                    "Paid: ${_formatDate(record.paidAt)}",
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
              ],
            ),
            
            if (record.amountPaid > 0) ...[
              const SizedBox(height: 8),
              const Divider(),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Amount Paid", style: TextStyle(fontSize: 13, color: Colors.grey)),
                  Text(
                    "RM ${record.amountPaid.toStringAsFixed(2)}",
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                  ),
                ],
              )
            ]
          ],
        ),
      ),
    );
  }
}