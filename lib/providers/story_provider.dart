import 'package:flutter/material.dart';
import '../models/story_model.dart';
import '../services/api_service.dart';

class StoryProvider with ChangeNotifier {
  List<KingdomModel> _kingdoms = [];
  List<StoryChapter> _chapters = [];
  List<int> _collectedArtifacts = [];
  StoryStatsModel _stats = StoryStatsModel();
  bool _isLoading = false;
  String? _errorMessage;
  
  final ApiService _apiService = ApiService();
  
  // Getters
  List<KingdomModel> get kingdoms => _kingdoms;
  List<StoryChapter> get chapters => _chapters;
  List<int> get collectedArtifacts => _collectedArtifacts;
  StoryStatsModel get stats => _stats;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  // ==========================================
  // LOAD KINGDOMS - Charger tous les royaumes
  // ==========================================
  
  Future<void> loadKingdoms() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final response = await _apiService.get('/story/kingdoms');
      
      _kingdoms = (response['kingdoms'] as List)
          .map((k) => KingdomModel.fromJson(k))
          .toList();
      
      _collectedArtifacts = List<int>.from(response['artifacts'] ?? []);
      _stats = StoryStatsModel.fromJson(response['stats']);
      
      _isLoading = false;
      notifyListeners();
    } catch (error) {
      _errorMessage = error.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      print('Error loading kingdoms: $error');
    }
  }
  
  // ==========================================
  // LOAD CHAPTERS - Charger les chapitres d'un royaume
  // ==========================================
  
  Future<void> loadChapters(int kingdomId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final response = await _apiService.get('/story/chapters?kingdomId=$kingdomId');
      
      _chapters = (response as List)
          .map((c) => StoryChapter.fromJson(c))
          .toList();
      
      _isLoading = false;
      notifyListeners();
    } catch (error) {
      _errorMessage = error.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      print('Error loading chapters: $error');
    }
  }
  
  // ==========================================
  // GET CHAPTER DETAILS - Détails d'un chapitre
  // ==========================================
  
  Future<StoryChapter?> getChapterDetails(int chapterId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final response = await _apiService.get('/story/chapters/$chapterId');
      
      final chapter = StoryChapter.fromJson(response);
      
      _isLoading = false;
      notifyListeners();
      
      return chapter;
    } catch (error) {
      _errorMessage = error.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      print('Error getting chapter details: $error');
      return null;
    }
  }
  
  // ==========================================
  // COMPLETE CHAPTER - Terminer un chapitre
  // ==========================================
  
  Future<Map<String, dynamic>?> completeChapter(
    int chapterId, 
    int timeTaken, 
    int mistakes,
  ) async {
    try {
      final response = await _apiService.post('/story/chapters/$chapterId/complete', {
        'time_taken': timeTaken,
        'mistakes': mistakes,
      });
      
      // Reload kingdoms and chapters to update progress
      await loadKingdoms();
      
      return {
        'success': response['success'],
        'stars': response['stars'],
        'xp_reward': response['xp_reward'],
        'artifact': response['artifact'],
        'kingdom_completed': response['kingdom_completed'],
      };
    } catch (error) {
      print('Error completing chapter: $error');
      return null;
    }
  }
  
  // ==========================================
  // HELPER METHODS
  // ==========================================
  
  KingdomModel? getKingdomById(int kingdomId) {
    try {
      return _kingdoms.firstWhere((k) => k.id == kingdomId);
    } catch (e) {
      return null;
    }
  }
  
  StoryChapter? getChapterById(int chapterId) {
    try {
      return _chapters.firstWhere((c) => c.id == chapterId);
    } catch (e) {
      return null;
    }
  }
  
  bool hasArtifact(int artifactId) {
    return _collectedArtifacts.contains(artifactId);
  }
  
  List<ArtifactModel> getKingdomArtifacts(int kingdomId) {
    final allArtifacts = ArtifactModel.getAllArtifacts();
    return allArtifacts
        .where((a) => a.kingdomId == kingdomId)
        .map((a) => ArtifactModel(
              id: a.id,
              name: a.name,
              icon: a.icon,
              kingdomId: a.kingdomId,
              description: a.description,
              collected: hasArtifact(a.id),
            ))
        .toList();
  }
  
  int getUnlockedKingdomsCount() {
    return _kingdoms.where((k) => k.unlocked).length;
  }
  
  int getCompletedKingdomsCount() {
    return _kingdoms.where((k) => k.isCompleted).length;
  }
  
  double getOverallProgress() {
    if (_kingdoms.isEmpty) return 0.0;
    
    int totalCompleted = 0;
    int totalChapters = 0;
    
    for (final kingdom in _kingdoms) {
      totalCompleted += kingdom.completedChapters;
      totalChapters += kingdom.totalChapters;
    }
    
    return totalChapters > 0 ? totalCompleted / totalChapters : 0.0;
  }
  
  // ==========================================
  // INITIALIZE CHAPTERS (Admin function)
  // ==========================================
  
  Future<bool> initializeChapters() async {
    try {
      final response = await _apiService.post('/story/initialize', {});
      print('Initialize response: $response');
      return response['success'] ?? false;
    } catch (error) {
      print('Error initializing chapters: $error');
      return false;
    }
  }
  
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}