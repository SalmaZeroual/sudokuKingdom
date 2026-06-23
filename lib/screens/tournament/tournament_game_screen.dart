// ============================================================
// lib/screens/tournament/tournament_game_screen.dart
// ============================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/tournament_provider.dart';
import '../../config/theme.dart';
import '../../widgets/sudoku_grid.dart';
import '../../widgets/number_pad.dart';
import '../../models/tournament_model.dart';
import 'tournament_results_screen.dart';

class TournamentGameScreen extends StatefulWidget {
  final TournamentModel tournament;

  const TournamentGameScreen({Key? key, required this.tournament})
      : super(key: key);

  @override
  State<TournamentGameScreen> createState() => _TournamentGameScreenState();
}

class _TournamentGameScreenState extends State<TournamentGameScreen>
    with TickerProviderStateMixin {
  // ── Grille ────────────────────────────────────────────────────────────
  int? selectedRow;
  int? selectedCol;
  late List<List<int>> _playerGrid;
  late List<List<bool>> _initialCells;
  late List<List<bool>> _errorCells;
  late List<List<Set<int>>> _notes;

  // ── Timers ────────────────────────────────────────────────────────────
  Timer? _gameTimer;
  Timer? _leaderboardTimer;
  int _elapsedSeconds = 0;
  int _mistakes = 0;
  bool _isCompleted = false;

  // ── UI ────────────────────────────────────────────────────────────────
  bool _showLeaderboard = true;

  late AnimationController _timerPulseController;
  late Animation<double> _timerPulseAnimation;

  @override
  void initState() {
    super.initState();

    _playerGrid = widget.tournament.grid
        .map((row) => List<int>.from(row))
        .toList();
    _initialCells = List.generate(
      9,
      (i) => List.generate(9, (j) => widget.tournament.grid[i][j] != 0),
    );
    _errorCells = List.generate(9, (_) => List.generate(9, (_) => false));
    _notes = List.generate(9, (_) => List.generate(9, (_) => <int>{}));

    _startGameTimer();

    _timerPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _timerPulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(
          parent: _timerPulseController, curve: Curves.easeInOut),
    );

    final provider =
        Provider.of<TournamentProvider>(context, listen: false);
    provider.loadLeaderboard(widget.tournament.id);

    // Rafraîchir le classement toutes les 10 secondes
    _leaderboardTimer =
        Timer.periodic(const Duration(seconds: 10), (_) {
      if (!mounted || _isCompleted) return;
      provider.loadLeaderboard(widget.tournament.id);
    });
  }

  void _startGameTimer() {
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _elapsedSeconds++);
    });
  }

  String get _formattedTime {
    final m = (_elapsedSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (_elapsedSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _setCellValue(int row, int col, int value) {
    if (_initialCells[row][col] || _isCompleted) return;

    setState(() {
      _playerGrid[row][col] = value;
      _notes[row][col].clear();

      final isWrong =
          value != 0 && value != widget.tournament.solution[row][col];

      if (isWrong) {
        _errorCells[row][col] = true;
        _mistakes++;
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) setState(() => _errorCells[row][col] = false);
        });
      } else {
        _errorCells[row][col] = false;
        if (_checkCompletion()) _completeGame();
      }
    });
  }

  bool _checkCompletion() {
    for (int i = 0; i < 9; i++) {
      for (int j = 0; j < 9; j++) {
        if (_playerGrid[i][j] == 0 ||
            _playerGrid[i][j] != widget.tournament.solution[i][j]) {
          return false;
        }
      }
    }
    return true;
  }

  Future<void> _completeGame() async {
    _isCompleted = true;
    _gameTimer?.cancel();
    _leaderboardTimer?.cancel();

    const baseScore = 10000;
    final timePenalty = _elapsedSeconds * 10;
    final mistakePenalty = _mistakes * 500;
    final finalScore =
        (baseScore - timePenalty - mistakePenalty).clamp(0, 10000);

    final provider =
        Provider.of<TournamentProvider>(context, listen: false);
    await provider.submitScore(
        widget.tournament.id, finalScore, _elapsedSeconds);

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
    _gameTimer?.cancel();
    _leaderboardTimer?.cancel();
    _timerPulseController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TournamentProvider>(context);

    return WillPopScope(
      onWillPop: () async => await _showExitDialog() ?? false,
      child: Scaffold(
        backgroundColor: AppColors.gray50,
        appBar: AppBar(
          title: Text(widget.tournament.name),
          actions: [
            // ✅ Bouton classement dans l'appbar — ouvre un panel modal,
            // ne partage PLUS l'écran en deux (bug image 5)
            IconButton(
              icon: const Icon(Icons.leaderboard),
              tooltip: 'Voir le classement',
              onPressed: () => _showLeaderboardSheet(context, provider),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              _buildTimerHeader(),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: SudokuGrid(
                      grid: _playerGrid,
                      initialCells: _initialCells,
                      errorCells: _errorCells,
                      notes: _notes,
                      selectedRow: selectedRow,
                      selectedCol: selectedCol,
                      onCellTap: (row, col) =>
                          setState(() {
                        selectedRow = row;
                        selectedCol = col;
                      }),
                    ),
                  ),
                ),
              ),
              NumberPad(
                isNoteMode: false,
                grid: _playerGrid,
                onNumberTap: (number) {
                  if (selectedRow == null || selectedCol == null) return;
                  if (number == 0) {
                    setState(() {
                      _playerGrid[selectedRow!][selectedCol!] = 0;
                      _notes[selectedRow!][selectedCol!].clear();
                    });
                  } else {
                    _setCellValue(selectedRow!, selectedCol!, number);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Classement en bottom sheet (plein écran préservé) ────────────────
  void _showLeaderboardSheet(BuildContext context, TournamentProvider provider) {
    provider.loadLeaderboard(widget.tournament.id);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.92,
        minChildSize: 0.35,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.gray300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Icon(Icons.emoji_events, color: AppColors.yellow),
                    const SizedBox(width: 8),
                    const Text('Classement Live',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    Consumer<TournamentProvider>(
                      builder: (_, p, __) => Row(
                        children: [
                          _ToggleTab(
                            label: '🌍',
                            active: p.leaderboardType == 'global',
                            onTap: () => p.setLeaderboardType('global'),
                          ),
                          const SizedBox(width: 4),
                          _ToggleTab(
                            label: '👥 Amis',
                            active: p.leaderboardType == 'friends',
                            onTap: () => p.setLeaderboardType('friends'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: Consumer<TournamentProvider>(
                  builder: (_, p, __) => p.isLeaderboardLoading
                      ? const Center(child: CircularProgressIndicator())
                      : p.leaderboard.isEmpty
                          ? Center(
                              child: Text(
                                p.leaderboardType == 'friends'
                                    ? 'Aucun ami n\'a joué'
                                    : 'Aucun participant pour l\'instant',
                                style: TextStyle(color: AppColors.gray500),
                              ),
                            )
                          : ListView.builder(
                              controller: scrollController,
                              padding: const EdgeInsets.all(16),
                              itemCount: p.leaderboard.length,
                              itemBuilder: (_, i) {
                                final player = p.leaderboard[i];
                                return _LeaderboardItem(
                                  rank: i + 1,
                                  username: player.username,
                                  score: player.score,
                                  time: player.time,
                                  isMe: false,
                                );
                              },
                            ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimerHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.yellow, AppColors.orange],
        ),
      ),
      child: Column(
        children: [
          ScaleTransition(
            scale: _timerPulseAnimation,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.timer, color: Colors.white, size: 26),
                const SizedBox(width: 10),
                Text(
                  _formattedTime,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
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
                label: 'Joueurs',
                value: '${widget.tournament.participants}',
                color: AppColors.blue,
              ),
              // Compte à rebours du tournoi
              _StatChip(
                icon: Icons.hourglass_bottom,
                label: 'Fin dans',
                value: widget.tournament.timeRemainingFormatted,
                color: AppColors.purple,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Classement live ─────────────────────────────────────────────────

  Widget _buildLiveLeaderboard(TournamentProvider provider) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(-2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header avec toggle
          Container(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.purple, AppColors.blue],
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: const [
                    Icon(Icons.emoji_events, color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'CLASSEMENT LIVE',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Toggle Mondial / Amis
                _buildCompactToggle(provider),
              ],
            ),
          ),

          // Liste
          Expanded(
            child: provider.isLeaderboardLoading
                ? const Center(child: CircularProgressIndicator())
                : provider.leaderboard.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.hourglass_empty,
                                  size: 40, color: AppColors.gray300),
                              const SizedBox(height: 12),
                              Text(
                                provider.leaderboardType == 'friends'
                                    ? 'Aucun ami\nn\'a joué'
                                    : 'En attente\nde scores...',
                                style: TextStyle(
                                    color: AppColors.gray500, fontSize: 12),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount:
                            provider.leaderboard.length.clamp(0, 10),
                        itemBuilder: (_, index) {
                          final player = provider.leaderboard[index];
                          return _LeaderboardItem(
                            rank: index + 1,
                            username: player.username,
                            score: player.score,
                            time: player.time,
                            isMe: false,
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactToggle(TournamentProvider provider) {
    final isGlobal = provider.leaderboardType == 'global';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(2),
      child: Row(
        children: [
          _ToggleTab(
            label: '🌍 Mondial',
            active: isGlobal,
            onTap: () => provider.setLeaderboardType('global'),
          ),
          _ToggleTab(
            label: '👥 Amis',
            active: !isGlobal,
            onTap: () => provider.setLeaderboardType('friends'),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showExitDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber, color: AppColors.orange),
            SizedBox(width: 12),
            Text('Quitter le tournoi ?'),
          ],
        ),
        // ✅ Message mis à jour : la progression est sauvegardée et
        // le joueur peut reprendre plus tard (le score 0 disparaît
        // du classement tant qu'il n'a pas soumis un vrai score).
        content: const Text(
          'Votre partie sera sauvegardée. Vous pourrez reprendre le tournoi depuis l\'écran principal.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Continuer'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.red),
            child: const Text('Sauvegarder et quitter'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widgets helpers
// ─────────────────────────────────────────────────────────────────────────────

class _ToggleTab extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _ToggleTab({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight:
                    active ? FontWeight.bold : FontWeight.normal,
                color: active ? AppColors.blue : Colors.white70,
              ),
            ),
          ),
        ),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 9,
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
    final m = time ~/ 60;
    final s = (time % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isMe ? AppColors.blue.withOpacity(0.1) : AppColors.gray50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isMe ? AppColors.blue : AppColors.gray200,
          width: isMe ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          // Rang
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: rank <= 3 ? _rankColor() : AppColors.gray300,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                rank <= 3 ? _medal() : '$rank',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: rank <= 3 ? 14 : 11,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  username,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _formattedTime,
                  style: TextStyle(
                      fontSize: 10, color: AppColors.gray500),
                ),
              ],
            ),
          ),
          Text(
            '$score',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: AppColors.yellow,
            ),
          ),
        ],
      ),
    );
  }

  String _medal() {
    switch (rank) {
      case 1: return '🥇';
      case 2: return '🥈';
      case 3: return '🥉';
      default: return '';
    }
  }

  Color _rankColor() {
    switch (rank) {
      case 1: return const Color(0xFFFFD700);
      case 2: return const Color(0xFFC0C0C0);
      case 3: return const Color(0xFFCD7F32);
      default: return AppColors.gray300;
    }
  }
}