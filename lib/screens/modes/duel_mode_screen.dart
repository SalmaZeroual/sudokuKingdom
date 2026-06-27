import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../providers/duel_provider.dart';
import '../../../providers/friends_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../config/theme.dart';
import '../../../config/constants.dart';
import '../../../widgets/difficulty_card.dart';
import '../../../widgets/friend_card.dart';
import '../../../widgets/offline_state.dart';
import '../../../models/friend_model.dart';
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Défier un ami',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      // ✅ Petite icône "ajouter ami" en haut de la section
                      IconButton(
                        icon: const Icon(Icons.person_add_alt_1, color: AppColors.green),
                        tooltip: 'Ajouter un ami',
                        onPressed: () => _showExternalInviteSheet(context),
                      ),
                    ],
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

                      // ✅ Bug corrigé : une coupure réseau affichait
                      // "Aucun ami" comme si la liste était réellement vide.
                      if (friendsProvider.isOffline && friends.isEmpty) {
                        return OfflineState(
                          message: 'Impossible de charger vos amis pour le moment.',
                          onRetry: () => friendsProvider.loadFriends(),
                        );
                      }

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
                                const SizedBox(height: 12),
                                TextButton.icon(
                                  onPressed: () => _showExternalInviteSheet(context),
                                  icon: const Icon(Icons.share),
                                  label: const Text('Inviter un ami'),
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
                              onChallenge: () => _showDifficultyDialog(context, friend),
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

  // ✅ Bouton "Défier" — fait exactement le même travail que sur l'écran Amis :
  // choisir une difficulté puis envoyer une invitation de duel.
  void _showDifficultyDialog(BuildContext context, FriendModel friend) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.sports_kabaddi, color: AppColors.red),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Défier ${friend.username}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text('Choisissez la difficulté :'),
              const SizedBox(height: 16),
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _DifficultyButton(
                          label: 'Facile',
                          color: AppColors.green,
                          onTap: () {
                            Navigator.of(ctx).pop();
                            _inviteToDuel(context, friend, 'facile');
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _DifficultyButton(
                          label: 'Moyen',
                          color: AppColors.blue,
                          onTap: () {
                            Navigator.of(ctx).pop();
                            _inviteToDuel(context, friend, 'moyen');
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _DifficultyButton(
                          label: 'Difficile',
                          color: AppColors.orange,
                          onTap: () {
                            Navigator.of(ctx).pop();
                            _inviteToDuel(context, friend, 'difficile');
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _DifficultyButton(
                          label: 'Extrême',
                          color: AppColors.red,
                          onTap: () {
                            Navigator.of(ctx).pop();
                            _inviteToDuel(context, friend, 'extreme');
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.center,
                child: TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Annuler'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _inviteToDuel(BuildContext context, FriendModel friend, String difficulty) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Envoi de l\'invitation...'),
            ],
          ),
        ),
      ),
    );

    try {
      final duelProvider = Provider.of<DuelProvider>(context, listen: false);
      await duelProvider.challengeFriend(friend.id, difficulty);

      if (context.mounted) {
        Navigator.of(context).pop(); // fermer le dialog de chargement
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => DuelSearchScreen(
              difficulty: difficulty,
              isInvitation: true,
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: AppColors.red,
        ));
      }
    }
  }

  // ✅ Inviter un ami HORS de l'app (WhatsApp, Facebook, SMS...). Le message
  // contient le pseudo et l'ID unique de l'inviteur pour que le destinataire
  // puisse l'ajouter facilement une fois l'app installée.
  void _showExternalInviteSheet(BuildContext context) {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    final username = user?.username ?? 'un joueur';
    final uniqueId = user?.uniqueId;

    final text = StringBuffer()
      ..writeln('🎮 $username te défie sur Sudoku Kingdom !')
      ..writeln()
      ..writeln('Télécharge l\'app et ajoute-moi pour qu\'on s\'affronte en duel 👊')
      ..writeln(uniqueId != null ? 'Mon ID : $uniqueId' : 'Recherche-moi : $username')
      ..writeln()
      ..writeln('📲 https://sudokukingdom.app/download');

    Share.share(text.toString(), subject: 'Rejoins-moi sur Sudoku Kingdom !');
  }
}

// Petit bouton de difficulté réutilisé pour le dialogue de défi
class _DifficultyButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _DifficultyButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Text(label),
    );
  }
}