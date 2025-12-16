class TenantRecord {
  int id;
  String month;
  DateTime startDate;
  DateTime dueDate;
  DateTime? paidAt;
  double amountPaid;
  String status;

  TenantRecord({
    required this.id,
    required this.month,
    required this.startDate,
    required this.dueDate,
    this.paidAt,
    this.amountPaid = 0.0,
    this.status = "unpaid",
  });

  factory TenantRecord.fromJson(Map<String, dynamic> json) {
    return TenantRecord(
      id: json['id'],
      month: json['month'],
      startDate: DateTime.parse(json['start_date']),
      dueDate: DateTime.parse(json['due_date']),
      paidAt: json['paid_at'] != null ? DateTime.parse(json['paid_at']) : null,
      amountPaid: json['amount_paid'] != null ? (json['amount_paid'] as num).toDouble() : 0.0,
      status: json['status'] ?? "unpaid",
    );
  }
}