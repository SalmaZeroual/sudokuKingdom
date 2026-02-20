import 'package:flutter/material.dart';
import 'dart:async';
import '../models/game_model.dart';
import '../models/booster_model.dart';
import '../services/api_service.dart';

class GameProvider with ChangeNotifier {
  GameModel? _currentGame;
  List<List<int>> _playerGrid = [];
  List<List<int>> _solutionGrid = [];
  List<List<bool>> _initialCells = [];
  List<List<bool>> _errorCells = [];
  List<List<Set<int>>> _notes = [];
  
  Timer? _timer;
  Timer? _autoSaveTimer;
  int _elapsedSeconds = 0;
  int _mistakes = 0;
  bool _isCompleted = false;
  bool _isLoading = false;
  bool _isNoteMode = false;
  bool _isPaused = false;
  
  // ✅ NOUVEAU: Game Over state
  bool _isGameOver = false;
  
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
  bool get isLoading => _isLoading;
  bool get isNoteMode => _isNoteMode;
  bool get isGameOver => _isGameOver; // ✅ NOUVEAU
  List<BoosterModel> get boosters => _boosters;
  String? get selectedBooster => _selectedBooster;
  
  bool get isCompleted {
    for (int i = 0; i < 9; i++) {
      for (int j = 0; j < 9; j++) {
        if (_playerGrid[i][j] == 0) return false;
        
        if (_solutionGrid.isNotEmpty) {
          if (_playerGrid[i][j] != _solutionGrid[i][j]) return false;
        }
      }
    }
    
    if (_solutionGrid.isEmpty) {
      return _validateSudoku();
    }
    
    return true;
  }
  
  String get formattedTime {
    final hours = _elapsedSeconds ~/ 3600;
    final minutes = (_elapsedSeconds % 3600) ~/ 60;
    final seconds = _elapsedSeconds % 60;
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
  
  void toggleNoteMode() {
    _isNoteMode = !_isNoteMode;
    notifyListeners();
  }
  
  // Initialize game for Story Mode
  void initializeStoryGame(List<List<int>> grid, List<List<int>> solution) {
    print('🎮 Initializing story game...');
    print('Grid: ${grid.length}x${grid.isNotEmpty ? grid[0].length : 0}');
    
    _currentGame = null;
    
    _playerGrid = List.generate(9, (i) => List<int>.from(grid[i]));
    _solutionGrid = List.generate(9, (i) => List<int>.from(solution[i]));
    
    _initialCells = List.generate(9, (i) => List.generate(9, (j) => grid[i][j] != 0));
    _errorCells = List.generate(9, (_) => List.generate(9, (_) => false));
    _notes = List.generate(9, (_) => List.generate(9, (_) => <int>{}));
    
    _mistakes = 0;
    _isNoteMode = false;
    _isPaused = false;
    _isGameOver = false; // ✅ NOUVEAU
    
    print('✅ Story game initialized! Grid: ${_playerGrid[0]}');
    notifyListeners();
  }
  
  bool _validateSudoku() {
    for (int i = 0; i < 9; i++) {
      final seen = <int>{};
      for (int j = 0; j < 9; j++) {
        if (_playerGrid[i][j] != 0) {
          if (seen.contains(_playerGrid[i][j])) return false;
          seen.add(_playerGrid[i][j]);
        }
      }
    }
    
    for (int j = 0; j < 9; j++) {
      final seen = <int>{};
      for (int i = 0; i < 9; i++) {
        if (_playerGrid[i][j] != 0) {
          if (seen.contains(_playerGrid[i][j])) return false;
          seen.add(_playerGrid[i][j]);
        }
      }
    }
    
    for (int box = 0; box < 9; box++) {
      final seen = <int>{};
      final startRow = (box ~/ 3) * 3;
      final startCol = (box % 3) * 3;
      
      for (int i = startRow; i < startRow + 3; i++) {
        for (int j = startCol; j < startCol + 3; j++) {
          if (_playerGrid[i][j] != 0) {
            if (seen.contains(_playerGrid[i][j])) return false;
            seen.add(_playerGrid[i][j]);
          }
        }
      }
    }
    
    return true;
  }
  
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
        _isGameOver = false; // ✅ NOUVEAU
        
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
      _isGameOver = false; // ✅ NOUVEAU
      
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
    if (_currentGame == null || _isCompleted || _isGameOver) return;
    
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
    if (_currentGame != null && !_isCompleted && !_isGameOver) {
      _startTimer();
      _startAutoSave();
      notifyListeners();
    }
  }
  
