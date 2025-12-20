import 'package:flutter/widgets.dart';
import 'package:flutter_application/services/api_service.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  static late IO.Socket socket;

  static void connect(int userId) {
    socket = IO.io(ApiService.getApiAddress(), 
      IO.OptionBuilder()
        .setTransports(['websocket'])
        .disableAutoConnect()
        .build()
    );

    socket.connect();

    socket.onConnect((_) {
      debugPrint('Connected to WebSocket');
      socket.emit('join', {'user_id': userId});
    });
  }

  static void onEvent(String event, Function(dynamic) handler) {
    socket.on(event, handler);

  }

  static void offEvent(String event) {
    socket.off(event);
  }
}