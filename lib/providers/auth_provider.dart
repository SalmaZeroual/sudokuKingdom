import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../config/constants.dart';

class AuthProvider with ChangeNotifier {
  UserModel? _user;
  String? _token;
  bool _isLoading = false;
  String? _errorMessage;
  
  UserModel? get user => _user;
  String? get token => _token;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _token != null && _user != null;
  
  final ApiService apiService = ApiService();
  
  Future<void> checkAuthStatus() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(AppConstants.tokenKey);
    
    if (_token != null) {
      await loadUser();
    }
    notifyListeners();
  }
  
  Future<Map<String, dynamic>> register(String username, String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final response = await apiService.post('/auth/register', {
        'username': username,
        'email': email,
        'password': password,
      });
      
      _isLoading = false;
      notifyListeners();
      
      return response;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }
  
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final response = await apiService.post('/auth/login', {
        'email': email,
        'password': password,
      });
      
      // Check if email verification is required
      if (response['requiresVerification'] == true) {
        _errorMessage = 'Email non vérifié';
        _isLoading = false;
        notifyListeners();
        return false;
      }
      
      _token = response['token'];
      _user = UserModel.fromJson(response['user']);
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.tokenKey, _token!);
      await prefs.setInt(AppConstants.userIdKey, _user!.id);
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  Future<Map<String, dynamic>> verifyEmail(String email, String code) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final response = await apiService.post('/auth/verify-email', {
        'email': email,
        'code': code,
      });
      
      _token = response['token'];
      _user = UserModel.fromJson(response['user']);
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.tokenKey, _token!);
      await prefs.setInt(AppConstants.userIdKey, _user!.id);
      
      _isLoading = false;
      notifyListeners();
      
      return response;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }
  
  Future<void> loadUser() async {
    try {
      final response = await apiService.get('/auth/me');
      _user = UserModel.fromJson(response);
      notifyListeners();
    } catch (e) {
      print('Error loading user: $e');
    }
  }
  
  Future<void> logout() async {
    _user = null;
    _token = null;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.tokenKey);
    await prefs.remove(AppConstants.userIdKey);
    
    notifyListeners();
  }
  
  void updateUser(UserModel user) {
    _user = user;
    notifyListeners();
  }
  
  // ==========================================
  // PASSWORD RESET METHODS
  // ==========================================
  
  Future<bool> requestPasswordReset(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      await apiService.post('/auth/forgot-password', {
        'email': email,
      });
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  Future<bool> verifyResetCode(String email, String code) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      await apiService.post('/auth/verify-reset-code', {
        'email': email,
        'code': code,
      });
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  Future<bool> resetPassword(String email, String code, String newPassword) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      await apiService.post('/auth/reset-password', {
        'email': email,
        'code': code,
        'newPassword': newPassword,
      });
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  // ==========================================
  // PROFILE UPDATE METHODS
  // ==========================================
  
  Future<bool> updateUsername(String newUsername) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final response = await apiService.put('/user/profile', {
        'username': newUsername,
      });
      
      if (_user != null) {
        _user = UserModel(
          id: _user!.id,
          username: newUsername,
          email: _user!.email,
          xp: _user!.xp,
          level: _user!.level,
          avatar: _user!.avatar,
          wins: _user!.wins,
          streak: _user!.streak,
          league: _user!.league,
        );
      }
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  Future<bool> changePassword(String oldPassword, String newPassword) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      await apiService.put('/user/password', {
        'oldPassword': oldPassword,
        'newPassword': newPassword,
      });
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  // ==========================================
  // AVATAR UPDATE METHOD
  // ==========================================
  
  Future<bool> updateAvatar(String avatarId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final response = await apiService.put('/user/avatar', {
        'avatar': avatarId,
      });
      
      // Update local user
      if (_user != null) {
        _user = UserModel(
          id: _user!.id,
          username: _user!.username,
          email: _user!.email,
          xp: _user!.xp,
          level: _user!.level,
          avatar: avatarId,
          wins: _user!.wins,
          streak: _user!.streak,
          league: _user!.league,
        );
      }
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  // ==========================================
  // ✅ DELETE ACCOUNT METHOD
  // ==========================================
  
  Future<bool> deleteAccount(String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      await apiService.delete('/user/account', body: {
        'password': password,
      });
      
      // Clear local data after successful deletion
      _user = null;
      _token = null;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.tokenKey);
      await prefs.remove(AppConstants.userIdKey);
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}