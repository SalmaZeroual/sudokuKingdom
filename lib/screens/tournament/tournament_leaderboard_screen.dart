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
  State<TournamentLeaderboardScreen> createState() =>
      _TournamentLeaderboardScreenState();
}

class _TournamentLeaderboardScreenState
    extends State<TournamentLeaderboardScreen> {
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
        builder: (context, provider, _) {
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
                  _buildTournamentHeader(),
                  const SizedBox(height: 24),

                  // ── Toggle Mondial / Amis ──────────────────────────
                  _buildLeaderboardToggle(provider),
                  const SizedBox(height: 24),

                  if (provider.leaderboard.isNotEmpty) _buildPodium(provider),
                  const SizedBox(height: 24),

                  _buildLeaderboard(provider),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── Toggle mondial / amis ─────────────────────────────────────────────

  Widget _buildLeaderboardToggle(TournamentProvider provider) {
    final isGlobal = provider.leaderboardType == 'global';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.gray100,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          // Bouton Mondial
          Expanded(
            child: GestureDetector(
              onTap: () => provider.setLeaderboardType('global'),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isGlobal ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: isGlobal
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.public,
                      size: 18,
                      color: isGlobal ? AppColors.blue : AppColors.gray500,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Mondial',
                      style: TextStyle(
                        fontWeight: isGlobal
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isGlobal ? AppColors.blue : AppColors.gray500,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bouton Amis
          Expanded(
            child: GestureDetector(
              onTap: () => provider.setLeaderboardType('friends'),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: !isGlobal ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: !isGlobal
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.people,
                      size: 18,
                      color: !isGlobal ? AppColors.purple : AppColors.gray500,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Amis',
                      style: TextStyle(
                        fontWeight: !isGlobal
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: !isGlobal ? AppColors.purple : AppColors.gray500,
                        fontSize: 14,
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

  // ─── Header tournoi ───────────────────────────────────────────────────

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
              const Icon(Icons.emoji_events, color: Colors.white, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.tournament.name,
                  style: const TextStyle(
                    fontSize: 20,
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
              _HeaderStat(
                label: 'Participants',
                value: '${widget.tournament.participants}',
              ),
              _HeaderStat(
                label: 'Temps restant',
                value: widget.tournament.timeRemainingFormatted,
                align: CrossAxisAlignment.end,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Podium ───────────────────────────────────────────────────────────

  Widget _buildPodium(TournamentProvider provider) {
    final top3 = provider.getTop3();
    if (top3.isEmpty) return const SizedBox.shrink();

    final first = top3[0];
    final second = top3.length > 1 ? top3[1] : null;
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
          Text(
            provider.leaderboardType == 'friends'
                ? '🏆 TOP AMIS 🏆'
                : '🏆 PODIUM 🏆',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.yellow,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
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
        Text(medal, style: const TextStyle(fontSize: 40)),
        const SizedBox(height: 8),
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
        Text(
          participation.scoreLabel,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.gray600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, color.withOpacity(0.7)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
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

  // ─── Liste classement ─────────────────────────────────────────────────

  Widget _buildLeaderboard(TournamentProvider provider) {
    if (provider.leaderboard.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            children: [
              Icon(Icons.emoji_events_outlined, size: 64, color: AppColors.gray300),
              const SizedBox(height: 16),
              Text(
                provider.leaderboardType == 'friends'
                    ? 'Aucun ami n\'a encore participé'
                    : 'Aucune participation pour l\'instant',
                style: TextStyle(fontSize: 16, color: AppColors.gray500),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final remaining = provider.leaderboard.length > 3
        ? provider.leaderboard.skip(3).toList()
        : <TournamentParticipation>[];

    final currentUserParticipation =
        provider.getCurrentUserParticipation(_currentUserId ?? 0);

    final showCurrentUser = currentUserParticipation != null &&
        currentUserParticipation.rank > 3 &&
        !remaining.any((p) => p.userId == _currentUserId);

    if (remaining.isEmpty && !showCurrentUser) return const SizedBox.shrink();

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
          Text(
            'Classement',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...remaining.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildLeaderboardItem(
                  p,
                  isCurrentUser: p.userId == _currentUserId,
                ),
              )),
          if (showCurrentUser && remaining.isNotEmpty)
            const Divider(height: 32),
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
        color: highlight ? AppColors.blue.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: highlight ? AppColors.blue : AppColors.gray200,
          width: highlight ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
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
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ),
          const SizedBox(width: 16),
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
                  participation.timeLabel,
                  style: TextStyle(fontSize: 12, color: AppColors.gray600),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: participation.hasScore
                  ? AppColors.yellow.withOpacity(0.1)
                  : AppColors.gray100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              participation.scoreLabel,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: participation.hasScore ? AppColors.yellow : AppColors.gray500,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

// ─── Petits widgets helpers ────────────────────────────────────────────────

class _HeaderStat extends StatelessWidget {
  final String label;
  final String value;
  final CrossAxisAlignment align;

  const _HeaderStat({
    required this.label,
    required this.value,
    this.align = CrossAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: align,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}