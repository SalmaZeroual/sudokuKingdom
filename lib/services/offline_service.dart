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
// ✅ NOUVEAU : file d'attente dédiée aux chapitres Énigme terminés hors-ligne.
// Une partie classique et un chapitre d'Énigme ne se synchronisent pas de
// la même façon (récompenses différentes : étoiles, artefacts...), donc on
// les garde séparés plutôt que de forcer le chapitre dans le format
// "games" utilisé par /game/sync-offline.
const _kPendingChapters = 'offline_pending_chapters';

class OfflineService {
  OfflineService._();
  static final OfflineService instance = OfflineService._();

  final ApiService _api = ApiService();
  StreamSubscription? _connectivitySub;
  bool _isSyncing = false;

  // ✅ NOUVEAU : registre de callbacks à rappeler dès que la connexion
  // revient. Corrige le bug où un écran (Amis, Messages, Énigme) qui avait
  // échoué à charger une fois UNE SEULE FOIS (au premier passage sur
  // l'onglet, ces écrans ne sont créés qu'une fois pour toute la session)
  // restait bloqué sur "Pas de connexion" pour le reste de la session,
  // même longtemps après le retour du réseau, puisque rien ne déclenchait
  // de nouvel essai automatique.
  static final List<Future<void> Function()> _reconnectCallbacks = [];

  static void registerReconnectCallback(Future<void> Function() callback) {
    _reconnectCallbacks.add(callback);
  }

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
      if (result == ConnectivityResult.none) return;

      // ✅ On vérifie la connexion RÉELLE (pas juste l'état de l'interface
      // réseau) avant de relancer quoi que ce soit — sinon "wifi activé
      // mais sans accès internet réel" déclencherait quand même un essai.
      if (!await isOnline()) return;

      debugPrint('🌐 Réseau retrouvé — synchronisation...');
      await syncPending();
      await syncPendingChapters(); // chapitres Énigme en attente

