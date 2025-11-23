import 'package:flutter_application/models/message.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'api_service.dart'; 

class ChatService {

  static Future<Message> sendImageMessage({
    required int senderId,
    required int channelId,
    required XFile imageFile,
  }) async {
    try {
      final uri = ApiService.buildUri("/chat/send_image");
      final request = http.MultipartRequest("POST", uri);

      request.fields['sender_id'] = senderId.toString();
      request.fields['channel_id'] = channelId.toString();

      final bytes = await imageFile.readAsBytes(); // works for mobile & web
      final fileName = imageFile.name;

      request.files.add(http.MultipartFile.fromBytes(
        'image_file',
        bytes,
        filename: fileName,
      ));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return Message.fromJson(data['data']);
      } else {
        throw Exception(data['message'] ?? 'Failed to send image message');
      }
    } catch (e) {
      throw Exception("ChatService.sendImageMessage error: $e");
    }
  }

  static Future<List<Message>> getMessages({
    required int channelId,
    int? limit,
    int? offset,
  }) async {
    final uri = ApiService.buildUri("/chat/messages");

    final body = {
      "channel_id": channelId,
      if (limit != null) "limit": limit,
      if (offset != null) "offset": offset,
    };

    final response = await http.post(
      uri,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      
      throw Exception("Failed to fetch messages");
    }

    final data = jsonDecode(response.body);

    List<dynamic> rawMessages = data["messages"];

    return rawMessages.map((m) => Message.fromJson(m)).toList();
  }

  static Future<Message> sendTextMessage({
    required int senderId,
    required int channelId,
    required String messageBody,
  }) async {
    final uri = ApiService.buildUri("/chat/send_text");

    final body = {
      "sender_id": senderId,
      "channel_id": channelId,
      "message_body": messageBody,
    };

    final response = await http.post(
      uri,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to send message");
    }

    final data = jsonDecode(response.body);
    final msg = Message.fromJson(data["data"]);

    return msg;
  }
}