  Future<void> setCellValue(int row, int col, int value) async {
    if (_initialCells[row][col] || _isCompleted || _isGameOver) return; // ✅ Bloquer si game over
    
    if (_isNoteMode) {
      if (_notes[row][col].contains(value)) {
        _notes[row][col].remove(value);
      } else {
        _notes[row][col].add(value);
      }
    } else {
      _playerGrid[row][col] = value;
      _notes[row][col].clear();
      
      int correctValue = _solutionGrid.isNotEmpty 
          ? _solutionGrid[row][col] 
          : _currentGame!.solution[row][col];
      
      if (value != 0 && value != correctValue) {
        _errorCells[row][col] = true;
        _mistakes++;
        
        // ✅ NOUVEAU: Vérifier si 3 erreurs atteintes
        if (_mistakes >= 3) {
          _triggerGameOver();
          return; // Arrêter l'exécution
        }
        
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
      
      if (_checkCompletion()) {
        await _completeGame();
      }
    }
    
    notifyListeners();
  }
  
  // ✅ NOUVEAU: Fonction Game Over
  void _triggerGameOver() {
    _isGameOver = true;
    _timer?.cancel();
    _autoSaveTimer?.cancel();
    
    print('💀 GAME OVER! 3 erreurs atteintes.');
    
    notifyListeners();
  }
  
  // ✅ NOUVEAU: Continuer avec publicité (pour plus tard)
  void continueWithAd() {
    _isGameOver = false;
    _mistakes = 2; // Réinitialiser à 2 erreurs (1 chance restante)
    
    _startTimer();
    _startAutoSave();
    
    print('📺 Pub regardée - Jeu repris avec 2 erreurs');
    
    notifyListeners();
  }
  
  void clearCell(int row, int col) {
    if (_initialCells[row][col] || _isCompleted || _isGameOver) return; // ✅ Bloquer si game over
    
    _playerGrid[row][col] = 0;
    _notes[row][col].clear();
    _errorCells[row][col] = false;
    
    notifyListeners();
  }
  
  bool _checkCompletion() {
    for (int i = 0; i < 9; i++) {
      for (int j = 0; j < 9; j++) {
        if (_playerGrid[i][j] == 0) return false;
        
        int correctValue = _solutionGrid.isNotEmpty 
            ? _solutionGrid[i][j] 
            : _currentGame!.solution[i][j];
            
        if (_playerGrid[i][j] != correctValue) {
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
    
    if (_currentGame != null) {
      try {
        await _apiService.post('/game/${_currentGame!.id}/complete', {
          'time_elapsed': _elapsedSeconds,
          'mistakes': _mistakes,
        });
      } catch (e) {
        print('Error completing game: $e');
      }
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
          int correctValue = _solutionGrid.isNotEmpty 
              ? _solutionGrid[row][col] 
              : _currentGame!.solution[row][col];
          
          _playerGrid[row][col] = correctValue;
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
            if (!_initialCells[i][j] && _playerGrid[i][j] != 0) {
              int correctValue = _solutionGrid.isNotEmpty 
                  ? _solutionGrid[i][j] 
                  : _currentGame!.solution[i][j];
              
              if (_playerGrid[i][j] != correctValue) {
                _playerGrid[i][j] = correctValue;
                _notes[i][j].clear();
                break;
              }
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
    _solutionGrid = [];
    _initialCells = [];
    _errorCells = [];
    _notes = [];
    _elapsedSeconds = 0;
    _mistakes = 0;
    _isCompleted = false;
    _isNoteMode = false;
    _isPaused = false;
    _isGameOver = false; // ✅ NOUVEAU
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