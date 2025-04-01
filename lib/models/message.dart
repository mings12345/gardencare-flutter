class Message {
  final int id;
  final int senderId;
  final int receiverId;
  final String message;
  final DateTime? createdAt; // Add this field
  final bool isRead; // Optional: for read receipts

  Message({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.message,
    this.createdAt,
    this.isRead = false,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] ?? 0,
      senderId: json['sender_id'],
      receiverId: json['receiver_id'],
      message: json['message'],
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
      isRead: json['is_read'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'sender_id': senderId,
    'receiver_id': receiverId,
    'message': message,
    'created_at': createdAt?.toIso8601String(),
    'is_read': isRead,
  };
}