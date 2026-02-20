import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../providers/tournament_provider.dart';
import '../../config/theme.dart';
import '../../widgets/sudoku_grid.dart';
import '../../widgets/number_pad.dart';
import '../../models/tournament_model.dart';
import 'tournament_results_screen.dart';

class TournamentGameScreen extends StatefulWidget {
  final TournamentModel tournament;
  
  const TournamentGameScreen({
    Key? key,
    required this.tournament,
  }) : super(key: key);

  @override
  State<TournamentGameScreen> createState() => _TournamentGameScreenState();
}

class _TournamentGameScreenState extends State<TournamentGameScreen> with TickerProviderStateMixin {
  int? selectedRow;
  int? selectedCol;
  
  List<List<int>> _playerGrid = [];
  List<List<bool>> _initialCells = [];
  List<List<bool>> _errorCells = [];
  List<List<Set<int>>> _notes = [];
  
  Timer? _timer;
  int _elapsedSeconds = 0;
  int _mistakes = 0;
  bool _isCompleted = false;
  bool _showLeaderboard = true;
  
  late AnimationController _timerPulseController;
  late Animation<double> _timerPulseAnimation;
  
  @override
  void initState() {
    super.initState();
    
    // Initialize grid
    _playerGrid = widget.tournament.grid.map((row) => List<int>.from(row)).toList();
    _initialCells = List.generate(9, (i) => List.generate(9, (j) => widget.tournament.grid[i][j] != 0));
    _errorCells = List.generate(9, (i) => List.generate(9, (j) => false));
    _notes = List.generate(9, (i) => List.generate(9, (j) => <int>{}));
    
    // Start timer
    _startTimer();
    
    // Pulse animation for timer
    _timerPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    
    _timerPulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _timerPulseController, curve: Curves.easeInOut),
    );
    
    // Load leaderboard
    final tournamentProvider = Provider.of<TournamentProvider>(context, listen: false);
    tournamentProvider.loadLeaderboard(widget.tournament.id);
    
    // Refresh leaderboard every 10 seconds
    Timer.periodic(const Duration(seconds: 10), (timer) {
      if (!mounted || _isCompleted) {
        timer.cancel();
        return;
      }
      tournamentProvider.loadLeaderboard(widget.tournament.id);
    });
  }
  
  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _elapsedSeconds++;
      });
    });
  }
  
  String get _formattedTime {
    final minutes = _elapsedSeconds ~/ 60;
    final seconds = _elapsedSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
  
  void _setCellValue(int row, int col, int value) {
    if (_initialCells[row][col] || _isCompleted) return;
    
    setState(() {
      _playerGrid[row][col] = value;
      _notes[row][col].clear();
      
      // Check if correct
      if (value != 0 && value != widget.tournament.solution[row][col]) {
        _errorCells[row][col] = true;
        _mistakes++;
        
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            setState(() {
              _errorCells[row][col] = false;
            });
          }
        });
      } else {
        _errorCells[row][col] = false;
      }
      
      // Check completion
      if (_checkCompletion()) {
        _completeGame();
      }
    });
  }
  
  bool _checkCompletion() {
    for (int i = 0; i < 9; i++) {
      for (int j = 0; j < 9; j++) {
        if (_playerGrid[i][j] == 0 || _playerGrid[i][j] != widget.tournament.solution[i][j]) {
          return false;
        }
      }
    }
    return true;
  }
  
  Future<void> _completeGame() async {
    _isCompleted = true;
    _timer?.cancel();
    
    // Calculate score (based on time and mistakes)
    final baseScore = 10000;
    final timepenalty = _elapsedSeconds * 10;
    final mistakePenalty = _mistakes * 500;
    final finalScore = (baseScore - timepenalty - mistakePenalty).clamp(0, 10000);
    
    // Submit score
    final tournamentProvider = Provider.of<TournamentProvider>(context, listen: false);
    await tournamentProvider.submitScore(
      widget.tournament.id,
      finalScore,
      _elapsedSeconds,
    );
    
    // Show results
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => TournamentResultsScreen(
            tournament: widget.tournament,
            score: finalScore,
            time: _elapsedSeconds,
            mistakes: _mistakes,
          ),
        ),
      );
    }
  }
  
  @override
  void dispose() {
    _timer?.cancel();
    _timerPulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tournamentProvider = Provider.of<TournamentProvider>(context);
    
    return WillPopScope(
      onWillPop: () async {
        final shouldExit = await _showExitDialog();
        return shouldExit ?? false;
      },
      child: Scaffold(
        backgroundColor: AppColors.gray50,
        appBar: AppBar(
          title: Text(widget.tournament.name),
          actions: [
            // Toggle leaderboard
            IconButton(
              icon: Icon(_showLeaderboard ? Icons.visibility_off : Icons.leaderboard),
              onPressed: () {
                setState(() {
                  _showLeaderboard = !_showLeaderboard;
                });
              },
              tooltip: _showLeaderboard ? 'Masquer classement' : 'Afficher classement',
            ),
          ],
        ),
        body: SafeArea(
          child: Row(
            children: [
              // Main game area
              Expanded(
                flex: _showLeaderboard ? 2 : 1,
                child: Column(
                  children: [
                    // Timer and stats
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.yellow, AppColors.orange],
                        ),
                      ),
                      child: Column(
                        children: [
                          // Timer
                          ScaleTransition(
                            scale: _timerPulseAnimation,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.timer, color: Colors.white, size: 28),
                                SizedBox(width: 12),
                                Text(
                                  _formattedTime,
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          SizedBox(height: 12),
                          
                          // Stats
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _StatChip(
                                icon: Icons.close,
                                label: 'Erreurs',
                                value: '$_mistakes',
                                color: AppColors.red,
                              ),
                              _StatChip(
                                icon: Icons.people,
                                label: 'Participants',
                                value: '${widget.tournament.participants}',
                                color: AppColors.blue,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    // Sudoku Grid
                    Expanded(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: SudokuGrid(
                            grid: _playerGrid,
                            initialCells: _initialCells,
                            errorCells: _errorCells,
                            notes: _notes,
                            selectedRow: selectedRow,
                            selectedCol: selectedCol,
                            onCellTap: (row, col) {
                              setState(() {
                                selectedRow = row;
                                selectedCol = col;
                              });
                            },
                          ),
                        ),
                      ),
                    ),
                    
                    // Number Pad
                    NumberPad(
                      isNoteMode: false,
                      grid: _playerGrid,
                      onNumberTap: (number) {
                        if (selectedRow != null && selectedCol != null) {
                          if (number == 0) {
                            setState(() {
                              _playerGrid[selectedRow!][selectedCol!] = 0;
                              _notes[selectedRow!][selectedCol!].clear();
                            });
                          } else {
                            _setCellValue(selectedRow!, selectedCol!, number);
                          }
                        }
                      },
                    ),
                  ],
                ),
              ),
              
              // Live Leaderboard
              if (_showLeaderboard)
                Container(
                  width: 280,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: Offset(-2, 0),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Header
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.purple, AppColors.blue],
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.emoji_events, color: Colors.white),
                            SizedBox(width: 12),
                            Text(
                              'CLASSEMENT LIVE',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Leaderboard list
                      Expanded(
                        child: tournamentProvider.isLoading
                            ? Center(child: CircularProgressIndicator())
                            : tournamentProvider.leaderboard.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.hourglass_empty, size: 48, color: AppColors.gray300),
                                        SizedBox(height: 16),
                                        Text(
                                          'En attente de scores...',
                                          style: TextStyle(color: AppColors.gray500),
                                        ),
                                      ],
                                    ),
                                  )
                                : ListView.builder(
                                    padding: EdgeInsets.all(12),
                                    itemCount: tournamentProvider.leaderboard.length.clamp(0, 10),
                                    itemBuilder: (context, index) {
                                      final player = tournamentProvider.leaderboard[index];
                                      final isMe = false; // TODO: Check if current user
                                      
                                      return _LeaderboardItem(
                                        rank: index + 1,
                                        username: player.username,
                                        score: player.score,
                                        time: player.time,
                                        isMe: isMe,
                                      );
                                    },
                                  ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
  
  Future<bool?> _showExitDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber, color: AppColors.orange),
            SizedBox(width: 12),
            Text('Quitter le tournoi ?'),
          ],
        ),
        content: Text('Votre progression ne sera pas sauvegardée.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Continuer'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.red),
            child: Text('Quitter'),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  
  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 18),
          SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LeaderboardItem extends StatelessWidget {
  final int rank;
  final String username;
  final int score;
  final int time;
  final bool isMe;
  
  const _LeaderboardItem({
    required this.rank,
    required this.username,
    required this.score,
    required this.time,
    this.isMe = false,
  });
  
  String get _formattedTime {
    final minutes = time ~/ 60;
    final seconds = time % 60;
    return '${minutes}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isMe ? AppColors.blue.withOpacity(0.1) : AppColors.gray50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isMe ? AppColors.blue : AppColors.gray200,
          width: isMe ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          // Rank
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: rank <= 3 ? _getRankColor() : AppColors.gray300,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                rank <= 3 ? _getMedal() : '$rank',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: rank <= 3 ? 16 : 12,
                ),
              ),
            ),
          ),
          
          SizedBox(width: 12),
          
          // Username
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  username,
                  style: TextStyle(
                    fontWeight: isMe ? FontWeight.bold : FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2),
                Text(
                  _formattedTime,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.gray500,
                  ),
                ),
              ],
            ),
          ),
          
          // Score
          Text(
            '$score',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: AppColors.yellow,
            ),
          ),
        ],
      ),
    );
  }
  
  String _getMedal() {
    switch (rank) {
      case 1: return '🥇';
      case 2: return '🥈';
      case 3: return '🥉';
      default: return '';
    }
  }
  
  Color _getRankColor() {
    switch (rank) {
      case 1: return Color(0xFFFFD700); // Gold
      case 2: return Color(0xFFC0C0C0); // Silver
      case 3: return Color(0xFFCD7F32); // Bronze
      default: return AppColors.gray300;
    }
  }
}