import 'package:flutter/material.dart';
import '../models/friend_model.dart';
import '../services/api_service.dart';

class FriendsProvider with ChangeNotifier {
  List<FriendModel> _friends = [];
  List<FriendRequest> _pendingRequests = [];
  List<FriendModel> _searchResults = [];
  
  bool _isLoading = false;
  bool _isSearching = false;
  String? _errorMessage;
  
  final ApiService _apiService = ApiService();
  
  // Getters
  List<FriendModel> get friends => _friends;
  List<FriendRequest> get pendingRequests => _pendingRequests;
  List<FriendModel> get searchResults => _searchResults;
  bool get isLoading => _isLoading;
  bool get isSearching => _isSearching;
  String? get errorMessage => _errorMessage;
  int get friendCount => _friends.length;
  int get pendingCount => _pendingRequests.length;
  
  // Load friends list
  Future<void> loadFriends() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final response = await _apiService.get('/social/friends');
      _friends = (response as List).map((f) => FriendModel.fromJson(f)).toList();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Load pending requests
  Future<void> loadPendingRequests() async {
    try {
      final response = await _apiService.get('/social/friends/pending');
      _pendingRequests = (response as List).map((r) => FriendRequest.fromJson(r)).toList();
      notifyListeners();
    } catch (e) {
      print('Error loading pending requests: $e');
    }
  }
  
  // Search users
  Future<void> searchUsers(String query) async {
    if (query.length < 2) {
      _searchResults = [];
      notifyListeners();
      return;
    }
    
    _isSearching = true;
    notifyListeners();
    
    try {
      final response = await _apiService.get('/social/users/search?query=$query');
      _searchResults = (response as List).map((u) => FriendModel.fromJson(u)).toList();
      
      _isSearching = false;
      notifyListeners();
    } catch (e) {
      _isSearching = false;
      notifyListeners();
    }
  }
  
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