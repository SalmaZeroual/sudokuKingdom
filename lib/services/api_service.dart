import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/constants.dart';

// ✅ NOUVEAU : exception structurée. Avant, _handleResponse perdait
// systématiquement le vrai message d'erreur du serveur (voir bug ci-dessous)
// et tout le code appelant devait deviner la cause via le texte. Maintenant
// on garde le code HTTP + le corps JSON complet, pour pouvoir réagir
// précisément (ex: 403 "Not friends" vs 403 "blocked").
class ApiException implements Exception {
  final int statusCode;
  final String message;
  final Map<String, dynamic>? data;
  // ✅ NOUVEAU : true quand l'échec vient d'un problème de connexion
  // (pas de réseau, timeout) et non d'une vraie réponse du serveur. Permet
  // d'afficher "Pas de connexion" au lieu de, par exemple, "Aucun ami" /
  // "Aucune conversation" — ce qui laissait croire à tort que les données
  // n'existaient pas.
  final bool isOffline;

  ApiException(this.statusCode, this.message, [this.data, this.isOffline = false]);

  @override
  String toString() => message;
}

// ✅ NOUVEAU : convertit une vraie coupure réseau (pas de connexion, DNS,
// timeout) en ApiException(isOffline: true), pour que tout le code
// appelant puisse réagir de façon uniforme sans avoir à connaître les
// types d'exceptions bas niveau de `http`/`dart:io`.
ApiException _normalizeNetworkError(Object e) {
  if (e is SocketException || e is TimeoutException || e is http.ClientException) {
    return ApiException(0, 'Pas de connexion internet', null, true);
  }
  if (e is ApiException) return e;
  return ApiException(0, e.toString(), null, false);
}

class ApiService {
  final String baseUrl = AppConstants.baseUrl;

  // ✅ Timeout global : si le serveur ne répond pas en 10 s,
  // la requête échoue proprement au lieu de rester bloquée indéfiniment.
  // (Cas typique : 4G activée mais sans signal réel)
  static const _timeout = Duration(seconds: 10);

  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.tokenKey);
    
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }
  
  Future<dynamic> get(String endpoint) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .get(Uri.parse('$baseUrl$endpoint'), headers: headers)
          .timeout(_timeout);
      return _handleResponse(response);
    } catch (e) {
      throw _normalizeNetworkError(e);
    }
  }
  
  Future<dynamic> post(String endpoint, Map<String, dynamic> body) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .post(
            Uri.parse('$baseUrl$endpoint'),
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(_timeout);
      return _handleResponse(response);
    } catch (e) {
      throw _normalizeNetworkError(e);
    }
  }
  
  Future<dynamic> put(String endpoint, Map<String, dynamic> body) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .put(
            Uri.parse('$baseUrl$endpoint'),
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(_timeout);
      return _handleResponse(response);
    } catch (e) {
      throw _normalizeNetworkError(e);
    }
  }

  Future<dynamic> patch(String endpoint, Map<String, dynamic> body) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .patch(
            Uri.parse('$baseUrl$endpoint'),
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(_timeout);
      return _handleResponse(response);
    } catch (e) {
      throw _normalizeNetworkError(e);
    }
  }

  Future<dynamic> delete(String endpoint, {Map<String, dynamic>? body}) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .delete(
            Uri.parse('$baseUrl$endpoint'),
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(_timeout);
      return _handleResponse(response);
    } catch (e) {
      throw _normalizeNetworkError(e);
    }
  }
  
  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return {};
      return jsonDecode(response.body);
    }

    // ✅ Bug corrigé : avant, le `throw` ci-dessous était DANS le même `try`
    // que celui censé l'attraper, donc le message réel du serveur (ex.
    // "Not friends", "Cet utilisateur a bloqué vos messages") était
    // immédiatement ré-attrapé et remplacé par un générique "Erreur 403".
    // L'utilisateur voyait alors une erreur incompréhensible au lieu du
    // vrai message.
    Map<String, dynamic>? data;
    String message = 'Erreur ${response.statusCode}';
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        data = decoded;
        if (decoded['error'] != null) {
          message = decoded['error'].toString();
        }
      }
    } catch (_) {
      // Corps non-JSON : on garde le message générique ci-dessus.
    }

    throw ApiException(response.statusCode, message, data);
  }
}