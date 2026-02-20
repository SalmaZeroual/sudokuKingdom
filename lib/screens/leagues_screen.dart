import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../config/theme.dart';

class LeaguesScreen extends StatefulWidget {
  const LeaguesScreen({Key? key}) : super(key: key);

  @override
  State<LeaguesScreen> createState() => _LeaguesScreenState();
}

class _LeaguesScreenState extends State<LeaguesScreen> {
  List<Map<String, dynamic>> _leaderboard = [];
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }
  
  Future<void> _loadLeaderboard() async {
    setState(() => _isLoading = true);
    
    try {
      final apiService = ApiService();
      final response = await apiService.get('/auth/leaderboard/global?limit=100');
      
      setState(() {
        _leaderboard = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading leaderboard: $e');
      setState(() => _isLoading = false);
    }
  }
  
  // ✅ Calculer l'objectif de XP selon la league actuelle
  Map<String, dynamic> _getLeagueProgress(int currentXP, String currentLeague) {
    final leagues = {
      'Bronze': {'min': 0, 'max': 500, 'next': 'Silver'},
      'Silver': {'min': 500, 'max': 1500, 'next': 'Gold'},
      'Gold': {'min': 1500, 'max': 3000, 'next': 'Platinum'},
      'Platinum': {'min': 3000, 'max': 5000, 'next': 'Diamond'},
      'Diamond': {'min': 5000, 'max': 8000, 'next': 'Master'},
      'Master': {'min': 8000, 'max': 12000, 'next': 'Legend'},
      'Legend': {'min': 12000, 'max': 999999, 'next': 'Legend Max'},
    };
    
    final leagueData = leagues[currentLeague] ?? leagues['Bronze']!;
    final min = leagueData['min'] as int;
    final max = leagueData['max'] as int;
    final next = leagueData['next'] as String;
    
    // Progression dans la league actuelle
    final progressInLeague = currentXP - min;
    final totalNeeded = max - min;
    final percentage = (progressInLeague / totalNeeded).clamp(0.0, 1.0);
    
    return {
      'current': progressInLeague,
      'total': totalNeeded,
      'percentage': percentage,
      'nextLeague': next,
      'currentXP': currentXP,
      'targetXP': max,
    };
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    
    // Calculer la progression
    final progress = _getLeagueProgress(user?.xp ?? 0, user?.league ?? 'Bronze');
    
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await _loadLeaderboard();
            await authProvider.loadUser();
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Text(
                  'Ligues',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Affrontez les meilleurs joueurs',
                  style: TextStyle(
                    color: AppColors.gray500,
                    fontSize: 16,
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Current League Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: _getLeagueGradient(user?.league ?? 'Bronze'),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: _getLeagueColor(user?.league ?? 'Bronze').withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Votre Ligue',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${user?.league ?? 'Bronze'} League',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              _getLeagueIcon(user?.league ?? 'Bronze'),
                              style: const TextStyle(fontSize: 40),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Progress to next league
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Progression vers ${progress['nextLeague']}',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                '${progress['currentXP']} / ${progress['targetXP']} pts',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: progress['percentage'],
                              backgroundColor: Colors.white.withOpacity(0.3),
                              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                              minHeight: 10,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${(progress['percentage'] * 100).toInt()}% complété',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // All Leagues
                Text(
                  'Toutes les Ligues',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                _LeagueTile(
                  name: 'Bronze',
                  icon: '🥉',
                  color: const Color(0xFFCD7F32),
                  points: '0 - 500',
                  isCurrentLeague: (user?.league ?? '') == 'Bronze',
                ),
                
                const SizedBox(height: 12),
                
                _LeagueTile(
                  name: 'Silver',
                  icon: '🥈',
                  color: const Color(0xFFC0C0C0),
                  points: '500 - 1,500',
                  isCurrentLeague: (user?.league ?? '') == 'Silver',
                ),
                
                const SizedBox(height: 12),
                
                _LeagueTile(
                  name: 'Gold',
                  icon: '🥇',
                  color: const Color(0xFFFFD700),
                  points: '1,500 - 3,000',
                  isCurrentLeague: (user?.league ?? '') == 'Gold',
                ),
                
                const SizedBox(height: 12),
                
                _LeagueTile(
                  name: 'Platinum',
                  icon: '💎',
                  color: const Color(0xFF00CED1),
                  points: '3,000 - 5,000',
                  isCurrentLeague: (user?.league ?? '') == 'Platinum',
                ),
                
                const SizedBox(height: 12),
                
                _LeagueTile(
                  name: 'Diamond',
                  icon: '💠',
                  color: const Color(0xFF1E90FF),
                  points: '5,000 - 8,000',
                  isCurrentLeague: (user?.league ?? '') == 'Diamond',
                ),
                
                const SizedBox(height: 12),
                
                _LeagueTile(
                  name: 'Master',
                  icon: '👑',
                  color: const Color(0xFF9370DB),
                  points: '8,000 - 12,000',
                  isCurrentLeague: (user?.league ?? '') == 'Master',
                ),
                
                const SizedBox(height: 12),
                
                _LeagueTile(
                  name: 'Legend',
                  icon: '⚡',
                  color: const Color(0xFFFF1493),
                  points: '12,000+',
                  isCurrentLeague: (user?.league ?? '') == 'Legend',
                  isLocked: (user?.xp ?? 0) < 12000,
                ),
                
                const SizedBox(height: 32),
                
                // Global Leaderboard
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Classement Global',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: _loadLeaderboard,
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.gray50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.gray200),
                  ),
                  child: _isLoading
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      : _leaderboard.isEmpty
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(20),
                                child: Text('Aucun classement disponible'),
                              ),
                            )
                          : Column(
                              children: [
                                // Top 3
                                ..._leaderboard.take(3).map((player) {
                                  final rank = player['rank'] as int;
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: _LeaderboardItem(
                                      rank: rank,
                                      name: player['username'],
                                      points: player['xp'],
                                      medal: rank == 1 ? '🥇' : rank == 2 ? '🥈' : '🥉',
                                      highlight: player['id'] == user?.id,
                                    ),
                                  );
                                }).toList(),
                                
                                // Divider si il y a plus de joueurs
                                if (_leaderboard.length > 3) ...[
                                  const Divider(height: 24),
                                  
                                  // Position de l'utilisateur actuel (si pas dans le top 3)
                                  Builder(
                                    builder: (context) {
                                      final userRank = _leaderboard.indexWhere(
                                        (p) => p['id'] == user?.id,
                                      );
                                      
                                      if (userRank >= 3) {
                                        final userData = _leaderboard[userRank];
                                        return _LeaderboardItem(
                                          rank: userData['rank'],
                                          name: 'Vous',
                                          points: userData['xp'],
                                          highlight: true,
                                        );
                                      }
                                      
                                      return const SizedBox.shrink();
                                    },
                                  ),
                                ],
                              ],
                            ),
                ),
                
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  // ✅ Gradient selon la league
  LinearGradient _getLeagueGradient(String league) {
    final color = _getLeagueColor(league);
    return LinearGradient(
      colors: [color, color.withOpacity(0.7)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }
  
  // ✅ Couleur selon la league
  Color _getLeagueColor(String league) {
    switch (league) {
      case 'Bronze': return const Color(0xFFCD7F32);
      case 'Silver': return const Color(0xFFC0C0C0);
      case 'Gold': return const Color(0xFFFFD700);
      case 'Platinum': return const Color(0xFF00CED1);
      case 'Diamond': return const Color(0xFF1E90FF);
      case 'Master': return const Color(0xFF9370DB);
      case 'Legend': return const Color(0xFFFF1493);
      default: return AppColors.purple;
    }
  }
  
  // ✅ Icône selon la league
  String _getLeagueIcon(String league) {
    switch (league) {
      case 'Bronze': return '🥉';
      case 'Silver': return '🥈';
      case 'Gold': return '🥇';
      case 'Platinum': return '💎';
      case 'Diamond': return '💠';
      case 'Master': return '👑';
      case 'Legend': return '⚡';
      default: return '🥉';
    }
  }
}

class _LeagueTile extends StatelessWidget {
  final String name;
  final String icon;
  final Color color;
  final String points;
  final bool isCurrentLeague;
  final bool isLocked;
  
  const _LeagueTile({
    required this.name,
    required this.icon,
    required this.color,
    required this.points,
    this.isCurrentLeague = false,
    this.isLocked = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCurrentLeague ? color.withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrentLeague ? color : AppColors.gray200,
          width: isCurrentLeague ? 2 : 1,
        ),
        boxShadow: isCurrentLeague
            ? [
                BoxShadow(
                  color: color.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              icon,
              style: const TextStyle(fontSize: 32),
            ),
          ),
          
          const SizedBox(width: 16),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '$name League',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isLocked ? AppColors.gray500 : AppColors.gray900,
                      ),
                    ),
                    if (isCurrentLeague) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'ACTUELLE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                    if (isLocked) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.lock, size: 16, color: AppColors.gray500),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '$points pts',
                  style: TextStyle(
                    color: AppColors.gray500,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          
          if (isCurrentLeague)
            Icon(Icons.check_circle, color: color, size: 28),
        ],
      ),
    );
  }
}

class _LeaderboardItem extends StatelessWidget {
  final int rank;
  final String name;
  final int points;
  final String? medal;
  final bool highlight;
  
  const _LeaderboardItem({
    required this.rank,
    required this.name,
    required this.points,
    this.medal,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: highlight ? AppColors.blue.withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: highlight ? AppColors.blue : AppColors.gray200,
          width: highlight ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(
              medal ?? '#$rank',
              style: TextStyle(
                fontSize: medal != null ? 24 : 18,
                fontWeight: FontWeight.bold,
                color: highlight ? AppColors.blue : AppColors.gray700,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          const SizedBox(width: 12),
          
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                fontSize: 16,
                fontWeight: highlight ? FontWeight.bold : FontWeight.w600,
                color: AppColors.gray900,
              ),
            ),
          ),
          
          Text(
            '$points pts',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.yellow,
            ),
          ),
        ],
      ),
    );
  }
}