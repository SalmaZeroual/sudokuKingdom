import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SavedAccount {
  final int userId;
  final String email;
  final String username;
  final String avatar;
  final String? savedPassword; // null = pas sauvegardé
  final DateTime lastLogin;

  SavedAccount({
    required this.userId,
    required this.email,
    required this.username,
    required this.avatar,
    this.savedPassword,
    required this.lastLogin,
  });

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'email': email,
        'username': username,
        'avatar': avatar,
        'savedPassword': savedPassword,
        'lastLogin': lastLogin.toIso8601String(),
      };

  factory SavedAccount.fromJson(Map<String, dynamic> json) => SavedAccount(
        userId: json['userId'],
        email: json['email'],
        username: json['username'],
        avatar: json['avatar'] ?? 'default',
        savedPassword: json['savedPassword'],
        lastLogin: DateTime.parse(json['lastLogin']),
      );

  SavedAccount copyWith({
    String? savedPassword,
    String? username,
    String? avatar,
    DateTime? lastLogin,
  }) =>
      SavedAccount(
        userId: userId,
        email: email,
        username: username ?? this.username,
        avatar: avatar ?? this.avatar,
        savedPassword: savedPassword ?? this.savedPassword,
        lastLogin: lastLogin ?? this.lastLogin,
      );
}

class AccountStorageService {
  static const String _savedAccountsKey = 'saved_accounts';

  /// Récupère tous les comptes sauvegardés, triés par dernière connexion
  Future<List<SavedAccount>> getSavedAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(_savedAccountsKey);
    if (data == null) return [];

    final List<dynamic> list = jsonDecode(data);
    final accounts = list.map((e) => SavedAccount.fromJson(e)).toList();
    accounts.sort((a, b) => b.lastLogin.compareTo(a.lastLogin));
    return accounts;
  }

  /// Sauvegarde ou met à jour un compte après connexion
  Future<void> saveAccount(SavedAccount account) async {
    final prefs = await SharedPreferences.getInstance();
    final accounts = await getSavedAccounts();

    // Remplacer si existe déjà (même email)
    accounts.removeWhere((a) => a.email == account.email);
    accounts.insert(0, account);

    await prefs.setString(
      _savedAccountsKey,
      jsonEncode(accounts.map((a) => a.toJson()).toList()),
    );
  }

  /// Met à jour le mot de passe sauvegardé d'un compte
  Future<void> updateSavedPassword(String email, String? password) async {
    final prefs = await SharedPreferences.getInstance();
    final accounts = await getSavedAccounts();

    final idx = accounts.indexWhere((a) => a.email == email);
    if (idx == -1) return;

    accounts[idx] = accounts[idx].copyWith(savedPassword: password);

    await prefs.setString(
      _savedAccountsKey,
      jsonEncode(accounts.map((a) => a.toJson()).toList()),
    );
  }

  /// Supprime un compte de la liste sauvegardée
  Future<void> removeAccount(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final accounts = await getSavedAccounts();
    accounts.removeWhere((a) => a.email == email);

    await prefs.setString(
      _savedAccountsKey,
      jsonEncode(accounts.map((a) => a.toJson()).toList()),
    );
  }

  /// Vérifie si c'est la première fois qu'on se connecte avec cet email
  Future<bool> isFirstLoginForEmail(String email) async {
    final accounts = await getSavedAccounts();
    return !accounts.any((a) => a.email == email);
  }
}