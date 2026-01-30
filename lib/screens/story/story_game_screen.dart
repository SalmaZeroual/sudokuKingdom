import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../providers/game_provider.dart';
import '../../providers/story_provider.dart';
import '../../config/theme.dart';
import '../../models/story_model.dart';
import '../../widgets/sudoku_grid.dart';
import '../../widgets/number_pad.dart';

class StoryGameScreen extends StatefulWidget {
  final StoryChapter chapter;
  final Color kingdomColor;
  
  const StoryGameScreen({
    Key? key,
    required this.chapter,
    required this.kingdomColor,
  }) : super(key: key);

  @override
  State<StoryGameScreen> createState() => _StoryGameScreenState();
}

class _StoryGameScreenState extends State<StoryGameScreen> {
  int? selectedRow;
  int? selectedCol;
  Timer? _gameTimer;
  int _elapsedTime = 0;
  
  @override
  void initState() {
    super.initState();
    
    // Start game timer
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _elapsedTime++;
        });
      }
    });
    
    // Initialize game with chapter grid
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final gameProvider = Provider.of<GameProvider>(context, listen: false);
      _initializeGame(gameProvider);
    });
    
    // Check for completion
    Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      final gameProvider = Provider.of<GameProvider>(context, listen: false);
      if (gameProvider.isCompleted) {
        timer.cancel();
        _gameTimer?.cancel();
        _showVictoryDialog();
      }
    });
  }
  
  @override
  void dispose() {
    _gameTimer?.cancel();
    super.dispose();
  }
  
  void _initializeGame(GameProvider gameProvider) {
    // Initialize with chapter's grid
    gameProvider.initializeStoryGame(
      widget.chapter.grid!,
      widget.chapter.solution!,
    );
  }
  
  String get _formattedTime {
    final minutes = _elapsedTime ~/ 60;
    final seconds = _elapsedTime % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
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
          backgroundColor: widget.kingdomColor,
          foregroundColor: Colors.white,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.chapter.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Chapitre ${widget.chapter.chapterOrder}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ],
          ),
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
            IconButton(
              icon: Icon(
                gameProvider.isNoteMode ? Icons.edit : Icons.edit_outlined,
              ),
              onPressed: () {
                gameProvider.toggleNoteMode();
              },
              tooltip: gameProvider.isNoteMode ? 'Mode notes activé' : 'Activer mode notes',
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              // Game Stats with themed background
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      widget.kingdomColor.withOpacity(0.1),
                      widget.kingdomColor.withOpacity(0.05),
                    ],
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _GameStat(
                          icon: Icons.access_time,
                          label: 'Temps',
                          value: _formattedTime,
                          color: widget.kingdomColor,
                        ),
                        _GameStat(
                          icon: Icons.close,
                          label: 'Erreurs',
                          value: '${gameProvider.mistakes}',
                          color: widget.kingdomColor,
                        ),
                        _GameStat(
                          icon: Icons.flag,
                          label: widget.chapter.difficultyLabel,
                          value: '',
                          color: widget.kingdomColor,
                        ),
                      ],
                    ),
                    
                    // Note mode indicator
                    if (gameProvider.isNoteMode) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: widget.kingdomColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: widget.kingdomColor),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.edit, color: widget.kingdomColor, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              'Mode notes activé',
                              style: TextStyle(
                                color: widget.kingdomColor,
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
                      },
                    ),
                  ),
                ),
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
  
  Future<bool?> _showExitDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quitter le chapitre ?'),
        content: const Text(
          'Votre progression ne sera pas sauvegardée si vous quittez maintenant.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Continuer'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Quitter',
              style: TextStyle(color: AppColors.red),
            ),
          ),
        ],
      ),
    );
  }
  
  void _showVictoryDialog() {
    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    final mistakes = gameProvider.mistakes;
    
    // Calculate stars
    int stars = 1;
    if (_elapsedTime < 300 && mistakes == 0) {
      stars = 3;
    } else if (_elapsedTime < 600 && mistakes < 3) {
      stars = 2;
    }
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.emoji_events, color: widget.kingdomColor, size: 32),
            const SizedBox(width: 12),
            const Text('Chapitre Complété !'),
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
            
            // Stars display
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (i) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    i < stars ? Icons.star : Icons.star_border,
                    size: 40,
                    color: i < stars ? AppColors.yellow : AppColors.gray300,
                  ),
                );
              }),
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
                        _formattedTime,
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
                        '$mistakes',
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
                      Text(
                        'Étoiles :',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: widget.kingdomColor,
                        ),
                      ),
                      Row(
                        children: List.generate(stars, (i) {
                          return Icon(
                            Icons.star,
                            color: AppColors.yellow,
                            size: 20,
                          );
                        }),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () async {
              // Complete chapter on backend
              final storyProvider = Provider.of<StoryProvider>(
                context,
                listen: false,
              );
              
              final result = await storyProvider.completeChapter(
                widget.chapter.id,
                _elapsedTime,
                mistakes,
              );
              
              if (result != null && context.mounted) {
                // Show artifact dialog if unlocked
                if (result['artifact'] != null) {
                  await _showArtifactDialog(result['artifact']);
                }
                
                // Show kingdom completed dialog if applicable
                if (result['kingdom_completed'] == true) {
                  await _showKingdomCompletedDialog();
                }
                
                Navigator.of(context).pop(); // Close victory dialog
                Navigator.of(context).pop(); // Go back to kingdom screen
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.kingdomColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Continuer'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _showArtifactDialog(Map<String, dynamic> artifact) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Text(artifact['icon'], style: TextStyle(fontSize: 32)),
            const SizedBox(width: 12),
            const Text('Artefact Trouvé !'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              artifact['name'],
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: widget.kingdomColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Vous avez découvert un artefact légendaire !',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.gray600),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.kingdomColor,
            ),
            child: const Text('Génial !'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _showKingdomCompletedDialog() {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.military_tech, color: widget.kingdomColor, size: 32),
            const SizedBox(width: 12),
            const Text('Royaume Complété !'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.castle, size: 80, color: widget.kingdomColor),
            const SizedBox(height: 16),
            Text(
              widget.chapter.kingdomId == 1
                  ? 'Forêt Enchantée'
                  : widget.chapter.kingdomId == 2
                      ? 'Désert des Mirages'
                      : widget.chapter.kingdomId == 3
                          ? 'Océan des Profondeurs'
                          : widget.chapter.kingdomId == 4
                              ? 'Montagnes Célestes'
                              : 'Cosmos Éternel',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: widget.kingdomColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Vous avez terminé tous les chapitres de ce royaume !',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.gray600),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.kingdomColor,
            ),
            child: const Text('Incroyable !'),
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
  final Color color;
  
  const _GameStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        if (value.isNotEmpty)
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
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