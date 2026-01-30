import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../config/theme.dart';

class LeaguesScreen extends StatelessWidget {
  const LeaguesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    
    return Scaffold(
      body: SafeArea(
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
                  gradient: const LinearGradient(
                    colors: [AppColors.purple, Color(0xFF7C3AED)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.purple.withOpacity(0.3),
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
                              user?.league ?? 'Bronze I',
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
                          child: const Icon(
                            Icons.workspace_premium,
                            color: AppColors.yellow,
                            size: 48,
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
                              'Progression vers Silver I',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              '${user?.xp ?? 0} / 500 pts',
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
                            value: (user?.xp ?? 0) / 500,
                            backgroundColor: Colors.white.withOpacity(0.3),
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                            minHeight: 10,
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
                isCurrentLeague: (user?.league ?? '').contains('Bronze'),
              ),
              
              const SizedBox(height: 12),
              
              _LeagueTile(
                name: 'Silver',
                icon: '🥈',
                color: const Color(0xFFC0C0C0),
                points: '500 - 1,500',
                isCurrentLeague: (user?.league ?? '').contains('Silver'),
              ),
              
              const SizedBox(height: 12),
              
              _LeagueTile(
                name: 'Gold',
                icon: '🥇',
                color: const Color(0xFFFFD700),
                points: '1,500 - 3,000',
                isCurrentLeague: (user?.league ?? '').contains('Gold'),
              ),
              
              const SizedBox(height: 12),
              
              _LeagueTile(
                name: 'Platinum',
                icon: '💎',
                color: const Color(0xFF00CED1),
                points: '3,000 - 5,000',
                isCurrentLeague: (user?.league ?? '').contains('Platinum'),
              ),
              
              const SizedBox(height: 12),
              
              _LeagueTile(
                name: 'Diamond',
                icon: '💠',
                color: const Color(0xFF1E90FF),
                points: '5,000 - 8,000',
                isCurrentLeague: (user?.league ?? '').contains('Diamond'),
              ),
              
              const SizedBox(height: 12),
              
              _LeagueTile(
                name: 'Master',
                icon: '👑',
                color: const Color(0xFF9370DB),
                points: '8,000 - 12,000',
                isCurrentLeague: (user?.league ?? '').contains('Master'),
              ),
              
              const SizedBox(height: 12),
              
              _LeagueTile(
                name: 'Legend',
                icon: '⚡',
                color: const Color(0xFFFF1493),
                points: '12,000+',
                isCurrentLeague: (user?.league ?? '').contains('Legend'),
                isLocked: (user?.xp ?? 0) < 12000,
              ),
              
              const SizedBox(height: 32),
              
              // Weekly Leaderboard
              Text(
                'Classement Hebdomadaire',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 16),
              
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.gray50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.gray200),
                ),
                child: Column(
                  children: [
                    _LeaderboardItem(
                      rank: 1,
                      name: 'DragonMaster',
                      points: 2450,
                      medal: '🥇',
                    ),
                    const SizedBox(height: 12),
                    _LeaderboardItem(
                      rank: 2,
                      name: 'SudokuPro',
                      points: 2380,
                      medal: '🥈',
                    ),
                    const SizedBox(height: 12),
                    _LeaderboardItem(
                      rank: 3,
                      name: 'PuzzleKing',
                      points: 2310,
                      medal: '🥉',
                    ),
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 12),
                    _LeaderboardItem(
                      rank: 47,
                      name: user?.username ?? 'Vous',
                      points: user?.xp ?? 0,
                      highlight: true,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
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