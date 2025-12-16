import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter_application/models/request.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_application/services/api_service.dart';
import 'package:image_picker/image_picker.dart';

class RentService{
  static Future<Request?> getRentRequest(int requestId) async {
    try {
      final uri = ApiService.buildUri("/rent/request/$requestId");

      final response = await http.get(uri);

      final responseBody = json.decode(response.body);

      if (response.statusCode == 200 && responseBody['success'] == true) {

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

  static Future<List<Request>> getAllRentRequests(int propertyId) async {
  try {

    final uri = ApiService.buildUri("/rent/requests/$propertyId");
    final response = await http.get(uri);

    final responseBody = json.decode(response.body);

    if (response.statusCode == 200 && responseBody['success'] == true) {
      final List<dynamic> requestListJson = responseBody['requests'];
      return requestListJson.map((json) => Request.fromJson(json)).toList();
    } else {
      debugPrint(
        "Failed to fetch requests: ${response.statusCode} -> ${responseBody['message'] ?? responseBody}"
      );
      return [];
    }
  } catch (e) {
    debugPrint("Exception during fetch: $e");
    return [];
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
  static Future<bool> acceptRentRequest({
    required int requestId,
  }) async {
    try {
      final uri = ApiService.buildUri("/rent/request/accept");
      final response = await http.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          'request_id': requestId,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint("Rent request accepted successfully: ${response.body}");
        return true;
      } else {
        debugPrint("Accept failed: ${response.statusCode} -> ${response.body}");
        return false;
      }
    } catch (e) {
      debugPrint("Exception during accept: $e");
      return false;
    }
  }

  static Future<bool> rejectRentRequest({
    required int requestId,
  }) async {
    try {
      final uri = ApiService.buildUri("/rent/request/reject");
      final response = await http.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          'request_id': requestId,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint("Rent request rejected successfully: ${response.body}");
        return true;
      } else {
        debugPrint("Reject failed: ${response.statusCode} -> ${response.body}");
        return false;
      }
    } catch (e) {
      debugPrint("Exception during reject: $e");
      return false;
    }
  }

  static Future<bool> terminateRentRequest({
    required int userId,
    required int requestId,
  }) async {
    try {
      final uri = ApiService.buildUri("/rent/request/terminate"); 

      final response = await http.post(
        uri,
        body: jsonEncode({
          'user_id': userId,
          'request_id': requestId,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint("Rent request terminated successfully: ${response.body}");
        return true;
      } else {
        debugPrint("Terminate failed: ${response.statusCode} -> ${response.body}");
        return false;
      }
    } catch (e) {
      debugPrint("Exception during terminate: $e");
      return false;
    }
  }

  static Future<bool> uploadContract({
    required int userId,
    required int requestId,
    required XFile contractFile,
    int? gracePeriodDays,
    double? rentalPrice,
    double? depositPrice,
  }) async {
    try {
      final uri = ApiService.buildUri("/rent/request/upload_contract");

      var request = http.MultipartRequest('POST', uri);

      request.fields['request_id'] = requestId.toString();
      request.fields['user_id'] = userId.toString();
      
      if (gracePeriodDays != null) {
        request.fields['grace_period_days'] = gracePeriodDays.toString();
      }
      if (rentalPrice != null) {
        request.fields['rental_price'] = rentalPrice.toString();
      }
      if (depositPrice != null) {
        request.fields['deposit_price'] = depositPrice.toString();
      }

      final bytes = await contractFile.readAsBytes();
      request.files.add(
        http.MultipartFile.fromBytes(
          'contract',
          bytes,
          filename: contractFile.name,
        ),
      );

      var response = await request.send();
      var body = await response.stream.bytesToString();

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint("Contract uploaded successfully: $body");
        return true;
      } else {
        debugPrint("Contract upload failed: ${response.statusCode} -> $body");
        return false;
      }
    } catch (e) {
      debugPrint("Exception during contract upload: $e");
      return false;
    }
  }

  static Future<bool> handleContractApproval({
    required int requestId,
    required bool isApproved,     // true = approve, false = reject
    int? gracePeriodDays,         // optional: number of days
  }) async {
    try {
      final uri = ApiService.buildUri("/rent/request/handle_contract"); // single endpoint

      final body = {
        'request_id': requestId,
        'approved': isApproved, 
      };

      // Include grace period if provided
      if (gracePeriodDays != null) {
        body['grace_period_days'] = gracePeriodDays;
      }

      final response = await http.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint(
          "Contract ${isApproved ? 'approved' : 'rejected'} successfully: ${response.body}");
        return true;
      } else {
        debugPrint(
          "Contract ${isApproved ? 'approve' : 'reject'} failed: ${response.statusCode} -> ${response.body}");
        return false;
      }
    } catch (e) {
      debugPrint("Exception during contract ${isApproved ? 'approve' : 'reject'}: $e");
      return false;
    }
  }

  static Future<RentAmount?> getRentAmounts({
    required int requestId,
  }) async {
    try {
      final uri = ApiService.buildUri("/rent/request/amounts"); 

      final response = await http.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          'request_id': requestId,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Assuming backend returns { "price": 500.0, "deposit": 1000.0 }
        return RentAmount(
          price: (data['price'] as num).toDouble(),
          deposit: (data['deposit'] as num).toDouble(),
        );
      } else {
        debugPrint("Failed to get amounts: ${response.statusCode} -> ${response.body}");
        return null;
      }
    } catch (e) {
      debugPrint("Exception during getRentAmounts: $e");
      return null;
    }
  }

  static Future<bool> payFirstPayment({
    required int requestId,
  }) async {
    try {
      final uri = ApiService.buildUri("/rent/request/pay_first_payment"); // placeholder

      final response = await http.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          'request_id': requestId,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint("First payment successful: ${response.body}");
        return true;
      } else {
        debugPrint("First payment failed: ${response.statusCode} -> ${response.body}");
        return false;
      }
    } catch (e) {
      debugPrint("Exception during first payment: $e");
      return false;
    }
  }

  static Future<bool> payRent({
    required int tenantRecordId,
    required double totalAmount,
  }) async {
    try {
      final uri = ApiService.buildUri("/rent/pay_rent");

      final response = await http.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          'tenant_record_id': tenantRecordId,
          'total_amount': totalAmount,
        }),
      );

      if (response.statusCode == 200) {
        debugPrint("Rent paid successfully: ${response.body}");
        return true;
      } else {
        debugPrint("Rent payment failed: ${response.statusCode} -> ${response.body}");
        return false;
      }
    } catch (e) {
      debugPrint("Exception during payRent: $e");
      return false;
    }
  }


}

class RentAmount {
  final double price;
  final double deposit;

  RentAmount({required this.price, required this.deposit});
}