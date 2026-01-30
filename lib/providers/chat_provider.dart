// lib/providers/chat_provider.dart

import 'package:flutter/material.dart';
import '../models/conversation_model.dart';
import '../services/api_service.dart';

class ChatProvider with ChangeNotifier {
  List<ConversationModel> _conversations = [];
  Map<int, List<MessageModel>> _messages = {}; // conversationId -> messages
  
  bool _isLoading = false;
  bool _isSendingMessage = false;
  int _unreadCount = 0;
  String? _errorMessage;
  
  final ApiService _apiService = ApiService();
  
  // Getters
  List<ConversationModel> get conversations => _conversations;
  Map<int, List<MessageModel>> get messages => _messages;
  bool get isLoading => _isLoading;
  bool get isSendingMessage => _isSendingMessage;
  int get unreadCount => _unreadCount;
  String? get errorMessage => _errorMessage;
  
  // Get messages for a specific conversation
  List<MessageModel> getMessagesForConversation(int conversationId) {
    return _messages[conversationId] ?? [];
  }
  
  // Load all conversations
  Future<void> loadConversations() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final response = await _apiService.get('/chat/conversations');
      _conversations = (response as List)
          .map((c) => ConversationModel.fromJson(c))
          .toList();
      
      // Calculate total unread count
      _unreadCount = _conversations.fold(0, (sum, conv) => sum + conv.unreadCount);
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Get or create conversation with a friend
  Future<int?> getOrCreateConversation(int friendId) async {
    try {
      print('📌 CHAT: Getting conversation for friend $friendId');
      
      // Call the correct route: /chat/conversations/:friendId/get-or-create
      final response = await _apiService.get('/chat/conversations/$friendId/get-or-create');
      
      print('📥 CHAT: Response: $response');
      
      if (response is Map) {
        final conversationId = response['conversation_id'] as int?;
        
        if (conversationId != null && conversationId > 0) {
          print('✅ CHAT: Got conversation ID: $conversationId');
          return conversationId;
        } else {
          print('❌ CHAT: Invalid conversation_id: $conversationId');
          return null;
        }
      } else {
        print('❌ CHAT: Unexpected response type: ${response.runtimeType}');
        return null;
      }
    } catch (e) {
      print('❌ CHAT: Error getting conversation: $e');
      return null;
    }
  }
  
  // Load messages for a conversation
  Future<void> loadMessages(int conversationId, {int limit = 50, int offset = 0}) async {
    try {
      final response = await _apiService.get(
        '/chat/conversations/$conversationId/messages?limit=$limit&offset=$offset',
      );
      
      final messagesList = (response as List)
          .map((m) => MessageModel.fromJson(m))
          .toList();
      
      if (offset == 0) {
        // First load - replace
        _messages[conversationId] = messagesList;
      } else {
        // Load more - prepend old messages
        _messages[conversationId] = [
          ...messagesList,
          ...(_messages[conversationId] ?? []),
        ];
      }
      
      notifyListeners();
    } catch (e) {
      print('Error loading messages: $e');
    }
  }
  
  // Send a message
  Future<bool> sendMessage(int conversationId, String content) async {
    if (content.trim().isEmpty) return false;
    
    _isSendingMessage = true;
    notifyListeners();
    
    try {
      final response = await _apiService.post(
        '/chat/conversations/$conversationId/messages',
        {'content': content},
      );
      
      final newMessage = MessageModel.fromJson(response);
      
      // Add message to local list
      if (_messages[conversationId] == null) {
        _messages[conversationId] = [];
      }
      _messages[conversationId]!.add(newMessage);
      
      // Update conversation list
      final convIndex = _conversations.indexWhere((c) => c.conversationId == conversationId);
      if (convIndex != -1) {
        final conv = _conversations[convIndex];
        _conversations[convIndex] = ConversationModel(
          conversationId: conv.conversationId,
          friendId: conv.friendId,
          friendUsername: conv.friendUsername,
          friendAvatar: conv.friendAvatar,
          friendLevel: conv.friendLevel,
          lastMessage: content,
          lastSenderId: newMessage.senderId,
          unreadCount: conv.unreadCount,
          lastMessageAt: newMessage.createdAt,
        );
        
        // Move conversation to top
        final updatedConv = _conversations.removeAt(convIndex);
        _conversations.insert(0, updatedConv);
      }
      
      _isSendingMessage = false;
      notifyListeners();
      return true;
    } catch (e) {
      print('Error sending message: $e');
      _isSendingMessage = false;
      notifyListeners();
      return false;
    }
  }
  
