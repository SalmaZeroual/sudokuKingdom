import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../../providers/duel_provider.dart';
import '../../config/theme.dart';
import 'duel_game_screen.dart';

class DuelSearchScreen extends StatefulWidget {
  final String difficulty;
  
  const DuelSearchScreen({
    Key? key,
    required this.difficulty,
  }) : super(key: key);

  @override
  State<DuelSearchScreen> createState() => _DuelSearchScreenState();
}

class _DuelSearchScreenState extends State<DuelSearchScreen> 
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  
  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    
    // Start searching
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startSearch();
    });
  }
  
  Future<void> _startSearch() async {
    final duelProvider = Provider.of<DuelProvider>(context, listen: false);
    
    try {
      await duelProvider.searchForOpponent(widget.difficulty);
      
      // Listen for duel found
      _listenForDuel();
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
        Navigator.of(context).pop();
      }
    }
  }
  
  void _listenForDuel() {
    // Poll for duel status
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (!mounted) return false;
      
      final duelProvider = Provider.of<DuelProvider>(context, listen: false);
      
      if (duelProvider.currentDuel != null && duelProvider.isDuelActive) {
        // Duel found! Navigate to game screen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const DuelGameScreen(),
          ),
        );
        return false;
      }
      
      return duelProvider.isSearching;
    });
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final duelProvider = Provider.of<DuelProvider>(context, listen: false);
        duelProvider.cancelSearch(widget.difficulty);
        return true;
      },
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.red,
                AppColors.orange,
                AppColors.red,
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // App bar
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () {
                          final duelProvider = Provider.of<DuelProvider>(
                            context, 
                            listen: false,
                          );
                          duelProvider.cancelSearch(widget.difficulty);
                          Navigator.of(context).pop();
                        },
                      ),
                      const Expanded(
                        child: Text(
                          'Recherche d\'adversaire',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 48), // Balance the back button
                    ],
                  ),
                ),
                
                // Content
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Animated swords
                      SizedBox(
                        width: 200,
                        height: 200,
                        child: AnimatedBuilder(
                          animation: _animationController,
                          builder: (context, child) {
                            return Stack(
                              alignment: Alignment.center,
                              children: [
                                // Left sword
                                Transform.translate(
                                  offset: Offset(
                                    -50 * math.sin(_animationController.value * math.pi * 2),
                                    0,
                                  ),
                                  child: Transform.rotate(
                                    angle: -math.pi / 4,
                                    child: const Icon(
                                      Icons.sports_kabaddi,
                                      size: 80,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                // Right sword
                                Transform.translate(
                                  offset: Offset(
                                    50 * math.sin(_animationController.value * math.pi * 2),
                                    0,
                                  ),
                                  child: Transform.rotate(
                                    angle: math.pi / 4,
                                    child: const Icon(
                                      Icons.sports_kabaddi,
                                      size: 80,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Loading text
                      const Text(
                        'Recherche en cours...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Difficulty badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.5),
                            width: 2,
                          ),
                        ),
                        child: Text(
                          _getDifficultyLabel(widget.difficulty),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 48),
                      
                      // Animated dots
                      AnimatedBuilder(
                        animation: _animationController,
                        builder: (context, child) {
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(3, (index) {
                              final delay = index * 0.33;
                              final opacity = (math.sin(
                                (_animationController.value + delay) * math.pi * 2
                              ) + 1) / 2;
                              
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withOpacity(opacity),
                                  ),
                                ),
                              );
                            }),
                          );
                        },
                      ),
                      
                      const SizedBox(height: 48),
                      
                      // Tips
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 32),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.lightbulb_outline,
                              color: AppColors.yellow,
                              size: 32,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _getRandomTip(),
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Cancel button
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: ElevatedButton(
                    onPressed: () {
                      final duelProvider = Provider.of<DuelProvider>(
                        context,
                        listen: false,
                      );
                      duelProvider.cancelSearch(widget.difficulty);
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.red,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 48,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text(
                      'Annuler',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  String _getDifficultyLabel(String difficulty) {
    switch (difficulty) {
      case 'facile':
        return '🟢 Facile';
      case 'moyen':
        return '🟡 Moyen';
      case 'difficile':
        return '🟠 Difficile';
      case 'extreme':
        return '🔴 Extrême';
      default:
        return difficulty;
    }
  }
  
  String _getRandomTip() {
    final tips = [
      '💡 Astuce: 3 erreurs et vous êtes éliminé !',
      '⚡ Le premier à terminer gagne le duel',
      '🎯 Restez concentré sur votre grille',
      '🚀 La vitesse compte, mais la précision aussi',
      '💪 Utilisez vos stratégies classiques',
      '🧠 Analysez avant de placer un chiffre',
    ];
    
    return tips[math.Random().nextInt(tips.length)];
  }
}