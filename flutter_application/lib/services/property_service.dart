import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter_application/models/user.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application/models/residence.dart';
import 'package:flutter_application/services/api_service.dart';
import 'package:image_picker/image_picker.dart';


class PropertyService {

 static Future<bool> deleteGalleryImage({required int propertyId, required String imageUrl}) async {
    try {
      final uri = ApiService.buildUri("/property/gallery/delete");

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'property_id': propertyId,
          'image_url': imageUrl,
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        debugPrint('Delete failed: ${response.statusCode} ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Exception during gallery delete: $e');
      return false;
    }
  }

  static Future<List<String>?> getGalleryImages(int propertyId) async {
    final uri = ApiService.buildUri("/property/gallery?property_id=$propertyId");

    try {
      final response = await http.get(uri);

      final jsonData = jsonDecode(response.body);

      if (jsonData['success'] == true && jsonData['images'] != null) {
        // Return list of image URLs
        return List<String>.from(jsonData['images']);
      } else {
        debugPrint("Fetch gallery failed: ${jsonData['message']}");
        return null;
      }
    } catch (e) {
      debugPrint("Exception during fetching gallery: $e");
      return null;
    }
  }
  
  static Future<bool> addGalleryImage({
    required int propertyId,
    required XFile galleryImage,
  }) async {
    final uri = ApiService.buildUri("/property/gallery/add");

    try {
      var request = http.MultipartRequest('POST', uri);

      // Add property_id as field
      request.fields['property_id'] = propertyId.toString();

      // Add image file
      final bytes = await galleryImage.readAsBytes();
      request.files.add(
        http.MultipartFile.fromBytes(
          'gallery_image',
          bytes,
          filename: galleryImage.name,
        ),
      );

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final jsonData = jsonDecode(response.body);

      if (jsonData['success'] == true) {
        return true;
      } else {
        debugPrint("Add gallery image failed: ${jsonData['message']}");
        return false;
      }
    } catch (e) {
      debugPrint("Exception during add gallery image: $e");
      return false;
    }
  }


  static Future<bool> updateResidence({required int propertyId, required Map<String, dynamic> fields, XFile? thumbnail}) async {
    final uri = ApiService.buildUri("/property/residence/update");

    try {
      var request = http.MultipartRequest('POST', uri);

      // Add JSON fields
      request.fields['property_id'] = propertyId.toString();
      request.fields['fields'] = jsonEncode(fields);

      // Add thumbnail if available
      if (thumbnail != null) {
        final bytes = await thumbnail.readAsBytes();
        request.files.add(
          http.MultipartFile.fromBytes(
            'thumbnail',
            bytes,
            filename: thumbnail.name,
          ),
        );
      }

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      final jsonData = jsonDecode(response.body);

      if (jsonData['success'] == true) {
        return true;
      } else {
        debugPrint("Update failed: ${jsonData['message']}");
        return false;
      }
    } catch (e) {
      debugPrint("Exception during update: $e");
      return false;
    }
  }


 static Future<Residence> getDetails(int propertyId) async {
    final uri = ApiService.buildUri("/property/residence/details");
    final uid = FirebaseAuth.instance.currentUser?.uid;
    
    // Prepare request body
    final body = jsonEncode({
      "property_id": propertyId,
      "uid": uid
    });

    final response = await http.post(
      uri,
      headers: {"Content-Type": "application/json"},
      body: body,
    );

      final jsonData = jsonDecode(response.body);

      if (jsonData['success'] == true && jsonData['data'] != null) {
        return Residence.fromJson(jsonData['data']);
      } else {
        debugPrint(jsonData['message']);
        throw Exception(jsonData['message'] ?? "Failed to get residence details");
      }

  }

 static Future<ResidenceQueryResult> query({String? state, String? city, String? district, int page = 1,}) async {
    final id = AppUser().id;

    // Build query string 
    final endpoint = "/property/residences/summaries"
        "?id=$id"
        "${state != null ? "&state=$state" : ""}"
        "${city != null ? "&city=$city" : ""}"
        "${district != null ? "&district=$district" : ""}"
        "&page=$page";

    final uri = ApiService.buildUri(endpoint);

    final response = await http.get(
      uri,
      headers: {"Content-Type": "application/json"},
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      final residencesJson = jsonData['summaries'] as List;
      final totalCount = jsonData['length'] as int;

      final residences = residencesJson
          .map((item) => Residence.fromJson(item))
          .toList();

      return ResidenceQueryResult(
        residences: residences,
        totalCount: totalCount,
      );
    } else {
      debugPrint("Failed to query residences: ${response.body}");
      throw Exception("Failed to query residences");
    }

  }

static Future<List<Residence>> getOwnedProperties(int ownerId) async {
    // Construct endpoint with owner_id directly
    final endpoint = "/property/residences/owned?owner_id=$ownerId";
    final uri = ApiService.buildUri(endpoint);

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception(
          "Failed to fetch owned properties: ${response.statusCode}");
    }

    final data = jsonDecode(response.body);
    if (data["success"] != true) {
      throw Exception("Failed to fetch owned properties: ${data["message"]}");
    }

    final List<dynamic> propsJson = data["properties"];
    return propsJson.map((item) => Residence.fromJson(item)).toList();
  }

}




class ResidenceQueryResult {
  final List<Residence> residences;
  final int totalCount;

  ResidenceQueryResult({
    required this.residences,
    required this.totalCount,
});
}