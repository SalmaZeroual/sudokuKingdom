import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/constants.dart';
import 'api_service.dart';

// ─── Clés SharedPreferences ──────────────────────────────────────────────────
const _kOfflineGame    = 'offline_current_game';
const _kPendingSync    = 'offline_pending_sync';

class OfflineService {
  OfflineService._();
  static final OfflineService instance = OfflineService._();

  final ApiService _api = ApiService();
  StreamSubscription? _connectivitySub;
  bool _isSyncing = false;

  // ── Vérifier la connectivité RÉELLE ─────────────────────────────────────
  //
  // ❌ Ancien code : Connectivity().checkConnectivity()
  //    → vérifie seulement si l'interface réseau est activée (4G ON = "connecté")
  //    → avec 4G activé mais sans signal, retourne "connecté" par erreur
  //
  // ✅ Nouveau code : on essaie vraiment de joindre le serveur.
  //    Si la requête répond en moins de 4 s → online.
  //    Si timeout ou erreur réseau → offline (peu importe l'état de la 4G).

  Future<bool> isOnline() async {
    // Étape 1 : vérification rapide de l'interface (évite même d'essayer si
    // vraiment aucun réseau — avion, tout désactivé)
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity == ConnectivityResult.none) return false;

    // Étape 2 : vérification RÉELLE en pingant le serveur
    try {
      final uri = Uri.parse('${AppConstants.baseUrl}/health');
      final response = await http
          .get(uri)
          .timeout(const Duration(seconds: 4));
      // Le serveur répond → vraiment en ligne
      return response.statusCode < 500;
    } catch (_) {
      // Timeout, socket error, DNS failure → pas d'internet réel
      return false;
    }
  }

  // ── Écouter les changements réseau → sync automatique ────────────────────

  void startListening() {
    _connectivitySub?.cancel();
    _connectivitySub =
        Connectivity().onConnectivityChanged.listen((result) async {
      if (result != ConnectivityResult.none) {
        debugPrint('🌐 Réseau retrouvé — synchronisation...');
        await syncPending();
      }
    });
  }

  void stopListening() {
    _connectivitySub?.cancel();
    _connectivitySub = null;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // GÉNÉRATION LOCALE DE GRILLE
  // ──────────────────────────────────────────────────────────────────────────

  /// Génère une grille + solution localement selon la difficulté.
  /// Retourne {'grid': [[...]], 'solution': [[...]]}
  Map<String, List<List<int>>> generateLocalGrid(String difficulty) {
    final solution = _generateSolution();
    final grid     = _applyDifficulty(solution, difficulty);
    return {'grid': grid, 'solution': solution};
  }

  List<List<int>> _generateSolution() {
    final grid = List.generate(9, (_) => List.filled(9, 0));
    _fillGrid(grid);
    return grid;
  }

  bool _fillGrid(List<List<int>> grid) {
    final rng = Random();
    for (int row = 0; row < 9; row++) {
      for (int col = 0; col < 9; col++) {
        if (grid[row][col] != 0) continue;

        final nums = List.generate(9, (i) => i + 1)..shuffle(rng);
        for (final num in nums) {
          if (_isValid(grid, row, col, num)) {
            grid[row][col] = num;
            if (_fillGrid(grid)) return true;
            grid[row][col] = 0;
          }
        }
        return false;
      }
    }
    return true;
  }

  bool _isValid(List<List<int>> g, int row, int col, int num) {
    for (int i = 0; i < 9; i++) {
      if (g[row][i] == num || g[i][col] == num) return false;
    }
    final br = (row ~/ 3) * 3, bc = (col ~/ 3) * 3;
    for (int i = 0; i < 3; i++) {
      for (int j = 0; j < 3; j++) {
        if (g[br + i][bc + j] == num) return false;
      }
    }
    return true;
  }

  List<List<int>> _applyDifficulty(
      List<List<int>> solution, String difficulty) {
    final emptyCells = <String, int>{
      'facile':    30,
      'moyen':     40,
      'difficile': 50,
      'extreme':   60,
    }[difficulty] ?? 40;

    final grid = solution.map((r) => List<int>.from(r)).toList();
    final rng  = Random();
    int removed = 0;

    while (removed < emptyCells) {
      final r = rng.nextInt(9);
      final c = rng.nextInt(9);
      if (grid[r][c] != 0) {
        grid[r][c] = 0;
        removed++;
      }
    }
    return grid;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // SAUVEGARDE LOCALE DE LA PARTIE EN COURS
  // ──────────────────────────────────────────────────────────────────────────

  Future<void> saveCurrentGame(Map<String, dynamic> gameData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kOfflineGame, jsonEncode(gameData));
  }

  Future<Map<String, dynamic>?> loadCurrentGame() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kOfflineGame);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> clearCurrentGame() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kOfflineGame);
  }

  // ──────────────────────────────────────────────────────────────────────────
  // FILE D'ATTENTE DE SYNCHRONISATION
  // ──────────────────────────────────────────────────────────────────────────

  /// Ajoute une partie terminée hors-ligne à la file d'attente.
  Future<void> enqueuePendingSync(Map<String, dynamic> completedGame) async {
    final prefs = await SharedPreferences.getInstance();
    final raw   = prefs.getString(_kPendingSync);
    final list  = raw != null
        ? List<Map<String, dynamic>>.from(
            (jsonDecode(raw) as List).map((e) => e as Map<String, dynamic>))
        : <Map<String, dynamic>>[];

    list.add(completedGame);
    await prefs.setString(_kPendingSync, jsonEncode(list));
    debugPrint('📥 Partie en attente de sync (total: ${list.length})');
  }

  Future<List<Map<String, dynamic>>> _getPending() async {
    final prefs = await SharedPreferences.getInstance();
    final raw   = prefs.getString(_kPendingSync);
    if (raw == null) return [];
    try {
      return List<Map<String, dynamic>>.from(
          (jsonDecode(raw) as List).map((e) => e as Map<String, dynamic>));
    } catch (_) {
      return [];
    }
  }

  Future<void> _clearPending() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kPendingSync);
  }

  Future<int> pendingCount() async {
    return (await _getPending()).length;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // SYNCHRONISATION
  // ──────────────────────────────────────────────────────────────────────────

  /// Envoie toutes les parties hors-ligne au backend.
  /// Retourne le nombre de parties synchronisées.
  Future<int> syncPending() async {
    if (_isSyncing) return 0;
    _isSyncing = true;

    try {
      final pending = await _getPending();
      if (pending.isEmpty) return 0;

      if (!await isOnline()) return 0;

      debugPrint('🔄 Synchronisation de ${pending.length} partie(s)...');

      final response = await _api.post('/game/sync-offline', {
        'games': pending,
      });

      final synced = (response['synced'] as int?) ?? pending.length;
      debugPrint('✅ $synced partie(s) synchronisée(s)');

      await _clearPending();
      return synced;
    } catch (e) {
      debugPrint('❌ Sync error: $e');
      return 0;
    } finally {
      _isSyncing = false;
    }
  }
}