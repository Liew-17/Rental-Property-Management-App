import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter_application/models/request.dart';
import 'package:flutter_application/models/user.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application/models/residence.dart';
import 'package:flutter_application/services/api_service.dart';
import 'package:image_picker/image_picker.dart';

class RentService{

  static Future<Request?> getRentRequest(int requestId) async {
    try {
      // Build the URI for /rent/request/<request_id>
      final uri = ApiService.buildUri("/rent/request/$requestId");

      // Send GET request
      final response = await http.get(uri);

      // Decode response
      final responseBody = json.decode(response.body);

      if (response.statusCode == 200 && responseBody['success'] == true) {
        // Convert JSON to Request object
        return Request.fromJson(responseBody['request']);
      } else {
        debugPrint(
          "Failed to fetch request: ${response.statusCode} -> ${responseBody['message'] ?? responseBody}"
        );
        return null;
      }
    } catch (e) {
      debugPrint("Exception during fetch: $e");
      return null;
    }
  }



  static Future<bool> sendRentRequest({
    required int userId,
    required int propertyId,
    required DateTime startDate,
    required int duration,
    required List<XFile> files,       
  }) async {
    try {
      final uri = ApiService.buildUri("/rent/request"); 

      var request = http.MultipartRequest('POST', uri);

      request.fields['user_id'] = userId.toString();
      request.fields['property_id'] = propertyId.toString();
      request.fields['start_date'] = startDate.toIso8601String();
      request.fields['duration_months'] = duration.toString();

      for (var file in files) {
        final bytes = await file.readAsBytes(); 
        request.files.add(
          http.MultipartFile.fromBytes(
            'files[]',
            bytes,
            filename: file.name,
          ),
        );
      }

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint("Rent request uploaded successfully: $responseBody");
        return true;
      } else {
        debugPrint("Upload failed: ${response.statusCode} -> $responseBody");
        return false;
      }
    } catch (e) {
      debugPrint("Exception during upload: $e");
      return false;
    }
  }





  

}