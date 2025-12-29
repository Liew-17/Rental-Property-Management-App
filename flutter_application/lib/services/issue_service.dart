import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_application/models/reported_issue.dart';
import 'package:flutter_application/models/user.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'api_service.dart';

class IssueService {
  
  static Future<List<ReportedIssue>> getIssues({required int propertyId}) async {
    try {

      final uri = ApiService.buildUri('/issue/list').replace(queryParameters: {
        'property_id': propertyId.toString(),
      });

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        if (body['success'] == true) {
          final List<dynamic> data = body['issues'];
          return data.map((e) => ReportedIssue.fromJson(e)).toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint("Error fetching issues: $e");
      return [];
    }
  }

    static Future<List<ReportedIssue>> getTenantIssues({required int propertyId}) async {
    try {
      int tenantId = AppUser().id!;

      final uri = ApiService.buildUri('/issue/list').replace(queryParameters: {
        'property_id': propertyId.toString(),
        'tenant_id': tenantId.toString(),
      });

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        if (body['success'] == true) {
          final List<dynamic> data = body['issues'];
          return data.map((e) => ReportedIssue.fromJson(e)).toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint("Error fetching issues: $e");
      return [];
    }
  }

  static Future<ReportedIssue?> getIssueDetail(int issueId) async {
    try {
      final uri = ApiService.buildUri('/issue/$issueId');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        if (body['success'] == true) {
          return ReportedIssue.fromJson(body['data']);
        }
      }
    } catch (e) {
      debugPrint("Error fetching issue detail: $e");
    }
    return null;
  }

  static Future<bool> createIssue({
    required int propertyId,
    required int tenantId,
    required String title,
    required String description,
    String priority = 'medium',
    List<XFile>? images,
  }) async {
    try {
      final uri = ApiService.buildUri('/issue/create');
      
      var request = http.MultipartRequest('POST', uri);
      
      request.fields['property_id'] = propertyId.toString();
      request.fields['tenant_id'] = tenantId.toString();
      request.fields['title'] = title;
      request.fields['description'] = description;
      request.fields['priority'] = priority;

      if (images != null) {
        for (var img in images) {
          final bytes = await img.readAsBytes(); 
          request.files.add(
            http.MultipartFile.fromBytes(
              'images',
              bytes,
              filename: img.name,
            ),
          );
        }
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      }
      else 
      {
        debugPrint(jsonDecode(response.body).toString()); 
        return false;
      }

    } catch (e) {
      debugPrint("Error creating issue: $e");
      return false;
    }
  }

  static Future<bool> resolveIssue(int issueId, String notes) async {
    try {
      final uri = ApiService.buildUri('/issue/resolve');
      final response = await http.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "issue_id": issueId,
          "resolution_notes": notes,
        }),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return body['success'] == true;
      }
      return false;
    } catch (e) {
      debugPrint("Error resolving issue: $e");
      return false;
    }
  }

  static Future<bool> updateStatus(int issueId, String status) async {
  try {
    final uri = ApiService.buildUri('/issue/update_status');
    final response = await http.post(
      uri,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "issue_id": issueId,
        "status": status,
      }),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['success'] == true;
    }
    return false;
  } catch (e) {
    debugPrint("Error updating status: $e");
    return false;
  }
}
}