import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/tournament_model.dart';
import '../services/api_service.dart';
import '../config/constants.dart';

class TournamentProvider with ChangeNotifier {
  List<TournamentModel> _tournaments = [];
  TournamentModel? _activeTournament;
  List<TournamentParticipation> _leaderboard = [];
  Set<int> _joinedTournamentIds = {};
  
  bool _isLoading = false;
  
  final ApiService _apiService = ApiService();
  
  // Getters
  List<TournamentModel> get tournaments => _tournaments;
  TournamentModel? get activeTournament => _activeTournament;
  List<TournamentParticipation> get leaderboard => _leaderboard;
  bool get isLoading => _isLoading;
  
  TournamentProvider() {
    _loadJoinedTournaments();
  }
  
  // ✅ NOUVEAU: Get tournament by difficulty
  TournamentModel? getTournamentByDifficulty(String difficulty) {
    try {
      return _tournaments.firstWhere(
        (t) => t.difficulty.toLowerCase() == difficulty.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }
  
  // Check if user has joined a tournament
  bool hasJoinedTournament(int tournamentId) {
    return _joinedTournamentIds.contains(tournamentId);
  }
  
  // Load joined tournaments from local storage
  Future<void> _loadJoinedTournaments() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final joinedIds = prefs.getStringList('joined_tournaments') ?? [];
      _joinedTournamentIds = joinedIds.map((id) => int.parse(id)).toSet();
      notifyListeners();
    } catch (e) {
      print('Error loading joined tournaments: $e');
    }
  }
  
  // Save joined tournaments to local storage
  Future<void> _saveJoinedTournaments() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final joinedIds = _joinedTournamentIds.map((id) => id.toString()).toList();
      await prefs.setStringList('joined_tournaments', joinedIds);
    } catch (e) {
      print('Error saving joined tournaments: $e');
    }
  }
  
  Future<void> loadTournaments() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final response = await _apiService.get('/tournament/list');
      _tournaments = (response as List)
          .map((t) => TournamentModel.fromJson(t))
          .toList();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      print('Error loading tournaments: $e');
      rethrow;
    }
  }
  
  Future<void> loadTournamentDetails(int tournamentId) async {
    try {
      final response = await _apiService.get('/tournament/$tournamentId');
      _activeTournament = TournamentModel.fromJson(response);
      
      await loadLeaderboard(tournamentId);
      notifyListeners();
    } catch (e) {
      print('Error loading tournament details: $e');
      rethrow;
    }
  }
  
  Future<void> loadLeaderboard(int tournamentId) async {
    try {
      final response = await _apiService.get('/tournament/$tournamentId/leaderboard');
      _leaderboard = (response as List)
          .map((p) => TournamentParticipation.fromJson(p))
          .toList();
      notifyListeners();
    } catch (e) {
      print('Error loading leaderboard: $e');
      rethrow;
    }
  }
  
  Future<bool> joinTournament(int tournamentId) async {
    try {
      await _apiService.post('/tournament/$tournamentId/join', {});
      
      // Add to joined tournaments
      _joinedTournamentIds.add(tournamentId);
      await _saveJoinedTournaments();
      
      await loadTournamentDetails(tournamentId);
      await loadTournaments(); // Refresh tournaments list
      
      return true;
    } catch (e) {
      print('Error joining tournament: $e');
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
      print('Error submitting score: $e');
      return false;
    }
  }
  
  // Get tournament by ID
  TournamentModel? getTournamentById(int id) {
    try {
      return _tournaments.firstWhere((t) => t.id == id);
    } catch (e) {
      return null;
    }
  }
  
  // Get top 3 for podium
  List<TournamentParticipation> getTop3() {
    if (_leaderboard.length >= 3) {
      return _leaderboard.take(3).toList();
    }
    return _leaderboard;
  }
  
  // Get current user rank
  TournamentParticipation? getCurrentUserParticipation(int userId) {
    try {
      return _leaderboard.firstWhere((p) => p.userId == userId);
    } catch (e) {
      return null;
    }
  }
  
  // Clear all data
  void clear() {
    _tournaments = [];
    _activeTournament = null;
    _leaderboard = [];
    notifyListeners();
  }
}