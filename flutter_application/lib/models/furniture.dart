
class Furniture {
  final int id;
  final int propertyId;
  final String name;
  final String status; // "Good", "Damaged", "Disposed"
  final double purchasePrice;
  final String? imageUrl;
  final String? note;
  final DateTime? addedDate;
  
  final List<FurnitureLog> logs; 

  Furniture({
    required this.id,
    required this.propertyId,
    required this.name,
    required this.status,
    this.purchasePrice = 0.0,
    this.imageUrl,
    this.note,
    this.addedDate,
    this.logs = const [],
  });

  factory Furniture.fromJson(Map<String, dynamic> json) {
    var logList = json['logs'] as List?;
    List<FurnitureLog> parsedLogs = logList != null
        ? logList.map((i) => FurnitureLog.fromJson(i)).toList()
        : [];

    return Furniture(
      id: json['id'],
      propertyId: json['property_id'],
      name: json['name'] ?? '',
      status: json['status'] ?? 'Good',
      purchasePrice: json['purchase_price'] != null 
          ? (json['purchase_price'] as num).toDouble() 
          : 0.0,
      imageUrl: json['image_url'],
      note: json['note'],
      addedDate: json['added_date'] != null 
          ? DateTime.parse(json['added_date']) 
          : null,
      logs: parsedLogs,
    );
  }

}

class FurnitureLog {
  final int id;
  final String logType; // "Maintenance", "Damage", "Repair", "Dispose"
  final String description;
  final DateTime date;
  final String? imageUrl;

  FurnitureLog({
    required this.id,
    required this.logType,
    required this.description,
    required this.date,
    this.imageUrl,
  });

  factory FurnitureLog.fromJson(Map<String, dynamic> json) {
    return FurnitureLog(
      id: json['id'],
      logType: json['log_type'] ?? 'Maintenance',
      description: json['description'] ?? '',
      date: json['date'] != null 
          ? DateTime.parse(json['date']) 
          : DateTime.now(),
      imageUrl: json['image_url'],
    );
  }

}