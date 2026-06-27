import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/story_model.dart';
import '../services/api_service.dart';
import '../services/offline_service.dart';

// ✅ NOUVEAU : clés de cache local. Permettent de continuer à PARCOURIR et
// JOUER les royaumes/chapitres déjà vus même sans connexion (avant, toute
// la section Énigme redevenait inutilisable hors-ligne, y compris pour du
// contenu déjà téléchargé).
const _kCachedKingdoms = 'cached_story_kingdoms';
const _kCachedChaptersPrefix = 'cached_story_chapters_';

class StoryProvider with ChangeNotifier {
  StoryProvider() {
    // ✅ Même correction : l'Énigme se redonne une chance de charger les
    // royaumes dès le retour réel du réseau, au lieu de rester bloquée sur
    // "Pas de connexion" pour le reste de la session.
    OfflineService.registerReconnectCallback(() async {
      if (_isOffline) await loadKingdoms();
    });
  }

  List<KingdomModel> _kingdoms = [];
  List<StoryChapter> _chapters = [];
  List<int> _collectedArtifacts = [];
  StoryStatsModel _stats = StoryStatsModel();
  bool _isLoading = false;
  String? _errorMessage;
  // ✅ NOUVEAU : pas de connexion (≠ vraiment aucun royaume/chapitre)
  bool _isOffline = false;
  
  final ApiService _apiService = ApiService();
  
  // Getters
  List<KingdomModel> get kingdoms => _kingdoms;
  List<StoryChapter> get chapters => _chapters;
  List<int> get collectedArtifacts => _collectedArtifacts;
  StoryStatsModel get stats => _stats;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isOffline => _isOffline;
  
  // ==========================================
  // LOAD KINGDOMS - Charger tous les royaumes
  // ==========================================
  
  Future<void> loadKingdoms() async {
    _isLoading = true;
    _errorMessage = null;
    _isOffline = false;
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

      // ✅ On garde une copie locale pour pouvoir naviguer hors-ligne.
      await _cacheKingdoms(response);
    } catch (error) {
      // ✅ Bug corrigé : avant, une coupure réseau rendait toute la section
      // Énigme illisible (erreur générique, liste vide). On retombe
      // maintenant sur la dernière liste de royaumes connue localement,
      // avec un indicateur clair "Pas de connexion" plutôt qu'une erreur.
      if (error is ApiException && error.isOffline) {
        _isOffline = true;
        final cached = await _loadCachedKingdoms();
        if (cached != null) {
          _kingdoms = (cached['kingdoms'] as List)
              .map((k) => KingdomModel.fromJson(k))
              .toList();
          _collectedArtifacts = List<int>.from(cached['artifacts'] ?? []);
          _stats = StoryStatsModel.fromJson(cached['stats']);
        }
      } else {
        _errorMessage = error.toString().replaceAll('Exception: ', '');
      }
      _isLoading = false;
      notifyListeners();
      print('Error loading kingdoms: $error');
    }
  }

  Future<void> _cacheKingdoms(Map<String, dynamic> response) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kCachedKingdoms, jsonEncode(response));
  }

  Future<Map<String, dynamic>?> _loadCachedKingdoms() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kCachedKingdoms);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
  
  // ==========================================
  // LOAD CHAPTERS - Charger les chapitres d'un royaume
  // ==========================================
  
  Future<void> loadChapters(int kingdomId) async {
    _isLoading = true;
    _errorMessage = null;
    _isOffline = false;
    notifyListeners();
    
    try {
      final response = await _apiService.get('/story/chapters?kingdomId=$kingdomId');
      
      _chapters = (response as List)
          .map((c) => StoryChapter.fromJson(c))
          .toList();
      
      _isLoading = false;
      notifyListeners();

      // ✅ Copie locale par royaume, pour pouvoir rejouer un chapitre déjà
      // vu (et sa grille) même sans connexion.
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_kCachedChaptersPrefix$kingdomId', jsonEncode(response));
    } catch (error) {
      if (error is ApiException && error.isOffline) {
        _isOffline = true;
        final prefs = await SharedPreferences.getInstance();
        final raw = prefs.getString('$_kCachedChaptersPrefix$kingdomId');
        if (raw != null) {
          try {
            _chapters = (jsonDecode(raw) as List)
                .map((c) => StoryChapter.fromJson(c))
                .toList();
          } catch (_) {}
        }
      } else {
        _errorMessage = error.toString().replaceAll('Exception: ', '');
      }
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
      // ✅ Bug corrigé : avant, terminer un chapitre hors-ligne perdait
      // silencieusement la progression (XP, étoiles, artefact) — l'appel
      // échouait et on faisait juste un print(). Maintenant, si c'est bien
      // un problème de connexion, on met le résultat en attente : il sera
      // automatiquement envoyé au serveur dès le retour du réseau, sans
      // que l'utilisateur ait à refaire le chapitre.
      if (error is ApiException && error.isOffline) {
        await OfflineService.instance.enqueuePendingChapterCompletion(
          chapterId: chapterId,
          timeTaken: timeTaken,
          mistakes: mistakes,
        );
        print('📥 Chapitre terminé hors-ligne, mis en attente de synchronisation');
        return {
          'success': true,
          'offline': true,
          'stars': null,
          'xp_reward': null,
          'artifact': null,
          'kingdom_completed': false,
        };
      }
      print('Error completing chapter: $error');
      return null;
    }
  }

  // ✅ NOUVEAU : à appeler au démarrage de l'app ou quand le réseau revient,
  // pour créditer les chapitres terminés hors-ligne en attente.
  Future<int> syncPendingChapters() async {
    final synced = await OfflineService.instance.syncPendingChapters();
    if (synced > 0) {
      await loadKingdoms();
    }
    return synced;
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