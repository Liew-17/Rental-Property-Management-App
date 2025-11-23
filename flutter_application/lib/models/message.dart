class Message {
  final int id; // unique ID from backend
  final int senderId;
  final String messageBody;
  final String type; // e.g., "text", "offer", "notification"
  final DateTime sentAt;

  Message({
    required this.id,
    required this.senderId,
    required this.messageBody,
    required this.type,
    required this.sentAt,
  });

  // Create a Message from JSON (from backend)
  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'], // make sure backend returns 'id'
      senderId: json['sender_id'],
      messageBody: json['message_body'],
      type: json['type'],
      sentAt: DateTime.parse(json['sent_at']),
    );
  }

  // Convert Message to JSON (for sending to backend)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender_id': senderId,
      'message_body': messageBody,
      'type': type,
      'sent_at': sentAt.toIso8601String(),
    };
  }
}
