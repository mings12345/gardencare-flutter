class Message {
  final int id;
  final int senderId;
  final int receiverId;
  final String message; // Ensure this is non-nullable
  final DateTime? createdAt; // Nullable
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
      id: json['id'] ?? 0, // Default to 0 if null
      senderId: json['sender_id'] ?? 0, // Default to 0 if null
      receiverId: json['receiver_id'] ?? 0, // Default to 0 if null
      message: json['message'] ?? '', // Default to an empty string if null
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at']) 
          : null, // Handle invalid or null dates
      isRead: json['is_read'] ?? false, // Default to false if null
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