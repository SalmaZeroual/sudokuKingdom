import 'package:flutter/material.dart';
import 'dart:async';
import '../models/game_model.dart';
import '../models/booster_model.dart';
import '../services/api_service.dart';

class GameProvider with ChangeNotifier {
  GameModel? _currentGame;
  List<List<int>> _playerGrid = [];
  List<List<bool>> _initialCells = [];
  List<List<bool>> _errorCells = [];
  List<List<Set<int>>> _notes = []; // NOUVEAU : Notes pour chaque case
  
  Timer? _timer;
  Timer? _autoSaveTimer;
  int _elapsedSeconds = 0;
  int _mistakes = 0;
  bool _isCompleted = false;
  bool _isLoading = false;
  bool _isNoteMode = false; // NOUVEAU : Mode notes activé/désactivé
  
  List<BoosterModel> _boosters = [];
  String? _selectedBooster;
  
  final ApiService _apiService = ApiService();
  
  // Getters
  GameModel? get currentGame => _currentGame;
  List<List<int>> get playerGrid => _playerGrid;
  List<List<bool>> get initialCells => _initialCells;
  List<List<bool>> get errorCells => _errorCells;
  List<List<Set<int>>> get notes => _notes;
  int get elapsedSeconds => _elapsedSeconds;
  int get mistakes => _mistakes;
  bool get isCompleted => _isCompleted;
  bool get isLoading => _isLoading;
  bool get isNoteMode => _isNoteMode;
  List<BoosterModel> get boosters => _boosters;
  String? get selectedBooster => _selectedBooster;
  
  String get formattedTime {
    final hours = _elapsedSeconds ~/ 3600;
    final minutes = (_elapsedSeconds % 3600) ~/ 60;
    final seconds = _elapsedSeconds % 60;
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
  
  // Toggle note mode
  void toggleNoteMode() {
    _isNoteMode = !_isNoteMode;
    notifyListeners();
  }
  
  // Check for active game on startup
  Future<bool> checkForActiveGame() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      final response = await _apiService.get('/game/active');
      
      if (response['game'] != null) {
        _currentGame = GameModel.fromJson(response['game']);
        _playerGrid = _currentGame!.grid.map((row) => List<int>.from(row)).toList();
        _initialCells = List.generate(9, (i) => List.generate(9, (j) => _currentGame!.grid[i][j] != 0));
        _errorCells = List.generate(9, (i) => List.generate(9, (j) => false));
        _notes = List.generate(9, (i) => List.generate(9, (j) => <int>{}));
        _elapsedSeconds = _currentGame!.timeElapsed;
        _mistakes = _currentGame!.mistakes;
        _isCompleted = false;
        
        await loadBoosters();
        
        _isLoading = false;
        notifyListeners();
        return true;
      }
      
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      print('Error checking for active game: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  Future<void> startNewGame(String mode, String difficulty) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      final response = await _apiService.post('/game/start', {
        'mode': mode,
        'difficulty': difficulty,
      });
      
      _currentGame = GameModel.fromJson(response);
      _playerGrid = _currentGame!.grid.map((row) => List<int>.from(row)).toList();
      _initialCells = List.generate(9, (i) => List.generate(9, (j) => _currentGame!.grid[i][j] != 0));
      _errorCells = List.generate(9, (i) => List.generate(9, (j) => false));
      _notes = List.generate(9, (i) => List.generate(9, (j) => <int>{}));
      
      _elapsedSeconds = 0;
      _mistakes = 0;
      _isCompleted = false;
      _isNoteMode = false;
      
