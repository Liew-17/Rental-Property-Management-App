import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter_application/services/api_service.dart';
import 'package:flutter_application/models/furniture.dart';

class FurnitureService {


  static Future<bool> createFurniture({
    required int propertyId,
    required String name,
    String status = "Good",
    double purchasePrice = 0.0,
    String? note,
    XFile? image,
  }) async {
    final uri = ApiService.buildUri("/furniture/create");

    try {
      var request = http.MultipartRequest('POST', uri);

      request.fields['property_id'] = propertyId.toString();
      request.fields['name'] = name;
      request.fields['status'] = status;
      request.fields['purchase_price'] = purchasePrice.toString();
      if (note != null) request.fields['note'] = note;

      if (image != null) {
        final bytes = await image.readAsBytes();
        request.files.add(
          http.MultipartFile.fromBytes(
            'image',
            bytes,
            filename: image.name,
          ),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final jsonData = jsonDecode(response.body);

      if (response.statusCode == 201 && jsonData['success'] == true) {
        return true;
      } else {
        debugPrint("Create furniture failed: ${jsonData['message']}");
        return false;
      }
    } catch (e) {
      debugPrint("Exception during create furniture: $e");
      return false;
    }
  }

  static Future<bool> updateFurniture({
    required int furnitureId,
    required Map<String, dynamic> fields, 
    XFile? image,
  }) async {
    final uri = ApiService.buildUri("/furniture/update");

    try {
      var request = http.MultipartRequest('POST', uri);

      request.fields['furniture_id'] = furnitureId.toString();

      fields.forEach((key, value) {
        if (value != null) {
          request.fields[key] = value.toString();
        }
      });

      if (image != null) {
        final bytes = await image.readAsBytes();
        request.files.add(
          http.MultipartFile.fromBytes(
            'image',
            bytes,
            filename: image.name,
          ),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final jsonData = jsonDecode(response.body);

      if (response.statusCode == 200 && jsonData['success'] == true) {
        return true;
      } else {
        debugPrint("Update furniture failed: ${jsonData['message']}");
        return false;
      }
    } catch (e) {
      debugPrint("Exception during update furniture: $e");
      return false;
    }
  }

  static Future<bool> deleteFurniture(int furnitureId) async {
    final uri = ApiService.buildUri("/furniture/delete");

    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'furniture_id': furnitureId}),
      );

      final jsonData = jsonDecode(response.body);

      if (response.statusCode == 200 && jsonData['success'] == true) {
        return true;
      } else {
        debugPrint("Delete furniture failed: ${jsonData['message']}");
        return false;
      }
    } catch (e) {
      debugPrint("Exception during delete furniture: $e");
      return false;
    }
  }

  static Future<List<Furniture>> getFurnitureByProperty(int propertyId) async {
    final uri = ApiService.buildUri("/furniture/list/$propertyId");

    try {
      final response = await http.get(uri);
      final jsonData = jsonDecode(response.body);
  

      if (response.statusCode == 200 && jsonData['success'] == true) {
          
        List<dynamic> list = jsonData['data'];
        return list.map((item) => Furniture.fromJson(item)).toList();
      } else {
        debugPrint("Get furniture list failed: ${jsonData['message']}");
        return [];
      }
    } catch (e) {
      debugPrint("Exception fetching furniture list: $e");
      return [];
    }
  }

  static Future<Furniture?> getFurnitureDetails(int furnitureId) async {
    final uri = ApiService.buildUri("/furniture/$furnitureId");

    try {
      final response = await http.get(uri);
      final jsonData = jsonDecode(response.body);

      if (response.statusCode == 200 && jsonData['success'] == true) {
        return Furniture.fromJson(jsonData['data']);
      } else {
        debugPrint("Get furniture details failed: ${jsonData['message']}");
        return null;
      }
    } catch (e) {
      debugPrint("Exception fetching furniture details: $e");
      return null;
    }
  }

  static Future<bool> addLog({
    required int furnitureId,
    required String logType, 
    required String description,
    required DateTime date,
    XFile? image,
  }) async {
    final uri = ApiService.buildUri("/furniture/log/add");

    try {
      var request = http.MultipartRequest('POST', uri);

      request.fields['furniture_id'] = furnitureId.toString();
      request.fields['log_type'] = logType;
      request.fields['description'] = description;
      request.fields['date'] = date.toIso8601String().split('T')[0]; 

      if (image != null) {
        final bytes = await image.readAsBytes();
        request.files.add(
          http.MultipartFile.fromBytes(
            'image',
            bytes,
            filename: image.name,
          ),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final jsonData = jsonDecode(response.body);

      if (response.statusCode == 201 && jsonData['success'] == true) {
        return true;
      } else {
        debugPrint("Add log failed: ${jsonData['message']}");
        return false;
      }
    } catch (e) {
      debugPrint("Exception during add log: $e");
      return false;
    }
  }

  static Future<bool> deleteLog(int logId) async {
    final uri = ApiService.buildUri("/furniture/log/delete");

    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'log_id': logId}),
      );

      final jsonData = jsonDecode(response.body);

      if (response.statusCode == 200 && jsonData['success'] == true) {
        return true;
      } else {
        debugPrint("Delete log failed: ${jsonData['message']}");
        return false;
      }
    } catch (e) {
      debugPrint("Exception during delete log: $e");
      return false;
    }
  }
}