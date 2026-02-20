import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/tournament_provider.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../models/tournament_model.dart';

class TournamentLeaderboardScreen extends StatefulWidget {
  final TournamentModel tournament;
  
  const TournamentLeaderboardScreen({
    Key? key,
    required this.tournament,
  }) : super(key: key);

  @override
  State<TournamentLeaderboardScreen> createState() => _TournamentLeaderboardScreenState();
}

class _TournamentLeaderboardScreenState extends State<TournamentLeaderboardScreen> {
  int? _currentUserId;
  
  @override
  void initState() {
    super.initState();
    _loadCurrentUserId();
    _loadLeaderboard();
  }
  
  Future<void> _loadCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentUserId = prefs.getInt(AppConstants.userIdKey);
    });
  }
  
  Future<void> _loadLeaderboard() async {
    final provider = Provider.of<TournamentProvider>(context, listen: false);
    await provider.loadLeaderboard(widget.tournament.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Classement'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLeaderboard,
          ),
        ],
      ),
      body: Consumer<TournamentProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          return RefreshIndicator(
            onRefresh: _loadLeaderboard,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tournament header
                  _buildTournamentHeader(),
                  
                  const SizedBox(height: 32),
                  
                  // Podium (Top 3)
                  if (provider.leaderboard.isNotEmpty)
                    _buildPodium(provider),
                  
                  const SizedBox(height: 32),
                  
                  // Remaining leaderboard
                  _buildLeaderboard(provider),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildTournamentHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.yellow, Color(0xFFF59E0B)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.yellow.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.emoji_events,
                color: Colors.white,
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.tournament.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Participants',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${widget.tournament.participants}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Temps restant',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.tournament.timeRemainingFormatted,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildPodium(TournamentProvider provider) {
    final top3 = provider.getTop3();
    
    if (top3.isEmpty) {
      return const SizedBox.shrink();
    }
    
    // Préparer les positions (2ème, 1er, 3ème)
    final second = top3.length > 1 ? top3[1] : null;
    final first = top3[0];
    final third = top3.length > 2 ? top3[2] : null;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.yellow.withOpacity(0.1),
            AppColors.orange.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.yellow.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          const Text(
            '🏆 PODIUM 🏆',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.yellow,
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Podium layout
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // 2nd place
              if (second != null)
                Expanded(
                  child: _buildPodiumPlace(
                    rank: 2,
                    participation: second,
                    height: 100,
                    medal: '🥈',
                    color: const Color(0xFFC0C0C0),
                  ),
                ),
              
              const SizedBox(width: 12),
              
              // 1st place
              Expanded(
                child: _buildPodiumPlace(
                  rank: 1,
                  participation: first,
                  height: 140,
                  medal: '🥇',
                  color: const Color(0xFFFFD700),
                ),
              ),
              
              const SizedBox(width: 12),
              
              // 3rd place
              if (third != null)
                Expanded(
                  child: _buildPodiumPlace(
                    rank: 3,
                    participation: third,
                    height: 80,
                    medal: '🥉',
                    color: const Color(0xFFCD7F32),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildPodiumPlace({
    required int rank,
    required TournamentParticipation participation,
    required double height,
    required String medal,
    required Color color,
  }) {
    final isCurrentUser = participation.userId == _currentUserId;
    
    return Column(
      children: [
        // Medal
        Text(
          medal,
          style: const TextStyle(fontSize: 40),
        ),
        
        const SizedBox(height: 8),
        
        // Username
        Text(
          isCurrentUser ? 'Vous' : participation.username,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isCurrentUser ? AppColors.blue : AppColors.gray900,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        
        const SizedBox(height: 4),
        
        // Score
        Text(
          '${participation.score} pts',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.gray600,
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Podium base
        Container(
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, color.withOpacity(0.7)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(8),
            ),
            border: Border.all(
              color: isCurrentUser ? AppColors.blue : Colors.transparent,
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              '#$rank',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildLeaderboard(TournamentProvider provider) {
    if (provider.leaderboard.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            children: [
              Icon(
                Icons.emoji_events_outlined,
                size: 64,
                color: AppColors.gray300,
              ),
              const SizedBox(height: 16),
              Text(
                'Aucune participation pour l\'instant',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.gray500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    
    // Afficher à partir du 4ème
    final remaining = provider.leaderboard.length > 3
        ? provider.leaderboard.skip(3).toList()
        : <TournamentParticipation>[];
    
    // Ajouter la position de l'utilisateur actuel s'il n'est pas dans le top 3
    final currentUserParticipation = provider.getCurrentUserParticipation(_currentUserId ?? 0);
    final showCurrentUser = currentUserParticipation != null &&
        currentUserParticipation.rank > 3 &&
        !remaining.any((p) => p.userId == _currentUserId);
    
    if (remaining.isEmpty && !showCurrentUser) {
      return const SizedBox.shrink();
    }
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gray200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Classement',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Liste des autres positions
          ...remaining.map((participation) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildLeaderboardItem(
                participation,
                isCurrentUser: participation.userId == _currentUserId,
              ),
            );
          }).toList(),
          
          // Séparateur si on affiche l'utilisateur en dehors du top
          if (showCurrentUser && remaining.isNotEmpty) ...[
            const Divider(height: 32),
          ],
          
          // Position de l'utilisateur actuel
          if (showCurrentUser)
            _buildLeaderboardItem(
              currentUserParticipation,
              isCurrentUser: true,
              highlight: true,
            ),
        ],
      ),
    );
  }
  
  Widget _buildLeaderboardItem(
    TournamentParticipation participation, {
    bool isCurrentUser = false,
    bool highlight = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: highlight
            ? AppColors.blue.withOpacity(0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: highlight ? AppColors.blue : AppColors.gray200,
          width: highlight ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          // Rank
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.gray100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                '#${participation.rank}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Name
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isCurrentUser ? 'Vous' : participation.username,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: highlight ? AppColors.blue : AppColors.gray900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatTime(participation.time),
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.gray600,
                  ),
                ),
              ],
            ),
          ),
          
          // Score
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.yellow.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${participation.score} pts',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.yellow,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  String _formatTime(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$secs';
  }
}