      _startTimer();
      _startAutoSave();
      await loadBoosters();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error starting game: $e');
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> loadBoosters() async {
    try {
      final response = await _apiService.get('/game/boosters');
      _boosters = (response as List).map((b) => BoosterModel.fromJson(b)).toList();
      notifyListeners();
    } catch (e) {
      print('Error loading boosters: $e');
    }
  }
  
  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _elapsedSeconds++;
      notifyListeners();
    });
  }
  
  void _startAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _saveProgress();
    });
  }
  
  Future<void> _saveProgress() async {
    if (_currentGame == null || _isCompleted) return;
    
    try {
      await _apiService.post('/game/${_currentGame!.id}/save', {
        'grid': _playerGrid,
        'time_elapsed': _elapsedSeconds,
        'mistakes': _mistakes,
      });
      print('✅ Progress auto-saved');
    } catch (e) {
      print('❌ Error saving progress: $e');
    }
  }
  
  void pauseGame() {
    _timer?.cancel();
    _autoSaveTimer?.cancel();
    _saveProgress();
    notifyListeners();
  }
  
  void resumeGame() {
    if (_currentGame != null && !_isCompleted) {
      _startTimer();
      _startAutoSave();
      notifyListeners();
    }
  }
  
  // Set cell value or note
  Future<void> setCellValue(int row, int col, int value) async {
    if (_initialCells[row][col] || _isCompleted) return;
    
    if (_isNoteMode) {
      // Mode notes : ajouter/retirer une note
      if (_notes[row][col].contains(value)) {
        _notes[row][col].remove(value);
      } else {
        _notes[row][col].add(value);
      }
    } else {
      // Mode normal : remplir la case
      _playerGrid[row][col] = value;
      
      // Effacer les notes de cette case
      _notes[row][col].clear();
      
      // Check if correct
      if (value != 0 && value != _currentGame!.solution[row][col]) {
        _errorCells[row][col] = true;
        _mistakes++;
        
        Future.delayed(const Duration(seconds: 1), () {
          if (_errorCells.length > row && _errorCells[row].length > col) {
            _errorCells[row][col] = false;
            notifyListeners();
          }
        });
      } else {
        if (_errorCells.length > row && _errorCells[row].length > col) {
          _errorCells[row][col] = false;
        }
      }
      
      // Check if completed
      if (_checkCompletion()) {
        await _completeGame();
      }
    }
    
    notifyListeners();
  }
  
  // Clear cell
  void clearCell(int row, int col) {
    if (_initialCells[row][col] || _isCompleted) return;
    
    _playerGrid[row][col] = 0;
    _notes[row][col].clear();
    _errorCells[row][col] = false;
    
    notifyListeners();
  }
  
  bool _checkCompletion() {
    for (int i = 0; i < 9; i++) {
      for (int j = 0; j < 9; j++) {
        if (_playerGrid[i][j] == 0 || _playerGrid[i][j] != _currentGame!.solution[i][j]) {
          return false;
        }
      }
    }
    return true;
  }
  
  Future<void> _completeGame() async {
    _isCompleted = true;
    _timer?.cancel();
    _autoSaveTimer?.cancel();
    
    try {
      await _apiService.post('/game/${_currentGame!.id}/complete', {
        'time_elapsed': _elapsedSeconds,
        'mistakes': _mistakes,
      });
    } catch (e) {
      print('Error completing game: $e');
    }
    
    notifyListeners();
  }
  
  void selectBooster(String boosterType) {
    _selectedBooster = boosterType;
    notifyListeners();
  }
  
  Future<void> useBooster(String boosterType, {int? row, int? col}) async {
    final booster = _boosters.firstWhere(
      (b) => b.boosterType == boosterType,
      orElse: () => BoosterModel(id: 0, userId: 0, boosterType: boosterType, quantity: 0),
    );
    
    if (booster.quantity <= 0) return;
    
    switch (boosterType) {
      case 'reveal_cell':
        if (row != null && col != null && !_initialCells[row][col]) {
          _playerGrid[row][col] = _currentGame!.solution[row][col];
          _initialCells[row][col] = true;
          _notes[row][col].clear();
        }
        break;
        
      case 'freeze_time':
        _timer?.cancel();
        _autoSaveTimer?.cancel();
        Future.delayed(const Duration(seconds: 5), () {
          _startTimer();
          _startAutoSave();
        });
        break;
        
      case 'swap_cells':
        for (int i = 0; i < 9; i++) {
          for (int j = 0; j < 9; j++) {
            if (!_initialCells[i][j] && 
                _playerGrid[i][j] != 0 && 
                _playerGrid[i][j] != _currentGame!.solution[i][j]) {
              _playerGrid[i][j] = _currentGame!.solution[i][j];
              _notes[i][j].clear();
              break;
            }
          }
        }
        break;
    }
    
    try {
      await _apiService.post('/game/use-booster', {
        'booster_type': boosterType,
      });
      
      final index = _boosters.indexWhere((b) => b.boosterType == boosterType);
      if (index != -1) {
        _boosters[index] = BoosterModel(
          id: _boosters[index].id,
          userId: _boosters[index].userId,
          boosterType: _boosters[index].boosterType,
          quantity: _boosters[index].quantity - 1,
        );
      }
    } catch (e) {
      print('Error using booster: $e');
    }
    
    _selectedBooster = null;
    notifyListeners();
  }
  
  void clearSelection() {
    _selectedBooster = null;
    notifyListeners();
  }
  
  Future<void> abandonGame() async {
    _timer?.cancel();
    _autoSaveTimer?.cancel();
    
    if (_currentGame != null) {
      try {
        await _apiService.post('/game/${_currentGame!.id}/save', {
          'grid': _playerGrid,
          'time_elapsed': _elapsedSeconds,
          'mistakes': _mistakes,
        });
      } catch (e) {
        print('Error saving before abandon: $e');
      }
    }
    
    _currentGame = null;
    _playerGrid = [];
    _initialCells = [];
    _errorCells = [];
    _notes = [];
    _elapsedSeconds = 0;
    _mistakes = 0;
    _isCompleted = false;
    _isNoteMode = false;
    _selectedBooster = null;
    _boosters = [];
    
    notifyListeners();
  }
  
  @override
  void dispose() {
    _timer?.cancel();
    _autoSaveTimer?.cancel();
    super.dispose();
  }
}