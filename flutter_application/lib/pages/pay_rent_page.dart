
import 'package:flutter/material.dart';
import 'package:flutter_application/pages/tenant_record_page.dart'; // Import for View Records
import 'package:flutter_application/services/rent_service.dart';
import 'package:intl/intl.dart';
import 'package:flutter_application/models/lease.dart';
import 'package:flutter_application/models/tenant_record.dart';
import 'package:flutter_application/services/property_service.dart';
import 'package:flutter_application/theme.dart';

class PayRentPage extends StatefulWidget {
  final int propertyId;

  const PayRentPage({super.key, required this.propertyId});

  @override
  State<PayRentPage> createState() => _PayRentPageState();
}

class _PayRentPageState extends State<PayRentPage> {
  bool _isLoading = true;
  bool _isProcessingPayment = false;
  
  Lease? _lease;
  TenantRecord? _currentDueRecord; 

  @override
  void initState() {
    super.initState();
    _loadPaymentData();
  }

  Future<void> _loadPaymentData() async {
    setState(() => _isLoading = true);
    try {
      // 1. Fetch Active Lease
      final lease = await PropertyService.getActiveLeaseForTenant(widget.propertyId);

      TenantRecord? targetRecord;

      if (lease != null && lease.tenantRecords.isNotEmpty) {
        // 2a. First, try to find Unpaid/Overdue records
        final unpaidRecords = lease.tenantRecords.where((r) {
          final status = r.status.toLowerCase();
          return status != 'paid'; 
        }).toList();

        if (unpaidRecords.isNotEmpty) {
          // If there are unpaid bills, show the oldest one first
          unpaidRecords.sort((a, b) => a.startDate.compareTo(b.startDate));
          targetRecord = unpaidRecords.first;
        } else {
          // 2b. If ALL are paid, find the LATEST paid record to display
          final paidRecords = lease.tenantRecords.where((r) {
            return r.status.toLowerCase() == 'paid';
          }).toList();

          if (paidRecords.isNotEmpty) {
            // Sort by Start Date DESCENDING (Newest first)
            paidRecords.sort((a, b) => b.startDate.compareTo(a.startDate));
            targetRecord = paidRecords.first;
          }
        }
      }

      if (mounted) {
        setState(() {
          _lease = lease;
          _currentDueRecord = targetRecord;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading payment data: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

Future<void> _handlePayment() async {
    // Ensure we have a valid record and lease before proceeding
    if (_currentDueRecord == null || _lease == null) return;

    setState(() => _isProcessingPayment = true);

    try {
      // Call the RentService to process the payment
      final success = await RentService.payRent(
        tenantRecordId: _currentDueRecord!.id,
        totalAmount: _lease!.monthlyRent,
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Payment for ${_currentDueRecord!.month} successful!"),
              backgroundColor: Colors.green,
            ),
          );
          
          // REFRESH DATA: Reload the lease and records to update the UI
          await _loadPaymentData(); 
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Payment failed. Please try again."),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text("Payment error: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessingPayment = false);
    }
  }

  void _onViewRecords() {
    if (_lease != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TenantRecordPage(lease: _lease!),
        ),
      );
    }
  }

  // Reuse logic from LeasePage for consistency
  Map<String, dynamic> _getStatusStyle(TenantRecord record) {
    switch (record.status.toLowerCase()) {
      case 'paid':
        return {
          'text': 'PAID',
          'color': Colors.green,
          'icon': Icons.check_circle_rounded
        };
      case 'overdue':
        return {
          'text': 'OVERDUE',
          'color': Colors.red,
          'icon': Icons.warning_rounded
        };
      case 'unpaid':
      default:
        return {
          'text': 'UNPAID',
          'color': Colors.orange,
          'icon': Icons.access_time_filled
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Make a Payment"),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _lease == null
              ? _buildErrorState("No active lease found.")
              : _currentDueRecord == null
                  ? _buildAllCaughtUpState()
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Payment Details",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          _buildPaymentCard(_lease!, _currentDueRecord!),
                        ],
                      ),
                    ),
    );
  }

 Widget _buildPaymentCard(Lease lease, TenantRecord record) {
    final style = _getStatusStyle(record);
    final statusText = style['text'];
    final statusColor = style['color'];
    final statusIcon = style['icon'];
    final monthText = record.month;

    final String dateLabel1 = "Bill Date";
    final String dateValue1 = _formatDate(record.startDate);
    final String dateLabel2 = "Due Date";
    final String dateValue2 = _formatDate(record.dueDate);
    
    // Check if this record is already paid
    final bool isPaid = record.status.toLowerCase() == 'paid';

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      surfaceTintColor: Colors.white,
      child: Stack(
        children: [
          // --- Main Content ---
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
            child: Column(
              children: [
                
                Column(
                  children: [

                    Text(
                      isPaid ? "Last Payment for" : "Rent Payment for", // Contextual label
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                    const SizedBox(height: 4),

                    Text(
                      monthText, 
                      style: const TextStyle(
                        fontSize: 32, 
                        fontWeight: FontWeight.w900,
                        color: Colors.black87,
                        letterSpacing: 0.5
                      ),
                    ),
                    
                    const SizedBox(height: 18),
                    
                    Text(
                      "Total Amount",
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "RM ${lease.monthlyRent.toStringAsFixed(0)}",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 30),
                const Divider(),
                const SizedBox(height: 24),

                // Dates Info
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _infoColumn(dateLabel1, dateValue1),
                    _infoColumn(dateLabel2, dateValue2),
                    _infoColumn("Grace Period", "${lease.gracePeriodDays} Days"),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Actions
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _onViewRecords,
                        icon: const Icon(Icons.history),
                        label: const Text("Records"),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        // Disable button if Paid or Processing
                        onPressed: (isPaid || _isProcessingPayment) 
                            ? null 
                            : _handlePayment,
                        style: AppTheme.primaryButton.copyWith(
                          padding: WidgetStateProperty.all(const EdgeInsets.symmetric(vertical: 12)),
                          // Optional: Change look when disabled
                          backgroundColor: isPaid 
                              ? WidgetStateProperty.all(Colors.grey[300]) 
                              : null,
                        ),
                        icon: _isProcessingPayment 
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Icon(isPaid ? Icons.check : Icons.payment),
                        label: Text(
                          _isProcessingPayment 
                              ? "Processing..." 
                              : (isPaid ? "Paid" : "Pay Now")
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // --- Status Badge (Top Right) ---
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: statusColor.withOpacity(0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(statusIcon, size: 14, color: statusColor),
                  const SizedBox(width: 6),
                  Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor, 
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                      letterSpacing: 0.5
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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

  Widget _buildAllCaughtUpState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle_outline, size: 80, color: Colors.green),
          const SizedBox(height: 20),
          const Text(
            "All Caught Up!",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            "You have no pending payments.",
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String msg) {
    return Center(
      child: Text(msg, style: TextStyle(color: Colors.grey[600])),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return "-";
    return DateFormat('dd MMM yyyy').format(date);
  }
}