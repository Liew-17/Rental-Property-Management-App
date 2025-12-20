import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter_application/models/lease.dart';
import 'package:flutter_application/models/tenant_record.dart';
import 'package:flutter_application/models/user.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_application/models/residence.dart';
import 'package:flutter_application/services/api_service.dart';
import 'package:image_picker/image_picker.dart';


class PropertyService {

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

  static Future<double?> predictProperty({required int propertyId}) async {
    try {
      final uri = ApiService.buildUri("/property/residence/predict/$propertyId");
      
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['predicted_price'] as num).toDouble();
      } else {
        debugPrint('Prediction failed: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Exception during prediction: $e');
      return null;
    }
  }

  static Future<bool> listProperty({
  required int propertyId,
  required double price,
  double? deposit,
  }) async {
    try {
      final uri = ApiService.buildUri("/property/residence/list");

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'property_id': propertyId,
          'price': price,
          'deposit': deposit,
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        debugPrint('Listing failed: ${response.statusCode} ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Exception during property listing: $e');
      return false;
    }
  }

  static Future<bool> unlistProperty({required int propertyId}) async {
    try {
      final uri = ApiService.buildUri("/property/residence/unlist");

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'property_id': propertyId,
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        debugPrint('Unlisting failed: ${response.statusCode} ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Exception during property unlisting: $e');
      return false;
    }
  }

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
    final id = AppUser().id;
    
    // Prepare request body
    final body = jsonEncode({
      "property_id": propertyId,
      "id": id,
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

  static Future<List<Residence>> searchResidences({
    String? query,
    String? state,
    String? city,
    String? district,
    double? minPrice,
    double? maxPrice,
    String? residenceType,
    int? minBedrooms,
    int? minBathrooms,
    double? minSize,
    double? maxSize,
  }) async {

    Map<String, String> queryParams = {};
    if(AppUser().id != null){
        queryParams['user_id'] = AppUser().id.toString();
    }    
    if (query != null && query.isNotEmpty) queryParams['query'] = query;
    if (state != null) queryParams['state'] = state;
    if (city != null) queryParams['city'] = city;
    if (district != null) queryParams['district'] = district;
    if (minPrice != null) queryParams['min_price'] = minPrice.toString();
    if (maxPrice != null) queryParams['max_price'] = maxPrice.toString();
    if (residenceType != null) queryParams['residence_type'] = residenceType;
    if (minBedrooms != null) queryParams['min_bedrooms'] = minBedrooms.toString();
    if (minBathrooms != null) queryParams['min_bathrooms'] = minBathrooms.toString();
    if (minSize != null) queryParams['min_size'] = minSize.toString();
    if (maxSize != null) queryParams['max_size'] = maxSize.toString();

    final uri = ApiService.buildUri("/property/search").replace(queryParameters: queryParams);

    try {
      final response = await http.get(uri);
      final jsonData = jsonDecode(response.body);

      if (response.statusCode == 200 && jsonData['success'] == true) {
        List<dynamic> results = jsonData['data']['results'];
        return results.map((item) => Residence.fromJson(item)).toList();
      }
    } catch (e) {
      debugPrint("Search error: $e");
    }
    return [];
  }

  static Future<List<Residence>> getOwnedProperties(int ownerId) async {
   
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

  static Future<List<Residence>> getRentedProperties(int tenantId) async {
    
    final endpoint = "/property/residences/rented/$tenantId";
    final uri = ApiService.buildUri(endpoint);

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception(
          "Failed to fetch rented properties: ${response.statusCode}");
    }

    final data = jsonDecode(response.body);
    if (data["success"] != true) {
      throw Exception("Failed to fetch rented properties: ${data["message"]}");
    }

    final List<dynamic> propsJson = data["properties"];
    return propsJson.map((item) => Residence.fromJson(item)).toList();
  }

 static Future<List<Lease>> getAllLeases(int propertyId) async {
    final uri = ApiService.buildUri("/property/get_lease/$propertyId/0"); // 0 = fetch all (not included terminated leases)

    try {
      final response = await http.get(uri);
      final jsonData = jsonDecode(response.body);

      if (jsonData['success'] == true) {
        List<dynamic> list = jsonData['data']; 
        return list.map((item) => Lease.fromJson(item)).toList();
      } else {
        return [];
      }
    } catch (e) {
      debugPrint("Exception during get lease: $e");
      return [];
    }
  }

  
  static Future<List<TenantRecord>> getTenantRecords({required int leaseId}) async {
    final uri = ApiService.buildUri("/property/get_tenant_records/$leaseId");

    try {
      final response = await http.get(uri);
      final jsonData = jsonDecode(response.body);

      if (jsonData['success'] == true) {
        List<dynamic> list = jsonData['data'];
        return list.map((item) => TenantRecord.fromJson(item)).toList();
      } else {
        debugPrint("Get tenant records failed: ${jsonData['message']}");
        return [];
      }
    } catch (e) {
      debugPrint("Exception during get tenant records: $e");
      return [];
    }
  }

  static Future<Lease?> getActiveLeaseForTenant(int propertyId) async {
    final uri = ApiService.buildUri("/property/get_lease/$propertyId/1"); 

    try {
      final response = await http.get(uri);
      final jsonData = jsonDecode(response.body);

      if (jsonData['success'] == true) {
        List<dynamic> list = jsonData['data'];
        
        if (list.isNotEmpty) {
          final lease = Lease.fromJson(list.first);
          
          // verification
          final currentUserId = AppUser().id;
          if (currentUserId != null && lease.tenantId == currentUserId) {
            final records = await getTenantRecords(leaseId: lease.id); // fetch tenant records
            
            records.sort((a, b) => b.startDate.compareTo(a.startDate));
            
            lease.tenantRecords = records;
            
            return lease;
          } else {
            debugPrint("Active lease found, but current user ($currentUserId) is not the tenant (${lease.tenantId}).");
            return null;
          }
        }
      }
      return null;
    } catch (e) {
      debugPrint("Exception fetching active lease for tenant: $e");
      return null;
    }
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