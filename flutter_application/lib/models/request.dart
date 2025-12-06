class Request {
  final int id;
  final int propertyId;
  final int tenantId;
  final DateTime startDate;
  final DateTime endDate;
  final int currentStep;
  final String status;
  final List<RequestDocument> documents;

  Request({
    required this.id,
    required this.propertyId,
    required this.tenantId,
    required this.startDate,
    required this.endDate,
    required this.currentStep,
    required this.status,
    this.documents = const [],
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
      documents: (json['documents'] as List<dynamic>?)
              ?.map((e) => RequestDocument.fromJson(e))
              .toList() ??
          [],
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