  // Mark conversation as read
  Future<void> markAsRead(int conversationId) async {
    try {
      await _apiService.post('/chat/conversations/$conversationId/read', {});
      
      // Update local conversation
      final convIndex = _conversations.indexWhere((c) => c.conversationId == conversationId);
      if (convIndex != -1) {
        final conv = _conversations[convIndex];
        _unreadCount -= conv.unreadCount;
        
        _conversations[convIndex] = ConversationModel(
          conversationId: conv.conversationId,
          friendId: conv.friendId,
          friendUsername: conv.friendUsername,
          friendAvatar: conv.friendAvatar,
          friendLevel: conv.friendLevel,
          lastMessage: conv.lastMessage,
          lastSenderId: conv.lastSenderId,
          unreadCount: 0,
          lastMessageAt: conv.lastMessageAt,
        );
      }
      
      // Mark local messages as read
      if (_messages[conversationId] != null) {
        _messages[conversationId] = _messages[conversationId]!.map((msg) {
          return MessageModel(
            id: msg.id,
            senderId: msg.senderId,
            receiverId: msg.receiverId,
            content: msg.content,
            isRead: true,
            createdAt: msg.createdAt,
            senderUsername: msg.senderUsername,
            senderAvatar: msg.senderAvatar,
          );
        }).toList();
      }
      
      notifyListeners();
    } catch (e) {
      print('Error marking as read: $e');
    }
  }
  
  // Load unread count
  Future<void> loadUnreadCount() async {
    try {
      final response = await _apiService.get('/chat/unread-count');
      _unreadCount = response['unread_count'] ?? 0;
      notifyListeners();
    } catch (e) {
      print('Error loading unread count: $e');
    }
  }
  
  // Delete conversation
  Future<bool> deleteConversation(int conversationId) async {
    try {
      await _apiService.delete('/chat/conversations/$conversationId');
      
      // Remove from local lists
      _conversations.removeWhere((c) => c.conversationId == conversationId);
      _messages.remove(conversationId);
      
      notifyListeners();
      return true;
    } catch (e) {
      print('Error deleting conversation: $e');
      return false;
    }
  }
  
  // Add a message to local list (for real-time updates)
  void addMessageLocally(int conversationId, MessageModel message) {
    if (_messages[conversationId] == null) {
      _messages[conversationId] = [];
    }
    _messages[conversationId]!.add(message);
    
    // Update conversation
    final convIndex = _conversations.indexWhere((c) => c.conversationId == conversationId);
    if (convIndex != -1) {
      final conv = _conversations[convIndex];
      _conversations[convIndex] = ConversationModel(
        conversationId: conv.conversationId,
        friendId: conv.friendId,
        friendUsername: conv.friendUsername,
        friendAvatar: conv.friendAvatar,
        friendLevel: conv.friendLevel,
        lastMessage: message.content,
        lastSenderId: message.senderId,
        unreadCount: conv.unreadCount + 1,
        lastMessageAt: message.createdAt,
      );
      
      // Move to top
      final updatedConv = _conversations.removeAt(convIndex);
      _conversations.insert(0, updatedConv);
      
      _unreadCount++;
    }
    
    notifyListeners();
  }
}