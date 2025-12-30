import 'package:flutter_application/models/tenant_record.dart';

class Lease {
  int id;
  DateTime startDate;
  DateTime? endDate;
  DateTime? terminationDate;
  double monthlyRent;
  double? depositAmount;
  int gracePeriodDays;
  String status;
  List<TenantRecord> tenantRecords;
  String? contractUrl;
  String? contractName;
  int tenantId;
  String? tenantName;
  String? tenantProfile;
  
  Lease({
    required this.id,
    required this.startDate,
    this.endDate,
    this.terminationDate,
    required this.monthlyRent,
    this.depositAmount,
    this.gracePeriodDays = 3,
    this.status = "pending",
    this.tenantRecords = const [],
    this.contractUrl,
    this.contractName,
    required this.tenantId,
    this.tenantName,
    this.tenantProfile,
  });

  factory Lease.fromJson(Map<String, dynamic> json) {
    return Lease(
      id: json['id'],
      startDate: DateTime.parse(json['start_date']),
      endDate: json['end_date'] != null ? DateTime.parse(json['end_date']) : null,
      terminationDate: json['termination_date'] != null ? DateTime.parse(json['termination_date']) : null,
      monthlyRent: (json['monthly_rent'] as num).toDouble(),
      depositAmount: json['deposit_amount'] != null ? (json['deposit_amount'] as num).toDouble() : null,
      gracePeriodDays: json['gracePeriodDays'] ?? 3,
      status: json['status'] ?? "pending",
      tenantRecords: (json['tenant_records'] as List<dynamic>?)?.map((e) => TenantRecord.fromJson(e)).toList() ?? [],
      contractUrl: json['contract_url'],
      contractName: json['contract_name'],
      tenantId: json['tenant_id'],
      tenantName: json['tenant_name'], 
      tenantProfile: json['tenant_profile_pic_url'], 
    );
  }
}