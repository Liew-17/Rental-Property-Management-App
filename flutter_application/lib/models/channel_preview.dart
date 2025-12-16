class ChannelPreview {
  final int id;
  final String type; // 'query' or 'lease'
  final String status;
  final String myRole;  // 'tenant' or 'owner'
  
  final int propertyId;
  final String propertyTitle;
  final String? propertyImage;

  final int otherUserId;
  final String otherUserName;
  final String? otherUserProfile;

  final String lastMessage;
  final String lastMessageType;
  final DateTime? lastMessageTime;

  ChannelPreview({
    required this.id,
    required this.type,
    required this.status,
    required this.myRole,
    required this.propertyId,
    required this.propertyTitle,
    this.propertyImage,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserProfile,
    required this.lastMessage,
    required this.lastMessageType,
    this.lastMessageTime,
  });

  factory ChannelPreview.fromJson(Map<String, dynamic> json) {
    return ChannelPreview(
      id: json['id'],
      type: json['type'],
      status: json['status'],
      myRole: json['my_role'],
      propertyId: json['property_id'],
      propertyTitle: json['property_title'] ?? "Unknown",
      propertyImage: json['property_image'],
      otherUserId: json['other_user_id'],
      otherUserName: json['other_user_name'],
      otherUserProfile: json['other_user_profile'],
      lastMessage: json['last_message'] ?? "",
      lastMessageType: json['last_message_type'] ?? "text",
      lastMessageTime: json['last_message_time'] != null 
          ? DateTime.parse(json['last_message_time']) 
          : null,
    );
  }
}