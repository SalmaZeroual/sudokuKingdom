import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:math';
import '../../providers/game_provider.dart';
import '../../providers/story_provider.dart';
import '../../config/theme.dart';
import '../../models/story_model.dart';
import '../../widgets/sudoku_grid.dart';
import '../../widgets/number_pad.dart';
import '../../widgets/kingdom_particles.dart';
import '../../utils/story_sound_manager.dart';


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

class _StoryGameScreenState extends State<StoryGameScreen>
    with TickerProviderStateMixin {
  int? selectedRow;
  int? selectedCol;
  Timer? _gameTimer;
  Timer? _characterMessageTimer;
  int _elapsedTime = 0;
  bool _isInitialized = false;
  
  // Combo system
  int _combo = 0;
  int _comboMax = 0;

  // ✅ NOUVEAU: Indices
  int _hintsRemaining = 3;
  
  // Character messages
  String? _characterMessage;
  late AnimationController _messageAnimController;
  late Animation<double> _messageAnimation;
  
  // Grid animation
  late AnimationController _gridAnimController;
  late Animation<double> _gridScaleAnimation;
  late Animation<double> _gridFadeAnimation;
  
  // Sound manager
  final _soundManager = StorySoundManager();
  
  @override
  void initState() {
    super.initState();
    
    // Setup animations
    _messageAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _messageAnimation = CurvedAnimation(
      parent: _messageAnimController,
      curve: Curves.elasticOut,
    );
    
    _gridAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _gridScaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _gridAnimController, curve: Curves.easeOut),
    );
    _gridFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _gridAnimController, curve: Curves.easeIn),
    );
    
    // Initialize game
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final gameProvider = Provider.of<GameProvider>(context, listen: false);
      _initializeGame(gameProvider);
      
      setState(() {
        _isInitialized = true;
      });
      
      // Start grid animation
      _gridAnimController.forward();
      
      // Start music
      _soundManager.playKingdomMusic(widget.chapter.kingdomId);
      
      // Start game timer
      _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) {
          setState(() {
            _elapsedTime++;
          });
        }
      });
      
      // Start character messages timer
      _startCharacterMessages();
      
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
          _characterMessageTimer?.cancel();
          _showVictoryDialog();
        }
      });
    });
  }
  
  void _startCharacterMessages() {
    _characterMessageTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        _showCharacterMessage();
      }
    });
  }
  
  void _showCharacterMessage() {
    final messages = _getCharacterMessages();
    if (messages.isEmpty) return;
    
    final random = Random();
    setState(() {
      _characterMessage = messages[random.nextInt(messages.length)];
    });
    
    _messageAnimController.forward().then((_) {
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          _messageAnimController.reverse().then((_) {
            if (mounted) {
              setState(() {
                _characterMessage = null;
              });
            }
          });
        }
      });
    });
  }
  
  List<String> _getCharacterMessages() {
    switch (widget.chapter.kingdomId) {
      case 1: // Forêt
        return [
          "🌳 La forêt murmure ses secrets...",
          "🍃 Les arbres anciens te guident.",
          "✨ L'énergie de la nature t'entoure.",
          "🌿 Tu es sur la bonne voie, voyageur.",
        ];
      case 2: // Désert
        return [
          "🏜️ Le vent du désert chante une mélodie oubliée...",
          "💫 Les mirages révèlent la vérité.",
          "✨ Le sable garde la mémoire des âges.",
          "🌅 La sagesse du désert t'illumine.",
        ];
      case 3: // Océan
        return [
          "🌊 Les vagues portent d'anciennes connaissances...",
          "💧 Les profondeurs révèlent leurs mystères.",
          "✨ Le courant te guide vers la vérité.",
          "🐚 L'océan reconnaît ta quête.",
        ];
      case 4: // Montagnes
        return [
          "⛰️ Les sommets percent le voile de l'ignorance...",
          "❄️ La montagne éternelle te teste.",
          "✨ L'air pur clarifie ton esprit.",
          "💎 Les cristaux de glace brillent pour toi.",
        ];
      case 5: // Cosmos
        return [
          "🌌 Les étoiles s'alignent en ta faveur...",
          "⭐ L'univers reconnaît ton potentiel.",
          "✨ Le cosmos dévoile ses secrets.",
          "💫 Tu touches l'infini, chercheur.",
        ];
      default:
        return [];
    }
  }
  
  @override
  void dispose() {
    _gameTimer?.cancel();
    _characterMessageTimer?.cancel();
    _messageAnimController.dispose();
    _gridAnimController.dispose();
    _soundManager.stopMusic();
    super.dispose();
  }
  
  void _initializeGame(GameProvider gameProvider) {
    gameProvider.initializeStoryGame(
      widget.chapter.grid!,
      widget.chapter.solution!,
    );
  }
  
  void _onCellValueChanged(int row, int col, int value, bool isCorrect) {
    if (isCorrect) {
      // Increase combo
      setState(() {
        _combo++;
        if (_combo > _comboMax) _comboMax = _combo;
      });
      
      // Play success sound
      _soundManager.playSound(SoundEffect.correctCell);
      
      // Show combo message
      if (_combo >= 3) {
        _soundManager.playSound(SoundEffect.combo);
      }
    } else {
      // Reset combo
      setState(() {
        _combo = 0;
      });
      
      // Play error sound
      _soundManager.playSound(SoundEffect.wrongCell);
    }
  }

  // ✅ NOUVEAU: Utiliser un indice
  void _useHint(BuildContext context) {
    final gameProvider = Provider.of<GameProvider>(context, listen: false);

    if (_hintsRemaining > 0) {
      // Trouver la première case vide et la remplir
      bool hintUsed = false;
      for (int i = 0; i < 9 && !hintUsed; i++) {
        for (int j = 0; j < 9 && !hintUsed; j++) {
          if (gameProvider.playerGrid[i][j] == 0 &&
              !gameProvider.initialCells[i][j]) {
            final correctValue = widget.chapter.solution![i][j];
            gameProvider.setCellValue(i, j, correctValue);
            setState(() {
              _hintsRemaining--;
            });
            hintUsed = true;

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('💡 Indice utilisé ! Il en reste $_hintsRemaining'),
                backgroundColor: widget.kingdomColor,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      }
    } else {
      // Plus d'indices → proposer pub
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.lightbulb, color: AppColors.yellow, size: 28),
              const SizedBox(width: 12),
              const Text('Plus d\'indices !'),
            ],
          ),
          content: const Text(
            'Vous avez utilisé vos 3 indices.\nRegardez une publicité pour obtenir un indice supplémentaire.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _hintsRemaining = 1;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('📺 Pub regardée - 1 indice accordé !'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              icon: const Icon(Icons.play_arrow, size: 18),
              label: const Text('Regarder une pub'),
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.kingdomColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }
  }
  
  String get _formattedTime {
    final minutes = _elapsedTime ~/ 60;
    final seconds = _elapsedTime % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
  
  @override
  Widget build(BuildContext context) {
    final gameProvider = Provider.of<GameProvider>(context);
    
    if (!_isInitialized || gameProvider.playerGrid.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: widget.kingdomColor,
          foregroundColor: Colors.white,
          title: Text(widget.chapter.title),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: widget.kingdomColor),
              const SizedBox(height: 16),
              Text(
                'Chargement du chapitre...',
                style: TextStyle(
                  color: widget.kingdomColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
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
            // Mute button
            IconButton(
              icon: Icon(_soundManager.isMuted ? Icons.volume_off : Icons.volume_up),
              onPressed: () {
                setState(() {
                  _soundManager.toggleMute();
                });
              },
            ),
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
        body: Stack(
          children: [
            // Particles background
            Positioned.fill(
              child: KingdomParticles(
                kingdomId: widget.chapter.kingdomId,
                kingdomColor: widget.kingdomColor,
              ),
            ),
            
            // Main content
            SafeArea(
              child: Column(
                children: [
                  // Game Stats
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
                              icon: Icons.local_fire_department,
                              label: 'Combo',
                              value: '$_combo',
                              color: _combo >= 3 ? AppColors.orange : widget.kingdomColor,
                            ),
                            // ✅ NOUVEAU: Indices cliquable
                            GestureDetector(
                              onTap: () => _useHint(context),
                              child: _GameStat(
                                icon: Icons.lightbulb_outline,
                                label: 'Indices',
                                value: '$_hintsRemaining',
                                color: _hintsRemaining > 0
                                    ? AppColors.yellow
                                    : AppColors.gray500,
                              ),
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
                        
                        // Combo message
                        if (_combo >= 3) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.orange.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.orange),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.local_fire_department, color: AppColors.orange, size: 16),
                                const SizedBox(width: 8),
                                Text(
                                  'COMBO x$_combo ! 🔥',
                                  style: const TextStyle(
                                    color: AppColors.orange,
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
                  
                  // Sudoku Grid with animation
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: AnimatedBuilder(
                          animation: _gridAnimController,
                          builder: (context, child) {
                            return Opacity(
                              opacity: _gridFadeAnimation.value,
                              child: Transform.scale(
                                scale: _gridScaleAnimation.value,
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: widget.kingdomColor.withOpacity(0.3),
                                        blurRadius: 20,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
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
                            );
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
                        final wasCorrect = gameProvider.playerGrid[selectedRow!][selectedCol!] == 
                            widget.chapter.solution![selectedRow!][selectedCol!];
                        
                        if (number == 0) {
                          gameProvider.clearCell(selectedRow!, selectedCol!);
                        } else {
                          gameProvider.setCellValue(selectedRow!, selectedCol!, number);
                          
                          // Check if correct
                          final isCorrect = number == widget.chapter.solution![selectedRow!][selectedCol!];
                          _onCellValueChanged(selectedRow!, selectedCol!, number, isCorrect);
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
            
            // Character message overlay
            if (_characterMessage != null)
              Positioned(
                top: 100,
                left: 20,
                right: 20,
                child: ScaleTransition(
                  scale: _messageAnimation,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          widget.kingdomColor.withOpacity(0.95),
                          widget.kingdomColor.withOpacity(0.85),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Text(
                      _characterMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ),
              ),
          ],
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
    
    // Play victory sound
    _soundManager.playSound(SoundEffect.victory);
    
    // Calculate stars
    int stars = 1;
    if (_elapsedTime < 300 && mistakes == 0) {
      stars = 3;
    } else if (_elapsedTime < 600 && mistakes < 3) {
      stars = 2;
    }
    
    // Play star sounds
    for (int i = 0; i < stars; i++) {
      Future.delayed(Duration(milliseconds: 300 * i), () {
        _soundManager.playSound(SoundEffect.star);
      });
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
            const SizedBox(height: 8),
            if (_comboMax >= 5)
              Text(
                '🔥 Combo Max: $_comboMax !',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            const SizedBox(height: 16),
            
            // Stars display
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (i) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: Duration(milliseconds: 500 + (i * 200)),
                    curve: Curves.elasticOut,
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: i < stars ? value : 1.0,
                        child: Icon(
                          i < stars ? Icons.star : Icons.star_border,
                          size: 40,
                          color: i < stars ? AppColors.yellow : AppColors.gray300,
                        ),
                      );
                    },
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Combo Max :'),
                      Text(
                        '$_comboMax',
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
                if (result['artifact'] != null) {
                  _soundManager.playSound(SoundEffect.artifact);
                  await _showArtifactDialog(result['artifact']);
                }
                
                if (result['kingdom_completed'] == true) {
                  await _showKingdomCompletedDialog();
                }
                
                Navigator.of(context).pop();
                Navigator.of(context).pop();
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
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 800),
              curve: Curves.elasticOut,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Text(
                    artifact['icon'],
                    style: const TextStyle(fontSize: 80),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
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
    final kingdomNames = [
      '',
      'Forêt Enchantée',
      'Désert des Mirages',
      'Océan des Profondeurs',
      'Montagnes Célestes',
      'Cosmos Éternel',
    ];
    
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
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 1000),
              curve: Curves.elasticOut,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Icon(Icons.castle, size: 80, color: widget.kingdomColor),
                );
              },
            ),
            const SizedBox(height: 16),
            Text(
              kingdomNames[widget.chapter.kingdomId],
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