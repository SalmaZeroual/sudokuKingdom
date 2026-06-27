import 'package:flutter/material.dart';
import '../models/friend_model.dart';
import '../services/api_service.dart';
import '../services/offline_service.dart';

class FriendsProvider with ChangeNotifier {
  FriendsProvider() {
    // ✅ Bug corrigé : sans ça, un échec de chargement (même bref) au tout
    // premier passage sur l'onglet Amis restait figé sur "Pas de
    // connexion" pour le reste de la session, même après le retour réel
    // du réseau.
    OfflineService.registerReconnectCallback(() async {
      if (_isOffline) await loadFriends();
      if (_isPendingRequestsOffline) await loadPendingRequests();
    });
  }

  List<FriendModel> _friends = [];
  List<FriendRequest> _pendingRequests = [];
  List<FriendModel> _searchResults = [];
  
  bool _isLoading = false;
  bool _isSearching = false;
  String? _errorMessage;
  // ✅ NOUVEAU : distingue "pas de connexion" de "vraiment aucun ami".
  bool _isOffline = false;
  bool _isPendingRequestsOffline = false; // ✅ NOUVEAU
  
  final ApiService _apiService = ApiService();
  
  // Getters
  List<FriendModel> get friends => _friends;
  List<FriendRequest> get pendingRequests => _pendingRequests;
  List<FriendModel> get searchResults => _searchResults;
  bool get isLoading => _isLoading;
  bool get isSearching => _isSearching;
  String? get errorMessage => _errorMessage;
  bool get isOffline => _isOffline;
  bool get isPendingRequestsOffline => _isPendingRequestsOffline;
  int get friendCount => _friends.length;
  int get pendingCount => _pendingRequests.length;
  
  // Load friends list
  Future<void> loadFriends() async {
    _isLoading = true;
    _errorMessage = null;
    _isOffline = false;
    notifyListeners();
    
    try {
      dynamic response = await _apiService.get('/social/friends');
      // defensive: older API used to return { friends: [...] }
      if (response is Map && response.containsKey('friends')) {
        response = response['friends'];
      }
      // log for debugging if something weird comes back
      debugPrint('Friends API response: $response');
      
      if (response is List) {
        _friends = response.map((f) => FriendModel.fromJson(f)).toList();
      } else {
        // unexpected shape, keep list empty and record error
        _errorMessage = 'Unexpected friends response';
        _friends = [];
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      // ✅ Bug corrigé : avant, une coupure réseau affichait "Aucun ami"
      // comme si la liste était réellement vide. On garde maintenant la
      // dernière liste connue en mémoire et on signale clairement qu'il
      // s'agit d'un problème de connexion, pas d'une absence d'amis.
      _isOffline = e is ApiException && e.isOffline;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      debugPrint('loadFriends error: $e');
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Load pending requests
  Future<void> loadPendingRequests() async {
    _isPendingRequestsOffline = false;
    try {
      final response = await _apiService.get('/social/friends/pending');
      _pendingRequests = (response as List).map((r) => FriendRequest.fromJson(r)).toList();
      notifyListeners();
    } catch (e) {
      // ✅ Bug corrigé : une coupure réseau affichait "Aucune demande" comme
      // si elles n'existaient vraiment pas.
      _isPendingRequestsOffline = e is ApiException && e.isOffline;
      print('Error loading pending requests: $e');
      notifyListeners();
    }
  }
  
  // Search users
  bool _isSearchOffline = false; // ✅ NOUVEAU

  Future<void> searchUsers(String query) async {
    if (query.length < 2) {
      _searchResults = [];
      _isSearchOffline = false;
      notifyListeners();
      return;
    }
    
    _isSearching = true;
    _isSearchOffline = false;
    notifyListeners();
    
    try {
      final response = await _apiService.get('/social/users/search?query=$query');
      _searchResults = (response as List).map((u) => FriendModel.fromJson(u)).toList();
      
      _isSearching = false;
      notifyListeners();
    } catch (e) {
      // ✅ Bug corrigé : une coupure réseau pendant une recherche affichait
      // "Aucun utilisateur trouvé", comme si ce pseudo/cet ID n'existait
      // tout simplement pas — alors qu'on ne pouvait juste pas vérifier.
      _isSearchOffline = e is ApiException && e.isOffline;
      _isSearching = false;
      notifyListeners();
    }
  }
  
  bool get isSearchOffline => _isSearchOffline;
  
  // Send friend request
  Future<bool> sendFriendRequest(int friendId) async {
    try {
      await _apiService.post('/social/friends/request', {
        'friend_id': friendId,
      });
      
      // Update local search results
      final index = _searchResults.indexWhere((f) => f.id == friendId);
      if (index != -1) {
        _searchResults[index] = FriendModel(
          id: _searchResults[index].id,
          username: _searchResults[index].username,
          level: _searchResults[index].level,
          avatar: _searchResults[index].avatar,
          xp: _searchResults[index].xp,
          league: _searchResults[index].league,
          friendshipStatus: 'pending',
        );
        notifyListeners();
      }
      
      return true;
    } catch (e) {
      print('Error sending friend request: $e');
      return false;
    }
  }
  
  // Accept friend request
  Future<bool> acceptFriendRequest(int friendshipId) async {
    try {
      await _apiService.post('/social/friends/accept/$friendshipId', {});
      
      // Remove from pending
      _pendingRequests.removeWhere((r) => r.friendshipId == friendshipId);
      
      // Reload friends list
      await loadFriends();
      
      return true;
    } catch (e) {
      print('Error accepting friend request: $e');
      return false;
    }
  }
  
  // Reject friend request
  Future<bool> rejectFriendRequest(int friendshipId) async {
    try {
      await _apiService.post('/social/friends/reject/$friendshipId', {});
      
      // Remove from pending
      _pendingRequests.removeWhere((r) => r.friendshipId == friendshipId);
      notifyListeners();
      
      return true;
    } catch (e) {
      print('Error rejecting friend request: $e');
      return false;
    }
  }
  
  // Remove friend
  Future<bool> removeFriend(int friendId) async {
    try {
      await _apiService.delete('/social/friends/$friendId');
      
      // Remove from friends list
      _friends.removeWhere((f) => f.id == friendId);
      notifyListeners();
      
      return true;
    } catch (e) {
      print('Error removing friend: $e');
      return false;
    }
  }
  
  // Clear search
  void clearSearch() {
    _searchResults = [];
    notifyListeners();
  }
}