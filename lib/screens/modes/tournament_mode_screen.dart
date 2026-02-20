import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/tournament_provider.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../models/tournament_model.dart';
import '../tournament/tournament_game_screen.dart';
import '../tournament/tournament_leaderboard_screen.dart';

class TournamentModeScreen extends StatefulWidget {
  const TournamentModeScreen({Key? key}) : super(key: key);

  @override
  State<TournamentModeScreen> createState() => _TournamentModeScreenState();
}

class _TournamentModeScreenState extends State<TournamentModeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TournamentProvider>(context, listen: false).loadTournaments();
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tournois'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              Provider.of<TournamentProvider>(context, listen: false).loadTournaments();
            },
          ),
        ],
      ),
      body: Consumer<TournamentProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          return RefreshIndicator(
            onRefresh: () => provider.loadTournaments(),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  _buildHeader(),
                  
                  const SizedBox(height: 32),
                  
                  // Info
                  _buildInfoCard(),
                  
                  const SizedBox(height: 32),
                  
                  // Difficulty Selection (Tournaments)
                  Text(
                    'Choisissez votre niveau',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Grid with 4 tournaments
                  _buildTournamentsGrid(provider),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.yellow.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.emoji_events,
            color: AppColors.yellow,
            size: 32,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tournois Hebdomadaires',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Affrontez les meilleurs joueurs',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.gray500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.blue.withOpacity(0.1), AppColors.purple.withOpacity(0.1)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.blue.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: AppColors.blue, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Chaque tournoi dure 1 semaine. Vous pouvez participer une seule fois par niveau !',
              style: TextStyle(
                color: AppColors.gray700,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTournamentsGrid(TournamentProvider provider) {
    // Créer 4 cartes pour chaque difficulté
    final difficulties = [
      {'level': 'Facile', 'difficulty': 'facile', 'color': AppColors.green, 'xp': '50'},
      {'level': 'Moyen', 'difficulty': 'moyen', 'color': AppColors.blue, 'xp': '100'},
      {'level': 'Difficile', 'difficulty': 'difficile', 'color': AppColors.orange, 'xp': '150'},
      {'level': 'Extrême', 'difficulty': 'extreme', 'color': AppColors.red, 'xp': '200'},
    ];
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: difficulties.length,
      itemBuilder: (context, index) {
        final diff = difficulties[index];
        final tournament = provider.getTournamentByDifficulty(diff['difficulty'] as String);
        final hasJoined = tournament != null && provider.hasJoinedTournament(tournament.id);
        
        return _buildTournamentCard(
          level: diff['level'] as String,
          difficulty: diff['difficulty'] as String,
          color: diff['color'] as Color,
          xp: diff['xp'] as String,
          tournament: tournament,
          hasJoined: hasJoined,
          provider: provider,
        );
      },
    );
  }
  
  Widget _buildTournamentCard({
    required String level,
    required String difficulty,
    required Color color,
    required String xp,
    required TournamentModel? tournament,
    required bool hasJoined,
    required TournamentProvider provider,
  }) {
    return GestureDetector(
      onTap: () => _handleTournamentTap(tournament, difficulty, hasJoined, provider),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withOpacity(0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Main content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Trophy icon
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.emoji_events,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  
                  const Spacer(),
                  
                  // Level name
                  Text(
                    level,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // XP
                  Text(
                    '$xp XP',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Participants
                  if (tournament != null) ...[
                    Row(
                      children: [
                        Icon(
                          Icons.people,
                          size: 14,
                          color: Colors.white.withOpacity(0.9),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${tournament.participants} joueurs',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ],
                  
                  const SizedBox(height: 12),
                  
                  // Button
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        hasJoined ? 'Jouer' : 'Participer',
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Badge "Inscrit"
            if (hasJoined)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    '✓',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _handleTournamentTap(
    TournamentModel? tournament,
    String difficulty,
    bool hasJoined,
    TournamentProvider provider,
  ) async {
    // Si pas de tournoi, afficher message
    if (tournament == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Aucun tournoi $difficulty actif pour le moment'),
          backgroundColor: AppColors.orange,
        ),
      );
      return;
    }
    
    // Si déjà inscrit, aller directement au jeu
    if (hasJoined) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => TournamentGameScreen(tournament: tournament),
        ),
      );
      return;
    }
    
    // Sinon, demander confirmation pour participer
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rejoindre le tournoi ?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tournoi ${tournament.name}'),
            const SizedBox(height: 8),
            Text('${tournament.participants} participants'),
            const SizedBox(height: 8),
            Text('Temps restant: ${tournament.timeRemainingFormatted}'),
            const SizedBox(height: 16),
            const Text(
              '⚠️ Vous ne pourrez participer qu\'une seule fois !',
              style: TextStyle(
                color: AppColors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.yellow,
            ),
            child: const Text('Participer'),
          ),
        ],
      ),
    );
    
    if (confirmed != true || !mounted) return;
    
    // Rejoindre le tournoi
    final success = await provider.joinTournament(tournament.id);
    
    if (!mounted) return;
    
    if (success) {
      // Aller au jeu
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => TournamentGameScreen(tournament: tournament),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Erreur lors de l\'inscription'),
          backgroundColor: AppColors.red,
        ),
      );
    }
  }
}