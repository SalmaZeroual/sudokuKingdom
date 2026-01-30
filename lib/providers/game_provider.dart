import 'package:flutter/material.dart';
import 'dart:async';
import '../models/game_model.dart';
import '../models/booster_model.dart';
import '../services/api_service.dart';

class GameProvider with ChangeNotifier {
  GameModel? _currentGame;
  List<List<int>> _playerGrid = [];
  List<List<int>> _solutionGrid = []; // NOUVEAU : Pour le mode Story
  List<List<bool>> _initialCells = [];
  List<List<bool>> _errorCells = [];
  List<List<Set<int>>> _notes = []; // Notes pour chaque case
  
  Timer? _timer;
  Timer? _autoSaveTimer;
  int _elapsedSeconds = 0;
  int _mistakes = 0;
  bool _isCompleted = false;
  bool _isLoading = false;
  bool _isNoteMode = false; // Mode notes activé/désactivé
  bool _isPaused = false; // NOUVEAU : Pour gérer la pause
  
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
  List<BoosterModel> get boosters => _boosters;
  String? get selectedBooster => _selectedBooster;
  
  // MODIFIÉ : Getter isCompleted avec support du mode Story
  bool get isCompleted {
    // Check if all cells are filled and correct
    for (int i = 0; i < 9; i++) {
      for (int j = 0; j < 9; j++) {
        if (_playerGrid[i][j] == 0) return false;
        
        // If we have a solution grid (story mode), check against it
        if (_solutionGrid.isNotEmpty) {
          if (_playerGrid[i][j] != _solutionGrid[i][j]) return false;
        }
      }
    }
    
    // Additional validation for non-story mode
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
  
  // Toggle note mode
  void toggleNoteMode() {
    _isNoteMode = !_isNoteMode;
    notifyListeners();
  }
  
  // NOUVEAU : Initialize game for Story Mode
  void initializeStoryGame(
    List<List<int>> grid,
    List<List<int>> solution,
  ) {
    _currentGame = null; // Story mode doesn't use game model
    _playerGrid = grid.map((row) => List<int>.from(row)).toList();
    _solutionGrid = solution.map((row) => List<int>.from(row)).toList();
    
    // Mark initial cells
    _initialCells = List.generate(
      9,
      (i) => List.generate(9, (j) => grid[i][j] != 0),
    );
    
    // Reset error cells
    _errorCells = List.generate(9, (_) => List.generate(9, (_) => false));
    
    // Reset notes
    _notes = List.generate(9, (_) => List.generate(9, (_) => <int>{}));
    
    // Reset game state
    _mistakes = 0;
    _isNoteMode = false;
    _isPaused = false;
    
    notifyListeners();
  }
  
  // NOUVEAU : Validate Sudoku helper method
  bool _validateSudoku() {
    // Validate rows
    for (int i = 0; i < 9; i++) {
      final seen = <int>{};
      for (int j = 0; j < 9; j++) {
        if (_playerGrid[i][j] != 0) {
          if (seen.contains(_playerGrid[i][j])) return false;
          seen.add(_playerGrid[i][j]);
        }
      }
    }
    
    // Validate columns
    for (int j = 0; j < 9; j++) {
      final seen = <int>{};
      for (int i = 0; i < 9; i++) {
        if (_playerGrid[i][j] != 0) {
          if (seen.contains(_playerGrid[i][j])) return false;
          seen.add(_playerGrid[i][j]);
        }
      }
    }
    
    // Validate 3x3 boxes
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
      
      // MODIFIÉ : Check contre solution (Story mode) ou currentGame
      int correctValue = _solutionGrid.isNotEmpty 
          ? _solutionGrid[row][col] 
          : _currentGame!.solution[row][col];
      
      // Check if correct
      if (value != 0 && value != correctValue) {
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
        if (_playerGrid[i][j] == 0) return false;
        
        // Check contre solution (Story mode) ou currentGame
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
    
    // Only call API if we have a current game (not Story mode)
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
          // MODIFIÉ : Support pour Story mode
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
              // MODIFIÉ : Support pour Story mode
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
    _solutionGrid = []; // AJOUTÉ : Reset solution grid
    _initialCells = [];
    _errorCells = [];
    _notes = [];
    _elapsedSeconds = 0;
    _mistakes = 0;
    _isCompleted = false;
    _isNoteMode = false;
    _isPaused = false; // AJOUTÉ
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