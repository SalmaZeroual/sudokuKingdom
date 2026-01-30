import 'package:flutter/material.dart';
import '../models/story_model.dart';
import '../services/api_service.dart';

class StoryProvider with ChangeNotifier {
  List<StoryChapter> _chapters = [];
  bool _isLoading = false;
  
  final ApiService _apiService = ApiService();
  
  List<StoryChapter> get chapters => _chapters;
  bool get isLoading => _isLoading;
  
  Future<void> loadChapters() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final response = await _apiService.get('/story/chapters');
      _chapters = (response as List).map((c) => StoryChapter.fromJson(c)).toList();
      
      _isLoading = false;
      notifyListeners();
    } catch (error) {
      _isLoading = false;
      notifyListeners();
      print('Error loading chapters: $error');
    }
  }
  
  Future<bool> completeChapter(int chapterId) async {
    try {
      await _apiService.post('/story/chapters/$chapterId/complete', {});
      await loadChapters();
      return true;
    } catch (error) {
      print('Error completing chapter: $error');
      return false;
    }
  }
}