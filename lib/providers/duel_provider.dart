import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/duel_model.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import '../config/constants.dart';

class DuelProvider with ChangeNotifier {
  DuelModel? _currentDuel;
  List<List<int>> _playerGrid = [];
  List<List<bool>> _initialCells = [];
  List<List<bool>> _errorCells = [];
  
  bool _isSearching = false;
  bool _isDuelActive = false;
  bool _isEliminated = false;
  Timer? _timer;
  int _elapsedSeconds = 0;
  int _myMistakes = 0;
  
  // Messages in-game
  List<DuelMessage> _messages = [];
  String? _lastOpponentMessage;
  
  final ApiService _apiService = ApiService();
  final SocketService _socketService = SocketService();
  
  // Getters
  DuelModel? get currentDuel => _currentDuel;
  List<List<int>> get playerGrid => _playerGrid;
  List<List<bool>> get initialCells => _initialCells;
  List<List<bool>> get errorCells => _errorCells;
  bool get isSearching => _isSearching;
  bool get isDuelActive => _isDuelActive;
  bool get isEliminated => _isEliminated;
  int get elapsedSeconds => _elapsedSeconds;
  int get myMistakes => _myMistakes;
  List<DuelMessage> get messages => _messages;
  String? get lastOpponentMessage => _lastOpponentMessage;
  
  String get formattedTime {
    final minutes = (_elapsedSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_elapsedSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
  
  int get myProgress {
    if (_playerGrid.isEmpty) return 0;
    
    int filledCells = 0;
    for (var row in _playerGrid) {
      filledCells += row.where((c) => c != 0).length;
    }
    
    return (filledCells / 81 * 100).round();
  }
  
  int get opponentProgress {
    if (_currentDuel == null) return 0;
    
    final isPlayer1 = _currentDuel!.player1Id == _getCurrentUserId();
    return isPlayer1 ? _currentDuel!.player2Progress : _currentDuel!.player1Progress;
  }
  
  int get opponentMistakes {
    if (_currentDuel == null) return 0;
    
    final isPlayer1 = _currentDuel!.player1Id == _getCurrentUserId();
    return isPlayer1 ? _currentDuel!.player2Mistakes : _currentDuel!.player1Mistakes;
  }
  
  // ✅ FIX: Méthode pour récupérer l'ID utilisateur depuis SharedPreferences
  int _getCurrentUserId() {
    // On retourne un ID par défaut pour l'instant
    // Cette valeur sera overridée par la vraie valeur dans searchForOpponent
    return _currentUserId ?? 0;
  }
  
  int? _currentUserId;
  
  Future<int> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    _currentUserId = prefs.getInt(AppConstants.userIdKey) ?? 0;
    return _currentUserId!;
  }
  
  // ==========================================
  // SEARCH & MATCHMAKING
  // ==========================================
  
  Future<void> searchForOpponent(String difficulty) async {
    _isSearching = true;
    _messages.clear();
    notifyListeners();
    
    try {
      // Charger l'ID utilisateur
      final userId = await _loadUserId();
      
      // ✅ FIX: Utiliser .connect() au lieu de await connect()
      _socketService.connect();
      
      _socketService.emit('search_duel', {
        'difficulty': difficulty,
        'userId': userId,
      });
      
      // Listen for duel found
      _socketService.on('duel_found', (data) {
        print('🎮 Duel found: $data');
        _handleDuelFound(data);
      });
      
      // Listen for opponent progress
      _socketService.on('opponent_progress', (data) {
        _handleOpponentProgress(data);
      });
      
      // Listen for duel finished
      _socketService.on('duel_finished', (data) {
        _handleDuelFinished(data);
      });
      
      // Listen for opponent disconnected
      _socketService.on('opponent_disconnected', (data) {
        _handleOpponentDisconnected();
      });
      
      // Listen for in-game messages
      _socketService.on('duel_message', (data) {
        _handleDuelMessage(data);
      });
      
      // Listen for opponent eliminated
      _socketService.on('opponent_eliminated', (data) {
        _handleOpponentEliminated();
      });
      
    } catch (e) {
      _isSearching = false;
      notifyListeners();
      print('Error searching for opponent: $e');
      rethrow;
    }
  }
  
  void cancelSearch(String difficulty) {
    final userId = _getCurrentUserId();
    
    _socketService.emit('cancel_search', {
      'difficulty': difficulty,
      'userId': userId,
    });
    
    _isSearching = false;
    _socketService.disconnect();
    notifyListeners();
  }
  
  Future<void> challengeFriend(int friendId, String difficulty) async {
    try {
      _isSearching = true;
      notifyListeners();
      
      final response = await _apiService.post('/duel/challenge', {
        'friend_id': friendId,
        'difficulty': difficulty,
      });
      
      _handleDuelFound(response);
      
    } catch (e) {
      _isSearching = false;
      notifyListeners();
      print('Error challenging friend: $e');
      rethrow;
    }
  }
  
  // ==========================================
  // DUEL HANDLERS
  // ==========================================
  
  void _handleDuelFound(Map<String, dynamic> data) {
    _currentDuel = DuelModel.fromJson(data);
    _playerGrid = _currentDuel!.grid.map((row) => List<int>.from(row)).toList();
    _initialCells = List.generate(9, (i) => 
      List.generate(9, (j) => _currentDuel!.grid[i][j] != 0)
    );
    _errorCells = List.generate(9, (i) => List.generate(9, (j) => false));
    
    _isSearching = false;
    _isDuelActive = true;
    _isEliminated = false;
    _elapsedSeconds = 0;
    _myMistakes = 0;
    _messages.clear();
    
    _startTimer();
    notifyListeners();
  }
  
  void _handleOpponentProgress(Map<String, dynamic> data) {
    if (_currentDuel == null) return;
    
    _currentDuel = _currentDuel!.copyWith(
      player2Progress: data['progress'],
      player2Mistakes: data['mistakes'],
    );
    
    notifyListeners();
  }
  
  void _handleDuelFinished(Map<String, dynamic> data) {
    _timer?.cancel();
    
    final winnerId = data['winner_id'];
    
    _currentDuel = _currentDuel!.copyWith(
      winnerId: winnerId == 'player1' ? _currentDuel!.player1Id : _currentDuel!.player2Id,
      status: 'finished',
    );
    
    _isDuelActive = false;
    notifyListeners();
  }
  
  void _handleOpponentDisconnected() {
    _timer?.cancel();
    _isDuelActive = false;
    
    // Victory by default
    _currentDuel = _currentDuel!.copyWith(
      winnerId: _getCurrentUserId(),
      status: 'finished',
    );
    
    notifyListeners();
  }
  
  void _handleDuelMessage(Map<String, dynamic> data) {
    final message = DuelMessage(
      senderId: data['sender_id'],
      content: data['content'],
      timestamp: DateTime.now(),
    );
    
    _messages.add(message);
    _lastOpponentMessage = data['content'];
    
    // Clear last message after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      _lastOpponentMessage = null;
      notifyListeners();
    });
    
