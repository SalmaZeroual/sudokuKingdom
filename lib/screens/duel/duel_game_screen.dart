import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../providers/duel_provider.dart';
import '../../providers/friends_provider.dart';
import '../../config/theme.dart';
import '../../widgets/sudoku_grid.dart';
import '../../widgets/number_pad.dart';
import '../duel/duel_game_screen.dart';

class DuelGameScreen extends StatefulWidget {
  const DuelGameScreen({Key? key}) : super(key: key);

  @override
  State<DuelGameScreen> createState() => _DuelGameScreenState();
}

class _DuelGameScreenState extends State<DuelGameScreen> with TickerProviderStateMixin {
  int? selectedRow;
  int? selectedCol;
  
  late AnimationController _warningController;
  late Animation<double> _warningAnimation;
  
  @override
  void initState() {
    super.initState();
    
    // Animation pour le bandeau d'avertissement
    _warningController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
    
    _warningAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _warningController, curve: Curves.easeInOut),
    );
  }
  
  @override
  void dispose() {
    _warningController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Consumer<DuelProvider>(
      builder: (context, duelProvider, child) {
        final duel = duelProvider.currentDuel;
        
        if (duel == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        
        // Check if duel finished
        if (duel.status == 'finished') {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showResultDialog(context, duelProvider);
          });
        }
        
        // Check if eliminated
        if (duelProvider.isEliminated) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showEliminatedDialog(context);
          });
        }
        
        return WillPopScope(
          onWillPop: () async {
            final shouldPop = await _showExitDialog(context);
            if (shouldPop == true) {
              duelProvider.abandonDuel();
            }
            return shouldPop ?? false;
          },
          child: Scaffold(
            body: Stack(
              children: [
                // Main content
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.center,
                      colors: [AppColors.red, Colors.white],
                      stops: [0.0, 0.3],
                    ),
                  ),
                  child: SafeArea(
                    child: Column(
                      children: [
                        // Header with timer
                        _buildHeader(duelProvider),
                        
                        // Players progress bars
                        _buildProgressBars(duelProvider, duel),
                        
                        // Opponent message overlay
                        if (duelProvider.lastOpponentMessage != null)
                          _buildOpponentMessage(duelProvider.lastOpponentMessage!),
                        
                        // Sudoku Grid
                        Expanded(
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: SudokuGrid(
                                grid: duelProvider.playerGrid,
                                initialCells: duelProvider.initialCells,
                                errorCells: duelProvider.errorCells,
                                notes: List.generate(9, (_) => List.generate(9, (_) => <int>{})),
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
                        
                        // Action buttons (messages, add friend)
                        _buildActionButtons(duelProvider),
                        
                        // Number Pad
                        NumberPad(
                          isNoteMode: false,
                          grid: duelProvider.playerGrid,
                          onNumberTap: (number) {
                            if (selectedRow != null && selectedCol != null) {
                              if (number == 0) {
                                duelProvider.clearCell(selectedRow!, selectedCol!);
                              } else {
                                duelProvider.setCellValue(selectedRow!, selectedCol!, number);
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                
                // ⚠️ BANDEAU D'AVERTISSEMENT (flottant en haut)
                if (duelProvider.myMistakes >= 2)
                  _buildWarningBanner(duelProvider.myMistakes),
              ],
            ),
          ),
        );
      },
    );
  }
  
  // ⚠️ BANDEAU D'AVERTISSEMENT ROUGE/NOIR
  Widget _buildWarningBanner(int mistakes) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: AnimatedBuilder(
          animation: _warningAnimation,
          builder: (context, child) {
            return Opacity(
              opacity: _warningAnimation.value,
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.black, AppColors.red],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.red, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.red.withOpacity(0.5),
                      blurRadius: 15,
                      spreadRadius: 2,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Icône d'avertissement animée
                    ScaleTransition(
                      scale: _warningAnimation,
                      child: const Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // Texte
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            mistakes == 2 ? 'ATTENTION !' : 'DANGER !',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            mistakes == 2 
                                ? 'Encore 1 erreur = ÉLIMINATION'
                                : 'Prochaine erreur = ÉLIMINATION',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Compteur de vies
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${3 - mistakes}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            '❤️',
                            style: TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
  
  Widget _buildHeader(DuelProvider duelProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () async {
              final shouldExit = await _showExitDialog(context);
              if (shouldExit == true && mounted) {
                duelProvider.abandonDuel();
                Navigator.of(context).pop();
              }
            },
          ),
          
          // Timer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.access_time, size: 18, color: AppColors.red),
                const SizedBox(width: 8),
                Text(
                  duelProvider.formattedTime,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.gray900,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 48), // Balance
        ],
      ),
    );
  }
  
  Widget _buildProgressBars(DuelProvider duelProvider, duel) {
    final myProgress = duelProvider.myProgress;
    final opponentProgress = duelProvider.opponentProgress;
    final myMistakes = duelProvider.myMistakes;
    final opponentMistakes = duelProvider.opponentMistakes;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Player 1 (Me)
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.blue,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(Icons.person, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Vous',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          '$myProgress% • ${3 - myMistakes} ❤️',
                          style: TextStyle(
                            color: myMistakes >= 2 ? AppColors.red : AppColors.gray600,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: myProgress / 100,
                        backgroundColor: AppColors.gray200,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          myMistakes >= 2 ? AppColors.orange : AppColors.blue,
                        ),
                        minHeight: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // VS Divider
          Row(
            children: [
              const Expanded(child: Divider()),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'VS',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Expanded(child: Divider()),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Player 2 (Opponent)
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.red,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(Icons.person, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          duel.player2Name ?? 'En attente...',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          '$opponentProgress% • ${3 - opponentMistakes} ❤️',
                          style: TextStyle(
                            color: opponentMistakes >= 2 ? AppColors.red : AppColors.gray600,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: opponentProgress / 100,
                        backgroundColor: AppColors.gray200,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          opponentMistakes >= 2 ? AppColors.orange : AppColors.red,
                        ),
                        minHeight: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildOpponentMessage(String message) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.red,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.red.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.message, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text(
            message,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildActionButtons(DuelProvider duelProvider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Quick messages button
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                _showQuickMessagesDialog(context, duelProvider);
              },
              icon: const Icon(Icons.message_outlined, size: 18),
              label: const Text('Messages'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Add friend button
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                _addOpponentAsFriend(context, duelProvider);
              },
              icon: const Icon(Icons.person_add_outlined, size: 18),
              label: const Text('Ajouter ami'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  void _showQuickMessagesDialog(BuildContext context, DuelProvider duelProvider) {
    final messages = [
      '👍 Bien joué !',
      '💪 Tu es fort !',
      '😎 Facile',
      '🔥 En feu !',
      '⚡ Trop rapide',
      '🎯 Précis',
    ];
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Messages rapides',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: messages.map((msg) {
                return ElevatedButton(
                  onPressed: () {
                    duelProvider.sendQuickMessage(msg);
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Message envoyé: $msg'),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gray100,
                    foregroundColor: AppColors.gray900,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  child: Text(msg),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _addOpponentAsFriend(BuildContext context, DuelProvider duelProvider) async {
    final duel = duelProvider.currentDuel;
    if (duel == null) return;
    
    final opponentId = duel.player2Id;
    
    if (opponentId == null) return;
    
    try {
      final friendsProvider = Provider.of<FriendsProvider>(context, listen: false);
      await friendsProvider.sendFriendRequest(opponentId);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Demande d\'ami envoyée !'),
            backgroundColor: AppColors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }
  
  Future<bool?> _showExitDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Abandonner le duel ?'),
        content: const Text(
          '⚠️ Vous perdrez automatiquement si vous quittez.\n\n'
          'Votre adversaire gagnera par forfait.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Continuer'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.red),
            child: const Text('Abandonner'),
          ),
        ],
      ),
    );
  }
  
  void _showResultDialog(BuildContext context, DuelProvider duelProvider) {
    final duel = duelProvider.currentDuel!;
    final isWinner = duel.winnerId == duel.player1Id;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              isWinner ? Icons.emoji_events : Icons.sentiment_dissatisfied,
              color: isWinner ? AppColors.yellow : AppColors.gray500,
              size: 32,
            ),
            const SizedBox(width: 12),
            Text(isWinner ? '🎉 Victoire !' : '😔 Défaite'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isWinner 
                  ? 'Félicitations ! Vous avez battu ${duel.player2Name} !'
                  : '${duel.player2Name} a gagné cette fois.',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.gray100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildStatRow('⏱️ Temps', duelProvider.formattedTime),
                  const SizedBox(height: 8),
                  _buildStatRow('❌ Erreurs', '${duelProvider.myMistakes}/3'),
                  const SizedBox(height: 8),
                  _buildStatRow('📊 Progression', '${duelProvider.myProgress}%'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              duelProvider.abandonDuel();
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Retour'),
          ),
          if (isWinner)
            ElevatedButton(
              onPressed: () {
                duelProvider.abandonDuel();
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.blue,
              ),
              child: const Text('Revanche !'),
            ),
        ],
      ),
    );
  }
  
  void _showEliminatedDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: AppColors.red, size: 32),
            SizedBox(width: 12),
            Text('⚠️ Éliminé !'),
          ],
        ),
        content: const Text(
          '3 erreurs atteintes !\n\n'
          'Vous avez été éliminé du duel.\n'
          'Votre adversaire remporte la victoire.',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              final duelProvider = Provider.of<DuelProvider>(context, listen: false);
              duelProvider.abandonDuel();
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.red,
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}