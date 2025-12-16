class Channel {
  final int id;
  final String status;
  final String? type;

  final int? propertyId;
  final String? propertyTitle;
  final String? propertyName; 
  
  final int? ownerId;
  final String ownerName;
  final String? ownerProfile;

  final int? tenantId;
  final String tenantName;
  final String? tenantProfile;

  Channel({
    required this.id,
    required this.status,
    this.type,
    this.propertyId,
    this.propertyTitle,
    this.propertyName,
    this.ownerId,
    required this.ownerName,
    this.ownerProfile,
    this.tenantId,
    required this.tenantName,
    this.tenantProfile,
  });

  factory Channel.fromJson(Map<String, dynamic> json) {
    return Channel(
      id: json['id'],
      status: json['status'] ?? 'closed',
      type: json['type'] ?? 'query',
      propertyId: json['property_id'],
      propertyTitle: json['property_title'],
      propertyName: json['property_name'],
      ownerId: json['owner_id'],
      ownerName: json['owner_name'] ?? 'Unknown',
      ownerProfile: json['owner_profile'],
      tenantId: json['tenant_id'],
      tenantName: json['tenant_name'] ?? 'Unknown',
      tenantProfile: json['tenant_profile'],
    );
  }
  
  // Helper to get a display title for the chat header
  String get displayTitle {
    return propertyTitle?.isNotEmpty == true 
        ? propertyTitle! 
        : (propertyName ?? "Unknown Property");
  }
}