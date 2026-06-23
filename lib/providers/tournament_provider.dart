import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/tournament_model.dart';
import '../services/api_service.dart';

class TournamentProvider with ChangeNotifier {
  List<TournamentModel> _tournaments = [];
  TournamentModel? _activeTournament;
  List<TournamentParticipation> _leaderboard = [];
  List<TournamentParticipation> _friendsLeaderboard = [];
  Set<int> _joinedTournamentIds = {};

  bool _isLoading = false;
  bool _isLeaderboardLoading = false;

  // Type de classement affiché : 'global' ou 'friends'
  String _leaderboardType = 'global';

  final ApiService _apiService = ApiService();

  // ─── Getters ─────────────────────────────────
  List<TournamentModel> get tournaments => _tournaments;
  TournamentModel? get activeTournament => _activeTournament;
  bool get isLoading => _isLoading;
  bool get isLeaderboardLoading => _isLeaderboardLoading;
  String get leaderboardType => _leaderboardType;

  /// Retourne le classement actif selon le type sélectionné
  List<TournamentParticipation> get leaderboard =>
      _leaderboardType == 'friends' ? _friendsLeaderboard : _leaderboard;

  TournamentProvider() {
    _loadJoinedTournaments();
  }

  // ─── Helpers ─────────────────────────────────

  TournamentModel? getTournamentByDifficulty(String difficulty) {
    try {
      return _tournaments.firstWhere(
        (t) => t.difficulty.toLowerCase() == difficulty.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }

  bool hasJoinedTournament(int tournamentId) =>
      _joinedTournamentIds.contains(tournamentId);

  List<TournamentParticipation> getTop3() =>
      leaderboard.length >= 3 ? leaderboard.take(3).toList() : leaderboard;

  TournamentParticipation? getCurrentUserParticipation(int userId) {
    try {
      return leaderboard.firstWhere((p) => p.userId == userId);
    } catch (_) {
      return null;
    }
  }

  TournamentModel? getTournamentById(int id) {
    try {
      return _tournaments.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  // ─── Leaderboard type toggle ──────────────────

  void setLeaderboardType(String type) {
    assert(type == 'global' || type == 'friends');
    if (_leaderboardType == type) return;
    _leaderboardType = type;
    notifyListeners();
  }

  // ─── Local storage ────────────────────────────

  Future<void> _loadJoinedTournaments() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final joinedIds = prefs.getStringList('joined_tournaments') ?? [];
      _joinedTournamentIds = joinedIds.map((id) => int.parse(id)).toSet();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading joined tournaments: $e');
    }
  }

  Future<void> _saveJoinedTournaments() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        'joined_tournaments',
        _joinedTournamentIds.map((id) => id.toString()).toList(),
      );
    } catch (e) {
      debugPrint('Error saving joined tournaments: $e');
    }
  }

  // ─── API calls ────────────────────────────────

  Future<void> loadTournaments() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.get('/tournament/list');
      _tournaments = (response as List)
          .map((t) => TournamentModel.fromJson(t))
          .toList();

      // ✅ Synchroniser les IDs rejoints depuis le serveur
      // (évite les désynchronisations après redémarrage de l'appli
      // ou passage au lendemain avec de nouveaux IDs de tournois)
      for (final t in _tournaments) {
        if (t.userHasJoined) {
          _joinedTournamentIds.add(t.id);
        }
      }
      await _saveJoinedTournaments();
    } catch (e) {
      debugPrint('Error loading tournaments: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadTournamentDetails(int tournamentId) async {
    try {
      final response = await _apiService.get('/tournament/$tournamentId');
      _activeTournament = TournamentModel.fromJson(response);
      await loadLeaderboard(tournamentId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading tournament details: $e');
      rethrow;
    }
  }

  /// Charge les deux classements (global + amis) indépendamment.
  /// ✅ Les deux appels sont séparés : si le classement Amis échoue,
  /// le classement Mondial s'affiche quand même (et inversement).
  Future<void> loadLeaderboard(int tournamentId) async {
    _isLeaderboardLoading = true;
    notifyListeners();

    try {
      // ── Classement mondial ─────────────────────────────────────────
      try {
        final globalResult = await _apiService
            .get('/tournament/$tournamentId/leaderboard?type=global');
        _leaderboard = (globalResult as List)
            .map((p) => TournamentParticipation.fromJson(p))
            .toList();
      } catch (e) {
        debugPrint('Error loading global leaderboard: $e');
        // On garde l'ancienne valeur ou une liste vide — pas de crash
        _leaderboard = _leaderboard.isEmpty ? [] : _leaderboard;
      }

      // ── Classement amis ────────────────────────────────────────────
      try {
        final friendsResult = await _apiService
            .get('/tournament/$tournamentId/leaderboard?type=friends');
        _friendsLeaderboard = (friendsResult as List)
            .map((p) => TournamentParticipation.fromJson(p))
            .toList();
      } catch (e) {
        debugPrint('Error loading friends leaderboard: $e');
        _friendsLeaderboard =
            _friendsLeaderboard.isEmpty ? [] : _friendsLeaderboard;
      }
    } finally {
      _isLeaderboardLoading = false;
      notifyListeners();
    }
  }

  Future<bool> joinTournament(int tournamentId) async {
    try {
      await _apiService.post('/tournament/$tournamentId/join', {});
      _joinedTournamentIds.add(tournamentId);
      await _saveJoinedTournaments();
      await loadTournamentDetails(tournamentId);
      await loadTournaments();
      return true;
    } catch (e) {
      final msg = e.toString().toLowerCase();
      // ✅ Si le joueur a déjà rejoint (redémarrage appli, ancien cache, etc.),
      // on le marque simplement comme "joined" et on continue sans erreur.
      if (msg.contains('already') || msg.contains('400')) {
        _joinedTournamentIds.add(tournamentId);
        await _saveJoinedTournaments();
        await loadTournamentDetails(tournamentId);
        await loadTournaments();
        return true;
      }
      debugPrint('Error joining tournament: $e');
      return false;
    }
  }

  Future<bool> submitScore(int tournamentId, int score, int time) async {
    try {
      await _apiService.post('/tournament/$tournamentId/submit', {
        'score': score,
        'time': time,
      });
      await loadLeaderboard(tournamentId);
      return true;
    } catch (e) {
      debugPrint('Error submitting score: $e');
      return false;
    }
  }

  void clear() {
    _tournaments = [];
    _activeTournament = null;
    _leaderboard = [];
    _friendsLeaderboard = [];
    notifyListeners();
  }
}