      // ✅ NOUVEAU : on redonne leur chance aux écrans qui étaient restés
      // bloqués sur "Pas de connexion" (Amis, Messages, Énigme...).
      for (final callback in _reconnectCallbacks) {
        try {
          await callback();
        } catch (e) {
          debugPrint('Erreur callback de reconnexion: $e');
        }
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

  // ✅ Bug corrigé : avant, UN SEUL emplacement de sauvegarde existait pour
  // toute l'app. Du coup, commencer une partie en "Moyen" pendant qu'une
  // partie "Facile" était en cours écrasait la sauvegarde de celle-ci — en
  // revenant sur "Facile" plus tard, elle avait disparu. Idem pour les
  // chapitres Énigme. Maintenant chaque (mode, difficulté) ou (story,
  // chapitre) a son propre emplacement, sous une seule clé SharedPreferences
  // (une map JSON) pour rester simple et économe en appels disque.

  String _slotKey(String? mode, String? difficulty, int? chapterId) {
    if (mode == 'story') return 'story:${chapterId ?? 0}';
    return '${mode ?? 'classic'}:${difficulty ?? 'moyen'}';
  }

  Future<Map<String, dynamic>> _loadAllSlots() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kOfflineGame);
    if (raw == null) return {};
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : {};
    } catch (_) {
      return {};
    }
  }

  Future<void> _saveAllSlots(Map<String, dynamic> slots) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kOfflineGame, jsonEncode(slots));
  }

  Future<void> saveCurrentGame(Map<String, dynamic> gameData) async {
    final slots = await _loadAllSlots();
    final key = _slotKey(
      gameData['mode'] as String?,
      gameData['difficulty'] as String?,
      gameData['chapter_id'] as int?,
    );
    slots[key] = {
      ...gameData,
      'saved_at': DateTime.now().toIso8601String(),
    };
    await _saveAllSlots(slots);
  }

  /// Si [mode] (et [difficulty] / [chapterId]) sont précisés, retourne
  /// uniquement la sauvegarde de cet emplacement précis. Sinon, retourne la
  /// sauvegarde la plus récente toutes difficultés/chapitres confondus
  /// (utile au démarrage de l'app, avant de savoir ce que l'utilisateur va
  /// choisir).
  Future<Map<String, dynamic>?> loadCurrentGame({
    String? mode,
    String? difficulty,
    int? chapterId,
  }) async {
    final slots = await _loadAllSlots();
    if (slots.isEmpty) return null;

    if (mode != null) {
      final key = _slotKey(mode, difficulty, chapterId);
      final data = slots[key];
      return data is Map<String, dynamic> ? data : null;
    }

    // Pas de filtre : on prend la sauvegarde la plus récente.
    Map<String, dynamic>? mostRecent;
    DateTime? mostRecentDate;
    for (final value in slots.values) {
      if (value is! Map<String, dynamic>) continue;
      final savedAt = DateTime.tryParse(value['saved_at']?.toString() ?? '');
      if (mostRecentDate == null || (savedAt != null && savedAt.isAfter(mostRecentDate))) {
        mostRecent = value;
        mostRecentDate = savedAt;
      }
    }
    return mostRecent;
  }

  /// Supprime uniquement l'emplacement précisé. Sans argument, supprime
  /// TOUTES les sauvegardes (à utiliser avec prudence).
  Future<void> clearCurrentGame({
    String? mode,
    String? difficulty,
    int? chapterId,
  }) async {
    if (mode == null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kOfflineGame);
      return;
    }
    final slots = await _loadAllSlots();
    slots.remove(_slotKey(mode, difficulty, chapterId));
    await _saveAllSlots(slots);
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

  // ── File d'attente spécifique aux chapitres Énigme ──────────────────────

  /// Met en attente un chapitre terminé hors-ligne (XP, étoiles, artefact
  /// non perdus : ils seront crédités dès le retour de connexion).
  Future<void> enqueuePendingChapterCompletion({
    required int chapterId,
    required int timeTaken,
    required int mistakes,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kPendingChapters);
    final list = raw != null
        ? List<Map<String, dynamic>>.from(
            (jsonDecode(raw) as List).map((e) => e as Map<String, dynamic>))
        : <Map<String, dynamic>>[];

    list.add({
      'chapter_id': chapterId,
      'time_taken': timeTaken,
      'mistakes': mistakes,
      'queued_at': DateTime.now().toIso8601String(),
    });
    await prefs.setString(_kPendingChapters, jsonEncode(list));
    debugPrint('📥 Chapitre Énigme en attente de sync (total: ${list.length})');
  }

  Future<List<Map<String, dynamic>>> _getPendingChapters() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kPendingChapters);
    if (raw == null) return [];
    try {
      return List<Map<String, dynamic>>.from(
          (jsonDecode(raw) as List).map((e) => e as Map<String, dynamic>));
    } catch (_) {
      return [];
    }
  }

  Future<void> _savePendingChapters(List<Map<String, dynamic>> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPendingChapters, jsonEncode(list));
  }

  Future<int> pendingChaptersCount() async {
    return (await _getPendingChapters()).length;
  }

  /// Envoie les chapitres Énigme terminés hors-ligne, un par un (l'API
  /// /story/chapters/:id/complete ne gère qu'un chapitre à la fois). Les
  /// envois réussis sont retirés de la file ; en cas d'échec (toujours
  /// hors-ligne), on arrête et on réessaiera plus tard.
  Future<int> syncPendingChapters() async {
    final pending = await _getPendingChapters();
    if (pending.isEmpty) return 0;
    if (!await isOnline()) return 0;

    int synced = 0;
    final remaining = <Map<String, dynamic>>[];

    for (final item in pending) {
      try {
        await _api.post('/story/chapters/${item['chapter_id']}/complete', {
          'time_taken': item['time_taken'],
          'mistakes': item['mistakes'],
        });
        synced++;
      } catch (e) {
        debugPrint('❌ Sync chapitre ${item['chapter_id']} échouée: $e');
        remaining.add(item); // on réessaiera plus tard
      }
    }

    await _savePendingChapters(remaining);
    if (synced > 0) {
      debugPrint('✅ $synced chapitre(s) Énigme synchronisé(s)');
    }
    return synced;
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