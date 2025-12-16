class Request {
  final int id;
  final int propertyId;
  final int tenantId;
  final DateTime startDate;
  final DateTime endDate;
  final int currentStep;
  final String status;
  final DateTime? firstPaymentDue;
  final List<RequestDocument> documents;

  // --- NEW: Embedded Objects ---
  final RequestProperty? property;
  final RequestUser? owner;
  final RequestUser? tenant;

  Request({
    required this.id,
    required this.propertyId,
    required this.tenantId,
    required this.startDate,
    required this.endDate,
    required this.currentStep,
    required this.status,
    this.firstPaymentDue,
    this.documents = const [],
    this.property,
    this.owner,
    this.tenant,
  });

  factory Request.fromJson(Map<String, dynamic> json) {
    return Request(
      id: json['id'],
      propertyId: json['property_id'],
      tenantId: json['tenant_id'],
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date']),
      currentStep: json['current_step'],
      status: json['status'],
      firstPaymentDue: json['first_payment_due'] != null
          ? DateTime.parse(json['first_payment_due'])
          : null,
      documents: (json['documents'] as List<dynamic>?)
              ?.map((e) => RequestDocument.fromJson(e))
              .toList() ??
          [],
      
      // Map embedded objects if they exist in the response
      property: json['property'] != null 
          ? RequestProperty.fromJson(json['property']) 
          : null,
      owner: json['owner'] != null 
          ? RequestUser.fromJson(json['owner']) 
          : null,
      tenant: json['tenant'] != null 
          ? RequestUser.fromJson(json['tenant']) 
          : null,
    );
  }
}

class RequestDocument {
  final int id;
  final int stepNumber;
  final String docType;
  final String originalFilename;
  final String fileUrl;
  final String fileFormat;
  final String uploadedBy;

  RequestDocument({
    required this.id,
    required this.stepNumber,
    required this.docType,
    required this.originalFilename,
    required this.fileUrl,
    required this.fileFormat,
    required this.uploadedBy,
  });

  factory RequestDocument.fromJson(Map<String, dynamic> json) {
    return RequestDocument(
      id: json['id'],
      stepNumber: json['step_number'],
      docType: json['doc_type'],
      originalFilename: json['original_filename'],
      fileUrl: json['file_url'],
      fileFormat: json['file_format'],
      uploadedBy: json['uploaded_by'],
    );
  }
}

// --- Helper Classes for Embedded Data ---

class RequestProperty {
  final int id;
  final String name;
  final String address;
  final String? thumbnailUrl;
  final String? state;
  final String? city;
  final String? district;
  final double price;
  final double deposit;

  RequestProperty({
    required this.id,
    required this.name,
    required this.address,
    this.thumbnailUrl,
    this.state,
    this.city,
    this.district,
    required this.price,
    required this.deposit,
  });

  factory RequestProperty.fromJson(Map<String, dynamic> json) {
    return RequestProperty(
      id: json['id'],
      name: json['name'],
      // Construct a full address string if specific fields are missing, or use as is
      address: json['address'] ?? '',
      state: json['state'],
      city: json['city'],
      district: json['district'],
      thumbnailUrl: json['thumbnail_url'],
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      deposit: (json['deposit'] as num?)?.toDouble() ?? 0.0,
    );
  }
  
  // Helper to get formatted location string
  String get fullLocation {
    return [state, district, city, address]
        .where((s) => s != null && s.isNotEmpty)
        .join(", ");
  }
}

class RequestUser {
  final int id;
  final String name;
  final String? profileUrl;

  RequestUser({
    required this.id,
    required this.name,
    this.profileUrl,
  });

  factory RequestUser.fromJson(Map<String, dynamic> json) {
    return RequestUser(
      id: json['id'],
      name: json['name'] ?? 'Unknown User',
      profileUrl: json['profile_pic_url'],
    );
  }
}