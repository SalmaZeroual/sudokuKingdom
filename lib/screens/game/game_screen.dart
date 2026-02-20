import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../providers/game_provider.dart';
import '../../config/theme.dart';
import '../../widgets/sudoku_grid.dart';
import '../../widgets/number_pad.dart';
import '../../widgets/game_controls.dart';
import '../modes/classic_mode_screen.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({Key? key}) : super(key: key);

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  int? selectedRow;
  int? selectedCol;
  
  @override
  void initState() {
    super.initState();
    
    Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      final gameProvider = Provider.of<GameProvider>(context, listen: false);
      
      // ✅ NOUVEAU: Vérifier Game Over
      if (gameProvider.isGameOver) {
        timer.cancel();
        _showGameOverDialog();
      }
      
      if (gameProvider.isCompleted) {
        timer.cancel();
        _showVictoryDialog();
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final gameProvider = Provider.of<GameProvider>(context);
    
    return WillPopScope(
      onWillPop: () async {
        final shouldPop = await _showExitDialog(context);
        return shouldPop ?? false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Partie en cours'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              final shouldExit = await _showExitDialog(context);
              if (shouldExit == true && context.mounted) {
                Navigator.of(context).pop();
              }
            },
          ),
          actions: [
            // Bouton Nouvelle Partie
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => _showNewGameDialog(context),
              tooltip: 'Nouvelle partie',
            ),
            // Bouton mode notes
            IconButton(
              icon: Icon(
                gameProvider.isNoteMode ? Icons.edit : Icons.edit_outlined,
                color: gameProvider.isNoteMode ? AppColors.blue : null,
              ),
              onPressed: () {
                gameProvider.toggleNoteMode();
              },
              tooltip: gameProvider.isNoteMode ? 'Mode notes activé' : 'Activer mode notes',
            ),
            IconButton(
              icon: const Icon(Icons.pause),
              onPressed: () {
                gameProvider.pauseGame();
                _showPauseDialog(context);
              },
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              // Game Stats
              Container(
                padding: const EdgeInsets.all(16),
                color: AppColors.gray50,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _GameStat(
                          icon: Icons.access_time,
                          label: 'Temps',
                          value: gameProvider.formattedTime,
                        ),
                        // ✅ AMÉLIORÉ: Afficher les erreurs avec couleur
                        _GameStat(
                          icon: Icons.close,
                          label: 'Erreurs',
                          value: '${gameProvider.mistakes}/3',
                          isError: gameProvider.mistakes >= 2,
                        ),
                        _GameStat(
                          icon: Icons.lightbulb_outline,
                          label: 'Indices',
                          value: '${gameProvider.boosters.where((b) => b.boosterType == 'reveal_cell').firstOrNull?.quantity ?? 0}',
                        ),
                      ],
                    ),
                    
                    // Note mode indicator
                    if (gameProvider.isNoteMode) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.blue),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.edit, color: AppColors.blue, size: 16),
                            SizedBox(width: 8),
                            Text(
                              'Mode notes activé',
                              style: TextStyle(
                                color: AppColors.blue,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              // Sudoku Grid
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: SudokuGrid(
                      grid: gameProvider.playerGrid,
                      initialCells: gameProvider.initialCells,
                      errorCells: gameProvider.errorCells,
                      notes: gameProvider.notes,
                      selectedRow: selectedRow,
                      selectedCol: selectedCol,
                      selectedBooster: gameProvider.selectedBooster,
                      onCellTap: (row, col) {
                        setState(() {
                          selectedRow = row;
                          selectedCol = col;
                        });
                        
                        if (gameProvider.selectedBooster == 'reveal_cell') {
                          gameProvider.useBooster('reveal_cell', row: row, col: col);
                          setState(() {
                            selectedRow = null;
                            selectedCol = null;
                          });
                        }
                      },
                    ),
                  ),
                ),
              ),
              
              // Game Controls
              GameControls(
                boosters: gameProvider.boosters,
                selectedBooster: gameProvider.selectedBooster,
                onBoosterTap: (type) {
                  if (gameProvider.selectedBooster == type) {
                    gameProvider.clearSelection();
                  } else {
                    gameProvider.selectBooster(type);
                  }
                },
              ),
              
              // Number Pad
              NumberPad(
                isNoteMode: gameProvider.isNoteMode,
                grid: gameProvider.playerGrid,
                onNumberTap: (number) {
                  if (selectedRow != null && selectedCol != null) {
                    if (number == 0) {
                      gameProvider.clearCell(selectedRow!, selectedCol!);
                    } else {
                      gameProvider.setCellValue(selectedRow!, selectedCol!, number);
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // ✅ NOUVEAU: Dialogue Game Over
  void _showGameOverDialog() {
    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.red, size: 32),
            SizedBox(width: 12),
            Text('Game Over !'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sentiment_very_dissatisfied, size: 80, color: AppColors.red),
            SizedBox(height: 16),
            Text(
              '3 erreurs atteintes !',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.red,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Vous avez fait trop d\'erreurs.\nVoulez-vous continuer ?',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.gray50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.gray200),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Temps:', style: TextStyle(color: AppColors.gray500)),
                      Text(
                        gameProvider.formattedTime,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Erreurs:', style: TextStyle(color: AppColors.gray500)),
                      Text(
                        '${gameProvider.mistakes}',
                        style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.red),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // ✅ Option 1: Quitter
          TextButton(
            onPressed: () async {
              await gameProvider.abandonGame();
              
              if (context.mounted) {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Close game screen
              }
            },
            child: Text('Quitter'),
          ),
          
          // ✅ Option 2: Continuer avec pub (pour plus tard)
          ElevatedButton.icon(
            onPressed: () {
              // Pour l'instant, continuer directement
              // Plus tard: Afficher une pub avant
              gameProvider.continueWithAd();
              Navigator.of(context).pop();
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('📺 Publicité regardée - Vous avez une nouvelle chance !'),
                  backgroundColor: AppColors.green,
                ),
              );
            },
            icon: Icon(Icons.play_arrow, size: 18),
            label: Text('Continuer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
  
  // Dialogue pour commencer une nouvelle partie
  Future<void> _showNewGameDialog(BuildContext context) {
    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.orange, size: 28),
            SizedBox(width: 12),
            Text('Nouvelle partie ?'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Êtes-vous sûr de vouloir abandonner cette partie ?',
              style: TextStyle(fontSize: 15),
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.red.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.red, size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Votre progression actuelle sera perdue',
                      style: TextStyle(
                        color: AppColors.red,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.gray50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.gray200),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Temps écoulé:', style: TextStyle(color: AppColors.gray500, fontSize: 13)),
                      Text(
                        gameProvider.formattedTime,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                  SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Erreurs:', style: TextStyle(color: AppColors.gray500, fontSize: 13)),
                      Text(
                        '${gameProvider.mistakes}',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              await gameProvider.abandonGame();
              
              if (context.mounted) {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => ClassicModeScreen()),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.blue,
              foregroundColor: Colors.white,
            ),
            child: Text('Nouvelle partie'),
          ),
        ],
      ),
    );
  }
  
  Future<bool?> _showExitDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quitter la partie ?'),
        content: const Text('Votre progression sera sauvegardée.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Continuer'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Quitter'),
          ),
        ],
      ),
    );
  }
  
  void _showPauseDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Pause'),
        content: const Text('La partie est en pause.'),
        actions: [
          TextButton(
            onPressed: () {
              final gameProvider = Provider.of<GameProvider>(context, listen: false);
              gameProvider.resumeGame();
              Navigator.of(context).pop();
            },
            child: const Text('Reprendre'),
          ),
        ],
      ),
    );
  }
  
  void _showVictoryDialog() {
    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.emoji_events, color: AppColors.yellow, size: 32),
            const SizedBox(width: 12),
            const Text('Victoire !'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.celebration, size: 80, color: AppColors.yellow),
            const SizedBox(height: 16),
            const Text(
              'Félicitations !',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.gray50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Temps :'),
                      Text(
                        gameProvider.formattedTime,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Erreurs :'),
                      Text(
                        '${gameProvider.mistakes}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Divider(),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'XP gagné :',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.blue,
                        ),
                      ),
                      const Text(
                        '+150 XP',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.yellow,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Retour à l\'accueil'),
          ),
          ElevatedButton(
            onPressed: () async {
              await gameProvider.abandonGame();
              
              if (context.mounted) {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => ClassicModeScreen()),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Nouvelle partie'),
          ),
        ],
      ),
    );
  }
}

class _GameStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isError; // ✅ NOUVEAU
  
  const _GameStat({
    required this.icon,
    required this.label,
    required this.value,
    this.isError = false,
  });
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          icon,
          color: isError ? AppColors.red : AppColors.blue, // ✅ Rouge si erreurs
          size: 24,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isError ? AppColors.red : null, // ✅ Rouge si erreurs
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.gray500,
          ),
        ),
      ],
    );
  }
}