    notifyListeners();
  }
  
  void _handleOpponentEliminated() {
    // Opponent eliminated by 3 mistakes - I win!
    _timer?.cancel();
    
    _currentDuel = _currentDuel!.copyWith(
      winnerId: _getCurrentUserId(),
      status: 'finished',
    );
    
    _isDuelActive = false;
    notifyListeners();
  }
  
  // ==========================================
  // GAME ACTIONS
  // ==========================================
  
  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _elapsedSeconds++;
      notifyListeners();
    });
  }
  
  Future<void> setCellValue(int row, int col, int value) async {
    if (_initialCells[row][col] || !_isDuelActive || _isEliminated) return;
    
    _playerGrid[row][col] = value;
    
    // Check if correct
    if (value != 0 && value != _currentDuel!.solution[row][col]) {
      _errorCells[row][col] = true;
      _myMistakes++;
      
      // Check for 3 mistakes elimination
      if (_myMistakes >= 3) {
        await _eliminatePlayer();
        return;
      }
      
      // Clear error after 1 second
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
    
    // Emit progress to opponent
    final progress = myProgress;
    
    _socketService.emit('update_progress', {
      'duel_id': _currentDuel!.id,
      'progress': progress,
      'mistakes': _myMistakes,
    });
    
    // Check if completed
    if (_checkCompletion()) {
      await _completeDuel();
    }
    
    notifyListeners();
  }
  
  // ✅ FONCTION clearCell() comme dans GameProvider
  void clearCell(int row, int col) {
    if (_initialCells[row][col] || !_isDuelActive || _isEliminated) return;
    
    _playerGrid[row][col] = 0;
    _errorCells[row][col] = false;
    
    notifyListeners();
  }
  
  bool _checkCompletion() {
    for (int i = 0; i < 9; i++) {
      for (int j = 0; j < 9; j++) {
        if (_playerGrid[i][j] == 0 || _playerGrid[i][j] != _currentDuel!.solution[i][j]) {
          return false;
        }
      }
    }
    return true;
  }
  
  Future<void> _completeDuel() async {
    _timer?.cancel();
    _isDuelActive = false;
    
    try {
      await _apiService.post('/duel/${_currentDuel!.id}/complete', {
        'time_elapsed': _elapsedSeconds,
      });
      
      _socketService.emit('duel_completed', {
        'duel_id': _currentDuel!.id,
      });
      
      _currentDuel = _currentDuel!.copyWith(
        winnerId: _getCurrentUserId(),
        status: 'finished',
      );
      
    } catch (e) {
      print('Error completing duel: $e');
    }
    
    notifyListeners();
  }
  
  Future<void> _eliminatePlayer() async {
    _isEliminated = true;
    _isDuelActive = false;
    _timer?.cancel();
    
    // Notify opponent
    _socketService.emit('player_eliminated', {
      'duel_id': _currentDuel!.id,
    });
    
    // Update duel as lost
    final opponentId = _currentDuel!.player1Id == _getCurrentUserId() 
        ? _currentDuel!.player2Id 
        : _currentDuel!.player1Id;
    
    _currentDuel = _currentDuel!.copyWith(
      winnerId: opponentId,
      status: 'finished',
    );
    
    notifyListeners();
  }
  
  // ==========================================
  // IN-GAME MESSAGES
  // ==========================================
  
  void sendQuickMessage(String message) {
    if (!_isDuelActive || _currentDuel == null) return;
    
    _socketService.emit('duel_message', {
      'duel_id': _currentDuel!.id,
      'sender_id': _getCurrentUserId(),
      'content': message,
    });
    
    // Add to local messages
    final msg = DuelMessage(
      senderId: _getCurrentUserId(),
      content: message,
      timestamp: DateTime.now(),
    );
    
    _messages.add(msg);
    notifyListeners();
  }
  
  // ==========================================
  // CLEANUP
  // ==========================================
  
  Future<void> abandonDuel() async {
    _timer?.cancel();
    
    if (_currentDuel != null && _isDuelActive) {
      _socketService.emit('abandon_duel', {
        'duel_id': _currentDuel!.id,
      });
    }
    
    _socketService.disconnect();
    _resetState();
  }
  
  void _resetState() {
    _currentDuel = null;
    _playerGrid = [];
    _initialCells = [];
    _errorCells = [];
    _elapsedSeconds = 0;
    _myMistakes = 0;
    _isDuelActive = false;
    _isEliminated = false;
    _isSearching = false;
    _messages.clear();
    _lastOpponentMessage = null;
    
    notifyListeners();
  }
  
  @override
  void dispose() {
    _timer?.cancel();
    _socketService.disconnect();
    super.dispose();
  }
}

// ==========================================
// EXTENSION & MODELS
// ==========================================

extension DuelModelExtension on DuelModel {
  DuelModel copyWith({
    int? player2Progress,
    int? player2Mistakes,
    int? winnerId,
    String? status,
  }) {
    return DuelModel(
      id: id,
      player1Id: player1Id,
      player2Id: player2Id,
      player1Name: player1Name,
      player2Name: player2Name,
      grid: grid,
      solution: solution,
      difficulty: difficulty,
      winnerId: winnerId ?? this.winnerId,
      status: status ?? this.status,
      createdAt: createdAt,
      player1Progress: player1Progress,
      player2Progress: player2Progress ?? this.player2Progress,
      player1Mistakes: player1Mistakes,
      player2Mistakes: player2Mistakes ?? this.player2Mistakes,
    );
  }
}

class DuelMessage {
  final int senderId;
  final String content;
  final DateTime timestamp;
  
  DuelMessage({
    required this.senderId,
    required this.content,
    required this.timestamp,
  });
}