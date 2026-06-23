// lib/widgets/achievement_share_card.dart

import 'package:flutter/material.dart';

enum ShareCardType { classic, tournament, duel }

class ShareCardData {
  final ShareCardType type;
  final String difficulty;
  final String time;
  final int score;
  final int mistakes;
  final String username;
  final int level;
  final int? rank;
  final int? totalPlayers;
  static const String appLink =
      'https://play.google.com/store/apps/details?id=com.sudoku.kingdom';

  const ShareCardData({
    required this.type,
    required this.difficulty,
    required this.time,
    required this.score,
    required this.mistakes,
    required this.username,
    required this.level,
    this.rank,
    this.totalPlayers,
  });

  String get typeLabel {
    switch (type) {
      case ShareCardType.classic:    return 'CLASSIQUE';
      case ShareCardType.tournament: return 'TOURNOI';
      case ShareCardType.duel:       return 'DUEL';
    }
  }

  List<Color> get gradient {
    switch (type) {
      case ShareCardType.classic:
        return [const Color(0xFF059669), const Color(0xFF064E3B)];
      case ShareCardType.tournament:
        return [const Color(0xFFF59E0B), const Color(0xFF92400E)];
      case ShareCardType.duel:
        return [const Color(0xFFEF4444), const Color(0xFF7F1D1D)];
    }
  }

  Color get accent {
    switch (type) {
      case ShareCardType.classic:    return const Color(0xFF6EE7B7);
      case ShareCardType.tournament: return const Color(0xFFFDE68A);
      case ShareCardType.duel:       return const Color(0xFFFCA5A5);
    }
  }

  String get emoji {
    switch (type) {
      case ShareCardType.classic:    return '🎯';
      case ShareCardType.tournament: return '🏆';
      case ShareCardType.duel:       return '⚔️';
    }
  }

  String get difficultyEmoji {
    switch (difficulty.toLowerCase()) {
      case 'facile':    return '🟢';
      case 'moyen':     return '🔵';
      case 'difficile': return '🟠';
      case 'extrême':
      case 'extreme':   return '🔴';
      default:          return '⚪';
    }
  }
}

/// Widget rendu via RepaintBoundary → export PNG 3×
class AchievementShareCard extends StatelessWidget {
  final ShareCardData data;
  const AchievementShareCard({Key? key, required this.data}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 360,
      height: 200,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: data.gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: data.gradient[0].withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Déco cercles
          Positioned(top: -30, right: -20,
              child: _circle(140, 0.07)),
          Positioned(bottom: -40, left: -15,
              child: _circle(160, 0.05)),

          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Top : badge + branding ──────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _Badge(emoji: data.emoji, label: data.typeLabel),
                    Row(children: [
                      const Icon(Icons.castle, color: Colors.white, size: 13),
                      const SizedBox(width: 4),
                      Text('Sudoku Kingdom',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.88),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          )),
                    ]),
                  ],
                ),

                const Spacer(),

                // ── Stats ────────────────────────────────────────────
                Row(children: [
                  _Stat(icon: Icons.timer_outlined,         value: data.time,          label: 'TEMPS',   accent: data.accent),
                  const SizedBox(width: 16),
                  _Stat(icon: Icons.star_outline,           value: '${data.score}',    label: 'SCORE',   accent: data.accent),
                  const SizedBox(width: 16),
                  _Stat(icon: Icons.close,                  value: '${data.mistakes}', label: 'ERREURS', accent: data.accent),
                  if (data.rank != null) ...[
                    const SizedBox(width: 16),
                    _Stat(icon: Icons.emoji_events_outlined, value: '#${data.rank}',   label: 'RANG',    accent: data.accent),
                  ],
                ]),

                const Spacer(),

                // ── Bottom : username + level + lien ─────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Text(data.difficultyEmoji,
                                style: const TextStyle(fontSize: 11)),
                            const SizedBox(width: 4),
                            Text(data.difficulty,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.78),
                                  fontSize: 11,
                                )),
                            const SizedBox(width: 8),
                            Text('Niv. ${data.level}',
                                style: TextStyle(
                                  color: data.accent,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                )),
                          ]),
                          const SizedBox(height: 3),
                          Text('@${data.username}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              )),
                        ]),
                    // Bouton "Jouer aussi"
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.28)),
                      ),
                      child: Column(children: [
                        const Icon(Icons.download_rounded,
                            color: Colors.white, size: 15),
                        const SizedBox(height: 2),
                        Text('Jouer aussi',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.88),
                              fontSize: 8,
                              fontWeight: FontWeight.w600,
                            )),
                      ]),
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

  Widget _circle(double size, double opacity) => Container(
        width: size, height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(opacity),
        ),
      );
}

// ── Sous-widgets ─────────────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  final String emoji, label;
  const _Badge({required this.emoji, required this.label});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.18),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.32)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(emoji, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 5),
          Text(label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 10,
                letterSpacing: 1.0,
              )),
        ]),
      );
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final String value, label;
  final Color accent;
  const _Stat(
      {required this.icon,
      required this.value,
      required this.label,
      required this.accent});
  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accent, size: 13),
          const SizedBox(height: 2),
          Text(value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.bold,
                height: 1,
              )),
          Text(label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 8,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.6,
              )),
        ],
      );
}