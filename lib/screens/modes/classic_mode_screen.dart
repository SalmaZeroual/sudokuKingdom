import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/game_provider.dart';
import '../../../config/theme.dart';
import '../../../config/constants.dart';
import '../../../widgets/difficulty_card.dart';
import '../../../widgets/booster_card.dart';
import '../../screens/game/game_screen.dart';

class ClassicModeScreen extends StatelessWidget {
  const ClassicModeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final gameProvider = Provider.of<GameProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mode Classique'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.grid_on,
                    color: AppColors.green,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mode Classique Progressif',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Montez de niveau comme dans un RPG',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.gray500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Difficulty Selection
            Text(
              'Choisissez la difficulté',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 16),
            
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: [
                DifficultyCard(
                  level: 'Facile',
                  xp: '${AppConstants.difficultyXP['facile']} XP',
                  color: AppColors.green,
                  onTap: () => _startGame(context, 'facile'),
                ),
                DifficultyCard(
                  level: 'Moyen',
                  xp: '${AppConstants.difficultyXP['moyen']} XP',
                  color: AppColors.blue,
                  onTap: () => _startGame(context, 'moyen'),
                ),
                DifficultyCard(
                  level: 'Difficile',
                  xp: '${AppConstants.difficultyXP['difficile']} XP',
                  color: AppColors.orange,
                  onTap: () => _startGame(context, 'difficile'),
                ),
                DifficultyCard(
                  level: 'Extrême',
                  xp: '${AppConstants.difficultyXP['extreme']} XP',
                  color: AppColors.red,
                  onTap: () => _startGame(context, 'extreme'),
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Boosters Available
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.gray50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.gray200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Boosters Disponibles',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  gameProvider.boosters.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: Text('Aucun booster disponible'),
                          ),
                        )
                      : GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 0.9,
                          ),
                          itemCount: gameProvider.boosters.length,
                          itemBuilder: (context, index) {
                            final booster = gameProvider.boosters[index];
                            return BoosterCard(
                              icon: booster.icon,
                              name: booster.displayName,
                              count: booster.quantity,
                            );
                          },
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _startGame(BuildContext context, String difficulty) async {
    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(),
      ),
    );
    
    await gameProvider.startNewGame(AppConstants.modeClassic, difficulty);
    
    if (context.mounted) {
      Navigator.of(context).pop(); // Close loading
      
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const GameScreen(),
        ),
      );
    }
  }
}