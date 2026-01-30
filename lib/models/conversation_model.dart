// lib/models/conversation_model.dart

class ConversationModel {
  final int conversationId;
  final int friendId;
  final String friendUsername;
  final String? friendAvatar;
  final int friendLevel;
  final String? lastMessage;
  final int? lastSenderId;
  final int unreadCount;
  final DateTime? lastMessageAt;
  
  ConversationModel({
    required this.conversationId,
    required this.friendId,
    required this.friendUsername,
    this.friendAvatar,
    required this.friendLevel,
    this.lastMessage,
    this.lastSenderId,
    required this.unreadCount,
    this.lastMessageAt,
  });
  
  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      conversationId: json['conversation_id'],
      friendId: json['friend_id'],
      friendUsername: json['friend_username'],
      friendAvatar: json['friend_avatar'],
      friendLevel: json['friend_level'] ?? 1,
      lastMessage: json['last_message'],
      lastSenderId: json['last_sender_id'],
      unreadCount: json['unread_count'] ?? 0,
      lastMessageAt: json['last_message_at'] != null
          ? DateTime.parse(json['last_message_at'])
          : null,
    );
  }
  
  bool get hasUnread => unreadCount > 0;
}

class MessageModel {
  final int id;
  final int senderId;
  final int receiverId;
  final String content;
  final bool isRead;
  final DateTime createdAt;
  final String senderUsername;
  final String? senderAvatar;
  
  MessageModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.isRead,
    required this.createdAt,
    required this.senderUsername,
    this.senderAvatar,
  });
  
  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'],
      senderId: json['sender_id'],
      receiverId: json['receiver_id'],
      content: json['content'],
      isRead: json['is_read'] == 1,
      createdAt: DateTime.parse(json['created_at']),
      senderUsername: json['sender_username'],
      senderAvatar: json['sender_avatar'],
    );
  }
  
  bool isSentByMe(int currentUserId) => senderId == currentUserId;
}