import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../../providers/tournament_provider.dart';
import '../../config/theme.dart';
import '../../models/tournament_model.dart';
import 'package:confetti/confetti.dart';

class TournamentResultsScreen extends StatefulWidget {
  final TournamentModel tournament;
  final int score;
  final int time;
  final int mistakes;
  
  const TournamentResultsScreen({
    Key? key,
    required this.tournament,
    required this.score,
    required this.time,
    required this.mistakes,
  }) : super(key: key);

  @override
  State<TournamentResultsScreen> createState() => _TournamentResultsScreenState();
}

class _TournamentResultsScreenState extends State<TournamentResultsScreen> 
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late AnimationController _rotateController;
  
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;
  
  late ConfettiController _confettiController;
  
  int? _myRank;
  bool _isTop3 = false;
  
  @override
  void initState() {
    super.initState();
    
    // Animations
    _fadeController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );
    
    _slideController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1000),
    );
    
    _scaleController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 600),
    );
    
    _rotateController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 2000),
    )..repeat();
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));
    
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );
    
    _rotateAnimation = Tween<double>(begin: 0.0, end: 2 * math.pi).animate(_rotateController);
    
    // Confetti
    _confettiController = ConfettiController(duration: Duration(seconds: 3));
    
    // Start animations
    _fadeController.forward();
    _slideController.forward();
    
    Future.delayed(Duration(milliseconds: 500), () {
      _scaleController.forward();
    });
    
    // Load final leaderboard
    _loadResults();
  }
  
  Future<void> _loadResults() async {
    final tournamentProvider = Provider.of<TournamentProvider>(context, listen: false);
    await tournamentProvider.loadLeaderboard(widget.tournament.id);
    
    // Find my rank
    final leaderboard = tournamentProvider.leaderboard;
    for (int i = 0; i < leaderboard.length; i++) {
      if (leaderboard[i].score == widget.score) {
        setState(() {
          _myRank = i + 1;
          _isTop3 = _myRank != null && _myRank! <= 3;
        });
        
        // Launch confetti if top 3
        if (_isTop3) {
          Future.delayed(Duration(milliseconds: 800), () {
            _confettiController.play();
          });
        }
        break;
      }
    }
  }
  
  String get _formattedTime {
    final minutes = widget.time ~/ 60;
    final seconds = widget.time % 60;
    return '${minutes}:${seconds.toString().padLeft(2, '0')}';
  }
  
  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    _rotateController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tournamentProvider = Provider.of<TournamentProvider>(context);
    
    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: _isTop3
                    ? [AppColors.yellow, AppColors.orange]
                    : [AppColors.blue, AppColors.purple],
              ),
            ),
          ),
          
          // Confetti
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              particleDrag: 0.05,
              emissionFrequency: 0.05,
              numberOfParticles: 30,
              gravity: 0.1,
              shouldLoop: false,
              colors: [
                AppColors.yellow,
                AppColors.orange,
                AppColors.red,
                AppColors.blue,
                AppColors.green,
              ],
            ),
          ),
          
          // Content
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Column(
                  children: [
                    SizedBox(height: 40),
                    
                    // Trophy icon (rotating if top 3)
                    if (_isTop3)
                      AnimatedBuilder(
                        animation: _rotateAnimation,
                        builder: (context, child) {
                          return Transform.rotate(
                            angle: _rotateAnimation.value,
                            child: child,
                          );
                        },
                        child: Icon(
                          Icons.emoji_events,
                          size: 100,
                          color: Colors.white.withOpacity(0.3),
                        ),
                      )
                    else
                      Icon(
                        Icons.emoji_events,
                        size: 80,
                        color: Colors.white.withOpacity(0.3),
                      ),
                    
                    SizedBox(height: 20),
                    
                    // Title
                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: Text(
                        _isTop3 ? 'FÉLICITATIONS !' : 'TOURNOI TERMINÉ',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                    
                    SizedBox(height: 8),
                    
                    // Rank
                    if (_myRank != null)
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_myRank! <= 3)
                                Text(
                                  _getMedal(),
                                  style: TextStyle(fontSize: 24),
                                ),
                              if (_myRank! <= 3) SizedBox(width: 8),
                              Text(
                                '#$_myRank',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: 8),
                              Text(
                                '/ ${widget.tournament.participants}',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white.withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    
                    SizedBox(height: 40),
                    
                    // Stats card
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: Container(
                        padding: EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 20,
                              offset: Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Score
                            _StatRow(
                              icon: Icons.stars,
                              label: 'Score',
                              value: '${widget.score}',
                              color: AppColors.yellow,
                              isLarge: true,
                            ),
                            
                            Divider(height: 32),
                            
                            // Time
                            _StatRow(
                              icon: Icons.timer,
                              label: 'Temps',
                              value: _formattedTime,
                              color: AppColors.blue,
                            ),
                            
                            SizedBox(height: 16),
                            
                            // Mistakes
                            _StatRow(
                              icon: Icons.close,
                              label: 'Erreurs',
                              value: '${widget.mistakes}',
                              color: AppColors.red,
                            ),
                            
                            SizedBox(height: 16),
                            
                            // XP gained
                            _StatRow(
                              icon: Icons.trending_up,
                              label: 'XP Gagné',
                              value: '+${_calculateXP()} XP',
                              color: AppColors.green,
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    SizedBox(height: 24),
                    
                    // Top 3 podium
                    if (tournamentProvider.leaderboard.isNotEmpty)
                      Expanded(
                        child: SingleChildScrollView(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: _PodiumWidget(
                              leaderboard: tournamentProvider.leaderboard.take(3).toList(),
                            ),
                          ),
                        ),
                      ),
                    
                    // Buttons
                    Padding(
                      padding: EdgeInsets.all(24),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.of(context).popUntil((route) => route.isFirst);
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: BorderSide(color: Colors.white, width: 2),
                                padding: EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text('Accueil', style: TextStyle(fontSize: 16)),
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                // Show full leaderboard
                                _showFullLeaderboard(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: _isTop3 ? AppColors.yellow : AppColors.blue,
                                padding: EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text('Classement', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  int _calculateXP() {
    if (_myRank == null) return 100;
    
    if (_myRank == 1) return 500;
    if (_myRank == 2) return 400;
    if (_myRank == 3) return 300;
    if (_myRank! <= 10) return 200;
    if (_myRank! <= 50) return 150;
    return 100;
  }
  
  String _getMedal() {
    switch (_myRank) {
      case 1: return '🥇';
      case 2: return '🥈';
      case 3: return '🥉';
      default: return '';
    }
  }
  
  void _showFullLeaderboard(BuildContext context) {
    final tournamentProvider = Provider.of<TournamentProvider>(context, listen: false);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.gray300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 20),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Icon(Icons.emoji_events, color: AppColors.yellow),
                  SizedBox(width: 12),
                  Text(
                    'Classement Final',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: 24),
                itemCount: tournamentProvider.leaderboard.length,
                itemBuilder: (context, index) {
                  final player = tournamentProvider.leaderboard[index];
                  final isMe = player.score == widget.score;
                  
                  return Container(
                    margin: EdgeInsets.only(bottom: 12),
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isMe ? AppColors.blue.withOpacity(0.1) : AppColors.gray50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isMe ? AppColors.blue : AppColors.gray200,
                        width: isMe ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          '#${index + 1}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppColors.gray600,
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            player.username,
                            style: TextStyle(
                              fontWeight: isMe ? FontWeight.bold : FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          '${player.score}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.yellow,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isLarge;
  
  const _StatRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.isLarge = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: isLarge ? 28 : 20),
        ),
        SizedBox(width: 16),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: isLarge ? 16 : 14,
              color: AppColors.gray600,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isLarge ? 24 : 18,
            fontWeight: FontWeight.bold,
            color: isLarge ? color : AppColors.gray900,
          ),
        ),
      ],
    );
  }
}

class _PodiumWidget extends StatelessWidget {
  final List<TournamentParticipation> leaderboard;
  
  const _PodiumWidget({required this.leaderboard});

  @override
  Widget build(BuildContext context) {
    if (leaderboard.isEmpty) return SizedBox();
    
    final first = leaderboard.length > 0 ? leaderboard[0] : null;
    final second = leaderboard.length > 1 ? leaderboard[1] : null;
    final third = leaderboard.length > 2 ? leaderboard[2] : null;
    
    return Column(
      children: [
        Text(
          'TOP 3',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 2,
          ),
        ),
        SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Second place
            if (second != null)
              _PodiumPlace(
                rank: 2,
                username: second.username,
                score: second.score,
                height: 120,
                medal: '🥈',
              ),
            
            SizedBox(width: 12),
            
            // First place
            if (first != null)
              _PodiumPlace(
                rank: 1,
                username: first.username,
                score: first.score,
                height: 150,
                medal: '🥇',
              ),
            
            SizedBox(width: 12),
            
            // Third place
            if (third != null)
              _PodiumPlace(
                rank: 3,
                username: third.username,
                score: third.score,
                height: 100,
                medal: '🥉',
              ),
          ],
        ),
      ],
    );
  }
}

