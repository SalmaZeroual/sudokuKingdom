import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/game_provider.dart';
import '../config/theme.dart';
import '../widgets/mode_card.dart';
import '../widgets/stat_card.dart';
import '../widgets/avatar_widget.dart'; 
import 'modes/classic_mode_screen.dart';
import 'modes/duel_mode_screen.dart';
import 'modes/tournament_mode_screen.dart';
import 'modes/story_mode_screen.dart';
import 'social/friends_screen.dart';
import 'chat/conversations_screen.dart';
import 'leagues_screen.dart';
import 'auth/login_screen.dart';
import 'auth/register_screen.dart';
import 'profile_screen.dart';
import 'game/game_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  
  late final List<Widget> _screens;
  
  @override
  void initState() {
    super.initState();
    _screens = [
      const _HomeContent(),
      const FriendsScreen(),
      const ConversationsScreen(),
      const LeaguesScreen(),
      const ProfileScreen(),
    ];
  }

  // ✅ GUEST: onglets nécessitant un compte (tout sauf Accueil index=0)
  void _onTabTap(BuildContext context, int index) {
    if (index != 0) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (auth.isGuest) {
        _showGuestDialog(context);
        return;
      }
    }
    setState(() => _currentIndex = index);
  }

  void _showGuestDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(children: [
          Icon(Icons.lock_outline, color: AppColors.blue),
          SizedBox(width: 10),
          Text('Compte requis'),
        ]),
        content: const Text(
          'Cette section est réservée aux joueurs inscrits.\n\nCrée un compte gratuit pour accéder à toutes les fonctionnalités !',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Pas maintenant'),
          ),
          // ✅ FIX: → RegisterScreen directement, pas LoginScreen
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const RegisterScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Créer un compte'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => _onTabTap(context, index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.blue,
        unselectedItemColor: AppColors.gray500,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.castle),
            label: 'Accueil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Amis',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.message),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.emoji_events),
            label: 'Ligues',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}

class _HomeContent extends StatefulWidget {
  const _HomeContent();

  @override
  State<_HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<_HomeContent> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForActiveGame();
    });
  }
  
  // ✅ GUEST: carte d'invitation à créer un compte
  Widget _buildGuestCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E293B), Color(0xFF334155)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_outline, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Mode invité',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Crée un compte pour sauvegarder tes scores, jouer en Duel et Tournoi !',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.75),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            // ✅ FIX: → RegisterScreen directement
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const RegisterScreen()),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.blue,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Créer\nun compte',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ GUEST: dialog affiché quand invité tente d'accéder à un mode restreint
  void _showGuestDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.lock_outline, color: AppColors.blue),
            SizedBox(width: 10),
            Text('Compte requis'),
          ],
        ),
        content: const Text(
          'Ce mode est réservé aux joueurs inscrits.\n\nCrée un compte gratuit pour accéder au Duel, Tournoi, Énigme, Amis et Messages !',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Pas maintenant'),
          ),
          // ✅ FIX: → RegisterScreen directement
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const RegisterScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Créer un compte'),
          ),
        ],
      ),
    );
  }

  Future<void> _checkForActiveGame() async {
    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    final hasActiveGame = await gameProvider.checkForActiveGame();
    
    if (hasActiveGame && mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.play_circle_outline, color: AppColors.green, size: 28),
              SizedBox(width: 12),
              Text('Partie en cours'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Vous avez une partie en cours :'),
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
                        Text('Temps écoulé:', style: TextStyle(color: AppColors.gray500)),
                        Text(
                          gameProvider.formattedTime,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Erreurs:', style: TextStyle(color: AppColors.gray500)),
                        Text(
                          '${gameProvider.mistakes}',
                          style: TextStyle(fontWeight: FontWeight.bold),
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
              onPressed: () async {
                await gameProvider.abandonGame();
                if (mounted) {
                  Navigator.of(context).pop();
                }
              },
              child: Text('Abandonner', style: TextStyle(color: AppColors.red)),
            ),
            ElevatedButton(
              onPressed: () {
                gameProvider.resumeGame();
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => GameScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.green,
                foregroundColor: Colors.white,
              ),
              child: Text('Reprendre'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final isGuest = authProvider.isGuest;
    
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.castle,
                      color: AppColors.blue,
                      size: 40,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Sudoku Kingdom',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                // ✅ GUEST: bouton connexion si invité, XP si connecté
                if (isGuest)
                  GestureDetector(
                    onTap: () => Navigator.of(context).pushNamed('/login'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.blue,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.person_outline, color: Colors.white, size: 18),
                          SizedBox(width: 6),
                          Text(
                            'Connexion',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.gray50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.gray200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.star, color: AppColors.yellow, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '${user?.xp ?? 0} XP',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.gray900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // ✅ GUEST: carte invité ou carte stats selon l'état
            if (isGuest)
              _buildGuestCard(context)
            else
            // Player Stats Card
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.blue, AppColors.purple],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.blue.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.username ?? 'Joueur',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Niveau ${user?.level ?? 1} - ${user?.rank ?? 'Apprenti'}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      // ✅ MODIFIÉ : Avatar au lieu de l'icône château
                      AvatarWidget(
                        avatarId: user?.avatar,
                        size: 56,
                        showBorder: true,
                        borderWidth: 2,
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          icon: Icons.emoji_events,
                          value: '${user?.wins ?? 0}',
                          label: 'Victoires',
                          iconColor: AppColors.yellow,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StatCard(
                          icon: Icons.local_fire_department,
                          value: '${user?.streak ?? 0}',
                          label: 'Série',
                          iconColor: AppColors.orange,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StatCard(
                          icon: Icons.workspace_premium,
                          value: user?.league ?? 'Bronze',
                          label: 'Ligue',
                          iconColor: AppColors.purple,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Game Modes
            Text(
              'Modes de Jeu',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 16),
            
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.1,
              children: [
                ModeCard(
                  icon: Icons.grid_on,
                  title: 'Classique',
                  subtitle: 'Mode progression RPG',
                  gradient: const [AppColors.green, Color(0xFF059669)],
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ClassicModeScreen()),
                    );
                  },
                ),
                ModeCard(
                  icon: Icons.sports_kabaddi,
                  title: 'Duel',
                  subtitle: 'Affrontement temps réel',
                  gradient: const [AppColors.red, AppColors.orange],
                  onTap: () {
                    // ✅ GUEST: Duel nécessite un compte
                    if (isGuest) {
                      _showGuestDialog(context);
                      return;
                    }
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const DuelModeScreen()),
                    );
                  },
                ),
                ModeCard(
                  icon: Icons.emoji_events,
                  title: 'Tournoi',
                  subtitle: 'Classement mondial',
                  gradient: const [AppColors.yellow, Color(0xFFF59E0B)],
                  onTap: () {
                    // ✅ GUEST: Tournoi nécessite un compte
                    if (isGuest) {
                      _showGuestDialog(context);
                      return;
                    }
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const TournamentModeScreen()),
                    );
                  },
                ),
                ModeCard(
                  icon: Icons.auto_stories,
                  title: 'Énigme',
                  subtitle: 'Histoire & aventure',
                  gradient: const [AppColors.purple, Color(0xFF7C3AED)],
                  onTap: () {
                    // ✅ GUEST: Énigme nécessite un compte
                    if (isGuest) {
                      _showGuestDialog(context);
                      return;
                    }
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const StoryModeScreen()),
                    );
                  },
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Daily Challenge
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.orange, AppColors.red],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.orange.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Défi Quotidien',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Grille spéciale 🎃',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(Icons.access_time, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        '08:45',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}