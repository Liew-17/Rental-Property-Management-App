import 'package:flutter/foundation.dart';

class ReportedIssue {
  final int id;
  final String title;
  final String status;
  final String priority;
  final DateTime reportedAt;

  final String? description;
  final int? propertyId;
  final String? propertyName;
  final int? tenantId;
  final String? tenantName;
  final String? tenantProfilePic;
  final DateTime? resolvedAt;
  final String? resolutionNotes;
  final List<String>? images; 
  final String? thumbnail;    // Single image for list view

  ReportedIssue({
    required this.id,
    required this.title,
    required this.status,
    required this.priority,
    required this.reportedAt,
    this.description,
    this.propertyId,
    this.propertyName,
    this.tenantId,
    this.tenantName,
    this.tenantProfilePic,
    this.resolvedAt,
    this.resolutionNotes,
    this.images,
    this.thumbnail,
  });

  factory ReportedIssue.fromJson(Map<String, dynamic> json) {
    return ReportedIssue(
      id: json['id'],
      title: json['title'],
      status: json['status'] ?? 'pending',
      priority: json['priority'] ?? 'medium',
      reportedAt: DateTime.parse(json['reported_at']),
      description: json['description'],
      propertyId: json['property_id'],
      propertyName: json['property_name'],
      tenantId: json['tenant_id'],
      tenantName: json['tenant_name'],
      tenantProfilePic: json['tenant_profile'],
      resolvedAt: json['resolved_at'] != null 
          ? DateTime.parse(json['resolved_at']) 
          : null,
      resolutionNotes: json['resolution_notes'],
      images: json['images'] != null 
          ? List<String>.from(json['images']) 
          : null,
      thumbnail: json['thumbnail'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "title": title,
      "status": status,
      "priority": priority,
      "reported_at": reportedAt.toIso8601String(),
      "description": description,
      "property_id": propertyId,
      "property_name": propertyName,
      "tenant_id": tenantId,
      "tenant_name": tenantName,
      "resolved_at": resolvedAt?.toIso8601String(),
      "resolution_notes": resolutionNotes,
      "images": images,
    };
  }
}