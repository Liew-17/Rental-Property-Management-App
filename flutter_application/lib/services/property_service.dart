import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter_application/models/user.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application/models/residence.dart';
import 'package:flutter_application/services/api_service.dart';


class PropertyService {
  
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

  static Future<ResidenceQueryResult> query({
    String? state,
    String? city,
    String? district,
    int page = 1,
  }) async {
    final uri = ApiService.buildUri("/property/residences/summaries");
    final id = AppUser().id;

    final body = jsonEncode({
      "state": state,
      "city": city,
      "district": district,
      "page": page,
      "id": id,
    });

    final response = await http.post(
      uri,
      headers: {"Content-Type": "application/json"},
      body: body,
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

}


class ResidenceQueryResult {
  final List<Residence> residences;
  final int totalCount;

  ResidenceQueryResult({
    required this.residences,
    required this.totalCount,
});
}