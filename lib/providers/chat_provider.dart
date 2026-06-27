// lib/providers/chat_provider.dart

import 'package:flutter/material.dart';
import '../models/conversation_model.dart';
import '../services/api_service.dart';
import '../services/offline_service.dart';

class ChatProvider with ChangeNotifier {
  ChatProvider() {
    // ✅ Même correction que pour les Amis : on redonne sa chance à la
    // liste de conversations dès le retour réel du réseau.
    OfflineService.registerReconnectCallback(() async {
      if (_isOffline) await loadConversations();
    });
  }

  List<ConversationModel> _conversations = [];
  Map<int, List<MessageModel>> _messages = {}; // conversationId -> messages
  
  bool _isLoading = false;
  bool _isSendingMessage = false;
  int _unreadCount = 0;
  String? _errorMessage;
  bool _isOffline = false; // ✅ NOUVEAU

  // ✅ NOUVEAU : statut d'envoi par conversation (peut-on envoyer ? pourquoi pas ?)
  // Permet d'afficher directement "Vous ne pouvez pas envoyer de message"
  // au lieu d'une fausse erreur de connexion.
  final Map<int, bool> _canSend = {};
  final Map<int, String?> _blockReason = {}; // 'blocked' | 'messages_disabled' | null
  final Map<int, bool> _iBlockedThem = {};
  
  final ApiService _apiService = ApiService();
  
  // Getters
  List<ConversationModel> get conversations => _conversations;
  Map<int, List<MessageModel>> get messages => _messages;
  bool get isLoading => _isLoading;
  bool get isSendingMessage => _isSendingMessage;
  int get unreadCount => _unreadCount;
  String? get errorMessage => _errorMessage;
  bool get isOffline => _isOffline;

  bool canSend(int conversationId) => _canSend[conversationId] ?? true;
  String? blockReason(int conversationId) => _blockReason[conversationId];
  bool iBlockedThem(int conversationId) => _iBlockedThem[conversationId] ?? false;
  
  // Get messages for a specific conversation
  List<MessageModel> getMessagesForConversation(int conversationId) {
    return _messages[conversationId] ?? [];
  }
  
  // Load all conversations
  Future<void> loadConversations() async {
    _isLoading = true;
    _errorMessage = null;
    _isOffline = false;
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
      // ✅ Bug corrigé : avant, une coupure réseau affichait "Aucune
      // conversation" comme si elles n'existaient pas. On garde la
      // dernière liste connue et on signale clairement le problème de
      // connexion.
      _isOffline = e is ApiException && e.isOffline;
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
  
  // ✅ NOUVEAU : vérifie si on peut envoyer un message dans cette
  // conversation (bloqué ? destinataire a désactivé les messages ?).
  // À appeler à l'ouverture du chat.
  Future<void> checkConversationStatus(int conversationId) async {
    try {
      final response = await _apiService.get('/chat/conversations/$conversationId/status');
      _canSend[conversationId] = response['can_send'] ?? true;
      _blockReason[conversationId] = response['reason'];
      _iBlockedThem[conversationId] = response['i_blocked_them'] ?? false;
      notifyListeners();
    } catch (e) {
      print('Error checking conversation status: $e');
      // En cas d'erreur réseau on n'empêche pas d'essayer d'envoyer.
      _canSend[conversationId] = true;
    }
  }

  // ✅ NOUVEAU : bloquer les messages d'un ami. Ne touche PAS à l'amitié :
  // on reste amis (peut toujours se défier en duel), mais plus aucun
  // message ne passe tant que ce n'est pas débloqué.
  Future<bool> blockFriendMessages(int friendId, int conversationId) async {
    try {
      await _apiService.post('/chat/block/$friendId', {});
      _canSend[conversationId] = false;
      _blockReason[conversationId] = 'blocked';
      _iBlockedThem[conversationId] = true;
      notifyListeners();
      return true;
    } catch (e) {
      print('Error blocking user: $e');
      return false;
    }
  }

  Future<bool> unblockFriendMessages(int friendId, int conversationId) async {
    try {
      await _apiService.delete('/chat/block/$friendId');
      _canSend[conversationId] = true;
      _blockReason[conversationId] = null;
      _iBlockedThem[conversationId] = false;
      notifyListeners();
      return true;
    } catch (e) {
      print('Error unblocking user: $e');
      return false;
    }
  }

  // Send a message
  Future<bool> sendMessage(int conversationId, String content) async {
    if (content.trim().isEmpty) return false;
    
    _isSendingMessage = true;
    _errorMessage = null;
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
      // ✅ Bug corrigé : avant, on perdait la vraie raison de l'échec
      // ("connexion ?" se demandait l'utilisateur, alors que c'est tout
      // simplement qu'il n'est plus ami / a été bloqué). Maintenant on
      // garde le message précis renvoyé par le serveur et on met à jour
      // l'état de blocage pour que la barre de saisie se cache.
      if (e is ApiException) {
        _errorMessage = e.message;
        if (e.data?['blocked'] == true) {
          _canSend[conversationId] = false;
          _blockReason[conversationId] = 'blocked';
        } else if (e.data?['messages_disabled'] == true) {
          _canSend[conversationId] = false;
          _blockReason[conversationId] = 'messages_disabled';
        }
      } else {
        _errorMessage = e.toString();
      }
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