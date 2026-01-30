import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/friends_provider.dart';
import '../../services/api_service.dart';
import '../../config/theme.dart';

class FriendProfileScreen extends StatefulWidget {
  final int friendId;
  
  const FriendProfileScreen({
    Key? key,
    required this.friendId,
  }) : super(key: key);

  @override
  State<FriendProfileScreen> createState() => _FriendProfileScreenState();
}

class _FriendProfileScreenState extends State<FriendProfileScreen> {
  final ApiService _apiService = ApiService();
  
  Map<String, dynamic>? _friendData;
  bool _isLoading = true;
  String? _error;
  
  @override
  void initState() {
    super.initState();
    _loadFriendProfile();
  }
  
  Future<void> _loadFriendProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      final response = await _apiService.get('/social/friends/${widget.friendId}/stats');
      setState(() {
        _friendData = response;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil de l\'ami'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'remove') {
                _showRemoveFriendDialog();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'remove',
                child: Row(
                  children: [
                    Icon(Icons.person_remove, size: 20, color: AppColors.red),
                    SizedBox(width: 12),
                    Text('Retirer cet ami', style: TextStyle(color: AppColors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState()
              : _buildProfileContent(),
    );
  }
  
  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: AppColors.red),
          const SizedBox(height: 16),
          Text(
            'Erreur de chargement',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.gray700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? 'Une erreur est survenue',
            style: TextStyle(color: AppColors.gray500),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadFriendProfile,
            icon: const Icon(Icons.refresh),
            label: const Text('Réessayer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildProfileContent() {
    final user = _friendData!['user'];
    final stats = _friendData!['stats'];
    
    return SingleChildScrollView(
      child: Column(
        children: [
          // Header avec avatar et infos principales
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.blue, AppColors.purple],
              ),
            ),
            child: Column(
              children: [
                // Avatar
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(50),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.person,
                    size: 56,
                    color: AppColors.blue,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Username
                Text(
                  user['username'],
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Level badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Niveau ${user['level']}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Stats cards
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // XP et Ligue
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.stars,
                        iconColor: AppColors.yellow,
                        title: 'XP Total',
                        value: '${user['xp']}',
                        gradient: [AppColors.yellow.withOpacity(0.1), AppColors.yellow.withOpacity(0.05)],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.military_tech,
                        iconColor: _getLeagueColor(user['league']),
                        title: 'Ligue',
                        value: user['league'],
                        gradient: [AppColors.purple.withOpacity(0.1), AppColors.purple.withOpacity(0.05)],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Titre statistiques de jeu
                Text(
                  '📊 Statistiques de jeu',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.gray400,
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Parties jouées
                _buildStatRow(
                  icon: Icons.videogame_asset,
                  iconColor: AppColors.blue,
                  label: 'Parties totales',
                  value: '${stats['total_games'] ?? 0}',
                ),
                
                const SizedBox(height: 12),
                
                // Parties complétées
                _buildStatRow(
                  icon: Icons.check_circle,
                  iconColor: AppColors.green,
                  label: 'Parties terminées',
                  value: '${stats['completed_games'] ?? 0}',
                ),
                
                const SizedBox(height: 12),
                
                // Temps moyen
                _buildStatRow(
                  icon: Icons.timer,
                  iconColor: AppColors.orange,
                  label: 'Temps moyen',
                  value: _formatTime(stats['avg_time']),
                ),
                
                const SizedBox(height: 12),
                
                // Meilleur temps
                _buildStatRow(
                  icon: Icons.speed,
                  iconColor: AppColors.purple,
                  label: 'Meilleur temps',
                  value: _formatTime(stats['best_time']),
                ),
                
                const SizedBox(height: 24),
                
                // Taux de réussite
                if (stats['total_games'] != null && stats['total_games'] > 0)
                  _buildSuccessRateCard(stats),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required List<Color> gradient,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 32),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.gray600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.gray400,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.gray700,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.gray400,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSuccessRateCard(Map<String, dynamic> stats) {
    final total = stats['total_games'] ?? 0;
    final completed = stats['completed_games'] ?? 0;
    final rate = total > 0 ? (completed / total * 100).toStringAsFixed(1) : '0.0';
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.green.withOpacity(0.1), AppColors.green.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.green.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.green.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.trending_up,
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
                  'Taux de réussite',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.gray600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$rate%',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.green,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '($completed/$total)',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.gray500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  String _formatTime(dynamic seconds) {
    if (seconds == null) return 'N/A';
    
    final int totalSeconds = (seconds is double) ? seconds.round() : (seconds as int);
    final minutes = totalSeconds ~/ 60;
    final secs = totalSeconds % 60;
    
    if (minutes > 0) {
      return '${minutes}m ${secs}s';
    } else {
      return '${secs}s';
    }
  }
  
  Color _getLeagueColor(String league) {
    if (league.contains('Bronze')) return const Color(0xFFCD7F32);
    if (league.contains('Silver')) return const Color(0xFFC0C0C0);
    if (league.contains('Gold')) return const Color(0xFFFFD700);
    if (league.contains('Platinum')) return const Color(0xFFE5E4E2);
    if (league.contains('Diamond')) return const Color(0xFFB9F2FF);
    if (league.contains('Master')) return const Color(0xFF9B59B6);
    return AppColors.gray500;
  }
  
  void _showRemoveFriendDialog() {
    final user = _friendData!['user'];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Retirer cet ami ?'),
        content: Text('Êtes-vous sûr de vouloir retirer ${user['username']} de vos amis ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              
              final friendsProvider = Provider.of<FriendsProvider>(context, listen: false);
              final success = await friendsProvider.removeFriend(widget.friendId);
              
              if (context.mounted) {
                if (success) {
                  Navigator.of(context).pop(); // Retour à la liste des amis
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Ami retiré avec succès'),
                      backgroundColor: AppColors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Erreur lors de la suppression'),
                      backgroundColor: AppColors.red,
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.red),
            child: const Text('Retirer'),
          ),
        ],
      ),
    );
  }
}