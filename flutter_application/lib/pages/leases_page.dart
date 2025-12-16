import 'package:flutter/material.dart';
import 'package:flutter_application/custom_widgets/file_preview_page.dart';
import 'package:flutter_application/pages/chat_page.dart';
import 'package:flutter_application/pages/chat_record_page.dart';
import 'package:flutter_application/pages/tenant_record_page.dart';
import 'package:intl/intl.dart';
import 'package:flutter_application/models/lease.dart';
import 'package:flutter_application/models/tenant_record.dart';
import 'package:flutter_application/services/api_service.dart'; // Import for profile image
import 'package:flutter_application/services/property_service.dart';
import 'package:flutter_application/theme.dart';

class LeasePage extends StatefulWidget {
  final int propertyId;

  const LeasePage({super.key, required this.propertyId});

  @override
  State<LeasePage> createState() => _LeasePageState();
}

class _LeasePageState extends State<LeasePage> {
  bool _isLoading = true;
  bool _isAscending = false;

  Lease? _activeLease;
  List<Lease> _pastLeases = [];
  
  TenantRecord? _activeLeaseLatestRecord;
  bool _loadingActiveRecord = false;

  @override
  void initState() {
    super.initState();
    _fetchLeaseData();
  }

  Future<void> _fetchLeaseData() async {
    setState(() => _isLoading = true);
    try {
      final leases = await PropertyService.getAllLeases(widget.propertyId);

      final active = leases.where((l) => 
          l.status.toLowerCase() == 'active'
      ).toList();
      
      final past = leases.where((l) => 
          l.status.toLowerCase() != 'active' && 
          l.status.toLowerCase() != 'terminated' && 
          l.status.toLowerCase() != 'pending'
      ).toList();

      if (mounted) {
        setState(() {
          _activeLease = active.isNotEmpty ? active.last : null; 
          _pastLeases = past;
          _sortPastLeases(); 
        });
      }

      if (_activeLease != null) {
        _fetchActiveRecordStatus(_activeLease!.id);
      }

    } catch (e) {
      debugPrint("Error in LeasePage: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchActiveRecordStatus(int leaseId) async {
    setState(() => _loadingActiveRecord = true);
    try {
      final records = await PropertyService.getTenantRecords(leaseId: leaseId);
      if (records.isNotEmpty) {
        records.sort((a, b) => b.startDate.compareTo(a.startDate));
        if (mounted) {
          setState(() {
            _activeLeaseLatestRecord = records.first;
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching active lease records: $e");
    } finally {
      if (mounted) setState(() => _loadingActiveRecord = false);
    }
  }

  void _sortPastLeases() {
    setState(() {
      _pastLeases.sort((a, b) {
        final dateA = a.startDate;
        final dateB = b.startDate;
        return _isAscending ? dateA.compareTo(dateB) : dateB.compareTo(dateA);
      });
    });
  }

  void _toggleSort() {
    setState(() {
      _isAscending = !_isAscending;
      _sortPastLeases();
    });
  }

  void _onViewContract(String fileUrl, String fileName) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FilePreviewPage(
          fileUrl: fileUrl,
          fileName: fileName,
        ),
      ),
    );
  }

  void _onViewRecords(Lease lease) {
        Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TenantRecordPage(
          lease:lease
        ),
      ),
    );

  }

  void _onChatActive(Lease lease) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatPage(
          propertyId: widget.propertyId,
          tenantId: lease.tenantId,
        ),
      ),
    );
  }

  // ADD THIS: Navigate to read-only history for past lease
  void _onChatHistory(Lease lease) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatRecordPage(
          leaseId: lease.id,
        ),
      ),
    );
  }

  // --- Status Style Helper ---
  Map<String, dynamic> _getStatusStyle(TenantRecord record) {
    switch (record.status.toLowerCase()) {
      case 'paid':
        return {
          'text': 'PAID',
          'color': Colors.green,
          'bg': Colors.green.withOpacity(0.1),
          'icon': Icons.check_circle_rounded
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Lease Management"),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchLeaseData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // === Section 1: Active Lease ===
                    const Text(
                      "Current Active Lease",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    _activeLease != null
                        ? _buildActiveLeaseCard(_activeLease!)
                        : _buildEmptyState("No active lease currently."),

                    const SizedBox(height: 30),

                    // === Section 2: Past Leases ===
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Lease History",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        if (_pastLeases.isNotEmpty)
                          TextButton.icon(
                            onPressed: _toggleSort,
                            icon: Icon(
                              _isAscending ? Icons.arrow_upward : Icons.arrow_downward, 
                              size: 16
                            ),
                            label: Text(_isAscending ? "Oldest First" : "Newest First"),
                            style: TextButton.styleFrom(foregroundColor: AppTheme.primaryColor),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    
                    if (_pastLeases.isEmpty)
                      _buildEmptyState("No lease history found.")
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _pastLeases.length,
                        separatorBuilder: (ctx, i) => const SizedBox(height: 12),
                        itemBuilder: (ctx, i) => _buildPastLeaseCard(_pastLeases[i]),
                      ),
                      
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildEmptyState(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Center(
        child: Text(text, style: TextStyle(color: Colors.grey[600])),
      ),
    );
  }

Widget _buildActiveLeaseCard(Lease lease) {
    // --- Data Preparation (Unchanged) ---
    String statusText = "No records";
    Color statusColor = Colors.grey;
    IconData statusIcon = Icons.info_outline;
    String monthText = "";
    
    String dateLabel1 = "Lease Start";
    String dateValue1 = _formatDate(lease.startDate);
    String dateLabel2 = "Lease End";
    String dateValue2 = _formatDate(lease.endDate);

    if (!_loadingActiveRecord && _activeLeaseLatestRecord != null) {
      final style = _getStatusStyle(_activeLeaseLatestRecord!);
      statusText = style['text'];
      statusColor = style['color'];
      statusIcon = style['icon'];
      monthText = _activeLeaseLatestRecord!.month;

      dateLabel1 = "Bill Date"; 
      dateValue1 = _formatDate(_activeLeaseLatestRecord!.startDate);
      dateLabel2 = "Due Date";
      dateValue2 = _formatDate(_activeLeaseLatestRecord!.dueDate);
    }

    return Card(
      elevation: 3,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // --- 1. Header: Tenant Info & Chat Button ---
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: (lease.tenantProfile != null && lease.tenantProfile!.isNotEmpty)
                      ? NetworkImage(ApiService.buildImageUrl(lease.tenantProfile!))
                      : null,
                  child: (lease.tenantProfile == null || lease.tenantProfile!.isEmpty)
                      ? const Icon(Icons.person, color: Colors.grey)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lease.tenantName ?? "Unknown Tenant",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const Text("Tenant", style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                // Chat Button: Primary Color with shadow
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      )
                    ]
                  ),
                  child: IconButton(
                    onPressed: () => _onChatActive(lease),
                    icon: const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 20),
                    constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                    padding: EdgeInsets.zero,
                    tooltip: "Message Tenant",
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // --- 2. Dashboard Section: Rent & Status (Redesigned) ---
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Left: Rent Amount
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "MONTHLY RENT",
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "RM ${lease.monthlyRent.toStringAsFixed(0)}",
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  
                  // Divider
                  Container(
                    height: 32,
                    width: 1,
                    color: Colors.grey.shade300,
                  ),

                  // Right: Status & Month
                  if (_loadingActiveRecord)
                     const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                             Icon(statusIcon, size: 16, color: statusColor),
                             const SizedBox(width: 6),
                             Text(
                               statusText,
                               style: TextStyle(
                                 color: statusColor,
                                 fontWeight: FontWeight.bold,
                                 fontSize: 16,
                               ),
                             ),
                          ],
                        ),
                        if (monthText.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            monthText,
                            style: TextStyle(
                              color: Colors.grey[400], 
                              fontSize: 11, 
                              fontWeight: FontWeight.w600
                            ),
                          ),
                        ]
                      ],
                    ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // --- 3. Dates (Unchanged) ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _infoColumn(dateLabel1, dateValue1),
                _infoColumn(dateLabel2, dateValue2),
                _infoColumn("Grace Period", "${lease.gracePeriodDays} Days"),
              ],
            ),
            const SizedBox(height: 24),
            
            // --- 4. Bottom Actions (Contract & Records) ---
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _onViewContract(lease.contractUrl??"", lease.contractName??""),
                    icon: const Icon(Icons.description_outlined),
                    label: const Text("Contract"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _onViewRecords(lease),
                    style: AppTheme.primaryButton,
                    icon: const Icon(Icons.receipt_long),
                    label: const Text("Records"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPastLeaseCard(Lease lease) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      color: Colors.white,
      surfaceTintColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                // Tenant Info (Small)
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: (lease.tenantProfile != null && lease.tenantProfile!.isNotEmpty)
                      ? NetworkImage(ApiService.buildImageUrl(lease.tenantProfile!))
                      : null,
                  child: (lease.tenantProfile == null || lease.tenantProfile!.isEmpty)
                      ? const Icon(Icons.person, color: Colors.grey, size: 20)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lease.tenantName ?? "Unknown Tenant",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      Text(
                        "${_formatDate(lease.startDate)} - ${_formatDate(lease.endDate)}",
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                // Status Badge
                 Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.getStatusColor(lease.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      lease.status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10, 
                        color: AppTheme.getStatusColor(lease.status),
                        fontWeight: FontWeight.bold
                      ),
                    ),
                  ),
              ],
            ),
            
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),

            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _onChatHistory(lease),
                  icon: const Icon(Icons.chat, size: 16, color: Colors.grey),
                  label: Text("Chat Log", style: TextStyle(color: Colors.grey[700])),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _onViewContract(lease.contractUrl??"", lease.contractName??""),
                  icon: const Icon(Icons.description_outlined, size: 16, color: Colors.grey),
                  label: Text("Contract", style: TextStyle(color: Colors.grey[700])),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _onViewRecords(lease),
                  icon: const Icon(Icons.history, size: 16, color: AppTheme.primaryColor),
                  label: const Text("Records", style: TextStyle(color: AppTheme.primaryColor)),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _infoColumn(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      ],
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return "Ongoing";
    return DateFormat('dd MMM yyyy').format(date);
  }
}

