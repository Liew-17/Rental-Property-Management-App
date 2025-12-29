import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_application/models/request.dart';
import 'package:flutter_application/models/residence.dart';
import 'package:flutter_application/models/user.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'api_service.dart'; // your existing API helper

class UserService {
  /// Update user location
static Future<bool> updateLocation({
    required String state,
    required String city,
    required String district,
  }) async {
    final uri = ApiService.buildUri("/user/update_location");

    final response = await http.put(
      uri,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "id": AppUser().id,
        "state": state,
        "city": city,
        "district": district,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data["success"] == true) {
      final updatedUser = data["user"];

      AppUser().state = updatedUser["state"];
      AppUser().city = updatedUser["city"];
      AppUser().district = updatedUser["district"];

      return true;
    }

    return false;
  }

static Future<UserData?> getUserById({
    required int userId,
  }) async {
    try {
      final uri = ApiService.buildUri("/user/get_user_info/$userId"); 

      final response = await http.get(
        uri,
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (responseData['success'] == true && responseData['user'] != null) {
          return UserData.fromJson(responseData['user']);
        }
      }
      
      debugPrint("Get User failed: ${response.statusCode} -> ${response.body}");
      return null;
      
    } catch (e) {
      debugPrint("Exception during get user: $e");
      return null;
    }
  }

static Future<List<Request>> getUserRentRequests(int userId) async {
  try {
    // Build the URI for /get_user_request/<user_id>
    final uri = ApiService.buildUri("/user/get_user_request/$userId");

    // Send GET request
    final response = await http.get(uri);

    // Decode response
    final responseBody = json.decode(response.body);

    if (response.statusCode == 200 && responseBody['success'] == true) {
      // Convert each JSON item to Request object
      final List<dynamic> requestListJson = responseBody['requests'];
      return requestListJson.map((json) => Request.fromJson(json)).toList();
    } else {
      debugPrint(
        "Failed to fetch user rent requests: ${response.statusCode} -> ${responseBody['message'] ?? responseBody}"
      );
      return [];
    }
  } catch (e) {
    debugPrint("Exception during fetch user rent requests: $e");
    return [];
  }
}

static Future<bool?> toggleFavourite(int propertyId) async {
    try {
      final uri = ApiService.buildUri("/user/favourite/toggle");

      final response = await http.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": AppUser().id, 
          "property_id": propertyId,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data["success"] == true) {
        return true;
      } else {
        debugPrint("Failed to toggle favourite: ${data['message']}");
        return false;
      }
    } catch (e) {
      debugPrint("Exception calling toggleFavourite: $e");
      return false;
    }
  }

  /// Fetch the list of properties favorited by the current user.
  static Future<List<Residence>> getUserFavourites() async {
    try {
      final userId = AppUser().id;
      final uri = ApiService.buildUri("/user/favourites/$userId");

      final response = await http.get(uri);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data["success"] == true) {
        final List<dynamic> favouritesJson = data["favourites"];
        // Map the JSON list to Property objects
        return favouritesJson.map((json) => Residence.fromJson(json)).toList();
      } else {
        debugPrint("Failed to fetch favourites: ${data['message']}");
        return [];
      }
    } catch (e) {
      debugPrint("Exception fetching favourites: $e");
      return [];
    }
  }

  static Future<bool> updateRole(String role) async {
    try {
      final uri = ApiService.buildUri("/user/update_role");
      final response = await http.put(
        uri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": AppUser().id,
          "role": role,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        AppUser().role = role;
        return true;
      } else {
        debugPrint("Update role failed: ${data['message']}");
        return false;
      }
    } catch (e) {
      debugPrint("Exception updating role: $e");
      return false;
    }
  }

  static Future<bool> uploadProfilePic(XFile imageFile) async {
    try {
      final uri = ApiService.buildUri("/user/upload_profile_pic");
      final request = http.MultipartRequest("POST", uri);

      request.fields['user_id'] = AppUser().id.toString();

      final bytes = await imageFile.readAsBytes();
      request.files.add(
        http.MultipartFile.fromBytes(
          'profile_pic',
          bytes,
          filename: imageFile.name,
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        AppUser().profilePicUrl = data['profile_pic_url'];
        return true;
      } else {
        debugPrint("Upload failed: ${data['message']}");
        return false;
      }
    } catch (e) {
      debugPrint("Exception uploading profile pic: $e");
      return false;
    }
  }

}

class UserData {
  final int id;
  final String name;
  final String? profileUrl; // Nullable, because a user might not have an image

  const UserData({
    required this.id,
    required this.name,
    this.profileUrl,
  });

  /// Factory constructor to create a UserData from a Map (API response)
  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      id: json['id'], // Ensure it's a string
      name: json['username'] ?? 'Unknown User',
      profileUrl: json['profile_url'], // Ensure this key matches your DB column
    );
  }
}