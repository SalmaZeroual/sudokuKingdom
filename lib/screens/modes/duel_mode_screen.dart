import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/duel_provider.dart';
import '../../../providers/friends_provider.dart';
import '../../../config/theme.dart';
import '../../../config/constants.dart';
import '../../../widgets/difficulty_card.dart';
import '../../../widgets/friend_card.dart';
import '../duel/duel_search_screen.dart';

class DuelModeScreen extends StatefulWidget {
  const DuelModeScreen({Key? key}) : super(key: key);

  @override
  State<DuelModeScreen> createState() => _DuelModeScreenState();
}

class _DuelModeScreenState extends State<DuelModeScreen> {
  
  @override
  void initState() {
    super.initState();
    
    // ✅ Charger les vrais amis au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final friendsProvider = Provider.of<FriendsProvider>(context, listen: false);
      friendsProvider.loadFriends();
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final duelProvider = Provider.of<DuelProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mode Duel'),
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
                    color: AppColors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.sports_kabaddi,
                    color: AppColors.red,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mode Duel',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Affrontez des joueurs en temps réel',
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
                  onTap: () => _searchOpponent(context, 'facile'),
                ),
                DifficultyCard(
                  level: 'Moyen',
                  xp: '${AppConstants.difficultyXP['moyen']} XP',
                  color: AppColors.blue,
                  onTap: () => _searchOpponent(context, 'moyen'),
                ),
                DifficultyCard(
                  level: 'Difficile',
                  xp: '${AppConstants.difficultyXP['difficile']} XP',
                  color: AppColors.orange,
                  onTap: () => _searchOpponent(context, 'difficile'),
                ),
                DifficultyCard(
                  level: 'Extrême',
                  xp: '${AppConstants.difficultyXP['extreme']} XP',
                  color: AppColors.red,
                  onTap: () => _searchOpponent(context, 'extreme'),
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Quick Match
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.red, AppColors.orange],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.red.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Icon(
                    Icons.bolt,
                    color: AppColors.yellow,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Match Rapide',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Trouve un adversaire en ligne',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: duelProvider.isSearching
                        ? null
                        : () => _searchOpponent(context, 'moyen'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.red,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                    ),
                    child: duelProvider.isSearching
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text(
                            'Lancer la recherche',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Challenge Friends
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
                    'Défier un ami',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // ✅ VRAIS AMIS depuis FriendsProvider
                  Consumer<FriendsProvider>(
                    builder: (context, friendsProvider, child) {
                      if (friendsProvider.isLoading) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32.0),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      
                      final friends = friendsProvider.friends;
                      
                      if (friends.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.people_outline,
                                  size: 48,
                                  color: AppColors.gray400,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Aucun ami',
                                  style: TextStyle(
                                    color: AppColors.gray600,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      
                      // Afficher les 3 premiers amis
                      return Column(
                        children: friends.take(3).map((friend) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: FriendCard(
                              name: friend.username,
                              status: friend.isOnline ? 'En ligne' : 'Hors ligne',
                              level: friend.level,
                              onChallenge: () {
                                // TODO: Implémenter le défi d'ami
                                print('Challenge friend ${friend.id}');
                              },
                            ),
                          );
                        }).toList(),
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
  
  void _searchOpponent(BuildContext context, String difficulty) {
    // Navigation vers l'écran de recherche
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DuelSearchScreen(difficulty: difficulty),
      ),
    );
  }
}