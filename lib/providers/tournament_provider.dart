import 'package:flutter/material.dart';
import '../models/tournament_model.dart';
import '../services/api_service.dart';

class TournamentProvider with ChangeNotifier {
  List<TournamentModel> _tournaments = [];
  TournamentModel? _activeTournament;
  List<TournamentParticipation> _leaderboard = [];
  
  bool _isLoading = false;
  
  final ApiService _apiService = ApiService();
  
  // Getters
  List<TournamentModel> get tournaments => _tournaments;
  TournamentModel? get activeTournament => _activeTournament;
  List<TournamentParticipation> get leaderboard => _leaderboard;
  bool get isLoading => _isLoading;
  
  Future<void> loadTournaments() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final response = await _apiService.get('/tournament/list');
      _tournaments = (response as List).map((t) => TournamentModel.fromJson(t)).toList();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      print('Error loading tournaments: $e');
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
    }
  }
  
  Future<void> loadLeaderboard(int tournamentId) async {
    try {
      final response = await _apiService.get('/tournament/$tournamentId/leaderboard');
      _leaderboard = (response as List).map((p) => TournamentParticipation.fromJson(p)).toList();
      notifyListeners();
    } catch (e) {
      print('Error loading leaderboard: $e');
    }
  }
  
  Future<bool> joinTournament(int tournamentId) async {
    try {
      await _apiService.post('/tournament/$tournamentId/join', {});
      await loadTournamentDetails(tournamentId);
      return true;
    } catch (e) {
      print('Error joining tournament: $e');
      return false;
    }
  }
  
  Future<void> submitScore(int tournamentId, int score, int time) async {
    try {
      await _apiService.post('/tournament/$tournamentId/submit', {
        'score': score,
        'time': time,
      });
      
      await loadLeaderboard(tournamentId);
    } catch (e) {
      print('Error submitting score: $e');
    }
  }
}