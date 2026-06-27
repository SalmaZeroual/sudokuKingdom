import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import '../services/account_storage_service.dart'; // ✅ AJOUTÉ
import '../config/constants.dart';

// ✅ NOUVEAU : clé de cache local du profil utilisateur. Permet de rester
// "connecté" (isAuthenticated/isGuest corrects) même quand le réseau est
// momentanément indisponible, au lieu de retomber à tort en mode invité.
const _kCachedUserKey = 'cached_user_profile';

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
  
  // ✅ GUEST: true si l'utilisateur joue sans compte
  bool get isGuest => !isAuthenticated;

  final ApiService apiService = ApiService();
  final SocketService _socketService = SocketService();
  final AccountStorageService _accountStorage = AccountStorageService(); // ✅ AJOUTÉ

  // ✅ AJOUTÉ : accès rapide aux comptes sauvegardés depuis le provider
  Future<List<SavedAccount>> getSavedAccounts() =>
      _accountStorage.getSavedAccounts();

  Future<void> checkAuthStatus() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(AppConstants.tokenKey);

    if (_token != null) {
      await loadUser();

      // ✅ Bug corrigé : avant, si le réseau était indisponible ICI (par
      // exemple au démarrage de l'app sans connexion), loadUser() échouait
      // silencieusement et _user restait null pour TOUTE la session — même
      // si le jeton stocké était parfaitement valide. isAuthenticated
      // devenait donc faux, et l'app traitait un utilisateur connecté
      // comme un invité, lui proposant de "créer un compte" alors qu'il
      // en a déjà un. On utilise maintenant le profil mis en cache
      // localement comme repli : avoir un jeton stocké + un profil en
      // cache suffit à être considéré comme connecté, même hors-ligne.
      if (_user == null) {
        final cached = prefs.getString(_kCachedUserKey);
        if (cached != null) {
          try {
            _user = UserModel.fromJson(jsonDecode(cached) as Map<String, dynamic>);
            print('📦 Profil chargé depuis le cache local (hors-ligne)');
          } catch (e) {
            print('Error loading cached user: $e');
          }
        }
      }

      if (_user != null) {
        _socketService.connect();
        _socketService.emit('user_online', _user!.id);
      }
    }
    notifyListeners();
  }

  // ✅ NOUVEAU : sauvegarde locale du profil, utilisée comme repli hors-ligne.
  Future<void> _cacheUserProfile() async {
    if (_user == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kCachedUserKey, jsonEncode(_user!.toJson()));
  }

  Future<Map<String, dynamic>> register(
      String username, String email, String password) async {
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

  /// ✅ MODIFIÉ : login sauvegarde maintenant le compte localement
  Future<bool> login(String email, String password,
      {bool savePassword = false}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await apiService.post('/auth/login', {
        'email': email,
        'password': password,
      });

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

      // ✅ AJOUTÉ : Sauvegarder le compte localement
      await _accountStorage.saveAccount(SavedAccount(
        userId: _user!.id,
        email: _user!.email,
        username: _user!.username,
        avatar: _user!.avatar ?? 'default',
        savedPassword: savePassword ? password : null,
        lastLogin: DateTime.now(),
      ));

      _socketService.connect();
      _socketService.emit('user_online', _user!.id);

      // ✅ NOUVEAU : on garde une copie locale du profil pour pouvoir
      // rester "connecté" même si le réseau tombe par la suite.
      await _cacheUserProfile();

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

      _socketService.connect();
      _socketService.emit('user_online', _user!.id);

      // ✅ NOUVEAU
      await _cacheUserProfile();

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
      // ✅ NOUVEAU : on rafraîchit le cache hors-ligne à chaque succès.
      await _cacheUserProfile();
    } catch (e) {
      print('Error loading user: $e');
    }
  }

  /// ✅ MODIFIÉ : logout avec option de garder/supprimer le mot de passe sauvegardé
  Future<void> logout({bool keepPassword = false}) async {
    if (_user != null) {
      _socketService.emit('user_offline', _user!.id);

      // Si l'utilisateur ne veut PAS garder le mot de passe, on l'efface
      if (!keepPassword) {
        await _accountStorage.updateSavedPassword(_user!.email, null);
      }
      // Le compte (email, username, avatar) est toujours gardé pour affichage
    }

    _socketService.disconnect();

    _user = null;
    _token = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.tokenKey);
    await prefs.remove(AppConstants.userIdKey);
    await prefs.remove(_kCachedUserKey); // ✅ NOUVEAU

    notifyListeners();
  }

  /// ✅ AJOUTÉ : supprimer complètement un compte de la liste sauvegardée
  Future<void> removeSavedAccount(String email) async {
    await _accountStorage.removeAccount(email);
    notifyListeners();
  }

  /// ✅ AJOUTÉ : mettre à jour le mot de passe sauvegardé
  Future<void> setSavedPassword(String email, String? password) async {
    await _accountStorage.updateSavedPassword(email, password);
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
      await apiService.post('/auth/forgot-password', {'email': email});
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

  Future<bool> resetPassword(
      String email, String code, String newPassword) async {
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
      await apiService.put('/user/profile', {'username': newUsername});

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
          uniqueId: _user!.uniqueId,
        );
        // ✅ AJOUTÉ : mettre à jour aussi le username dans le compte sauvegardé
        await _accountStorage.saveAccount(SavedAccount(
          userId: _user!.id,
          email: _user!.email,
          username: newUsername,
          avatar: _user!.avatar ?? 'default',
          lastLogin: DateTime.now(),
        ));
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

      // ✅ AJOUTÉ : mettre à jour le mot de passe sauvegardé si existait
      if (_user != null) {
        final accounts = await _accountStorage.getSavedAccounts();
        final saved = accounts.firstWhere(
          (a) => a.email == _user!.email,
          orElse: () => SavedAccount(
            userId: 0,
            email: '',
            username: '',
            avatar: '',
            lastLogin: DateTime.now(),
          ),
        );
        if (saved.savedPassword != null) {
          await _accountStorage.updateSavedPassword(_user!.email, newPassword);
        }
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
  // AVATAR UPDATE METHOD
  // ==========================================

  Future<bool> updateAvatar(String avatarId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await apiService.put('/user/avatar', {'avatar': avatarId});

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
          uniqueId: _user!.uniqueId,
        );
        // ✅ AJOUTÉ : mettre à jour l'avatar dans le compte sauvegardé
        await _accountStorage.saveAccount(SavedAccount(
          userId: _user!.id,
          email: _user!.email,
          username: _user!.username,
          avatar: avatarId,
          lastLogin: DateTime.now(),
        ));
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
  // DELETE ACCOUNT METHOD
  // ==========================================

  Future<bool> deleteAccount(String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await apiService.delete('/user/account', body: {'password': password});

      if (_user != null) {
        _socketService.emit('user_offline', _user!.id);
        // ✅ AJOUTÉ : supprimer aussi des comptes sauvegardés
        await _accountStorage.removeAccount(_user!.email);
      }
      _socketService.disconnect();

      _user = null;
      _token = null;

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.tokenKey);
      await prefs.remove(AppConstants.userIdKey);
      await prefs.remove(_kCachedUserKey); // ✅ NOUVEAU

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