class _PodiumPlace extends StatelessWidget {
  final int rank;
  final String username;
  final int score;
  final double height;
  final String medal;
  
  const _PodiumPlace({
    required this.rank,
    required this.username,
    required this.score,
    required this.height,
    required this.medal,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Avatar with medal
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: rank == 1 ? 70 : 60,
              height: rank == 1 ? 70 : 60,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: _getRankColor(),
                  width: 3,
                ),
              ),
              child: Center(
                child: Text(
                  username[0].toUpperCase(),
                  style: TextStyle(
                    fontSize: rank == 1 ? 28 : 24,
                    fontWeight: FontWeight.bold,
                    color: _getRankColor(),
                  ),
                ),
              ),
            ),
            Positioned(
              top: -5,
              right: -5,
              child: Text(medal, style: TextStyle(fontSize: rank == 1 ? 32 : 24)),
            ),
          ],
        ),
        
        SizedBox(height: 8),
        
        // Username
        SizedBox(
          width: 80,
          child: Text(
            username,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        
        SizedBox(height: 4),
        
        // Score
        Text(
          '$score',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
        
        SizedBox(height: 8),
        
        // Podium base
        Container(
          width: 80,
          height: height,
          decoration: BoxDecoration(
            color: _getRankColor(),
            borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
          ),
          child: Center(
            child: Text(
              '#$rank',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  Color _getRankColor() {
    switch (rank) {
      case 1: return Color(0xFFFFD700); // Gold
      case 2: return Color(0xFFC0C0C0); // Silver
      case 3: return Color(0xFFCD7F32); // Bronze
      default: return AppColors.gray300;
    }
  }
}