import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_application/models/user.dart';
import 'package:http/http.dart' as http;
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

  
}