// ============================================================
// lib/models/tournament_model.dart
// ============================================================

class TournamentModel {
  final int id;
  final String name;
  final List<List<int>> grid;
  final List<List<int>> solution;
  final String difficulty;
  final DateTime startDate;
  final DateTime endDate;
  final String status;
  final int participants;
  /// Vrai si l'utilisateur connecté a déjà rejoint ce tournoi aujourd'hui.
  /// Renvoyé par le backend quand le token est envoyé avec /tournament/list.
  final bool userHasJoined;

  TournamentModel({
    required this.id,
    required this.name,
    required this.grid,
    required this.solution,
    required this.difficulty,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.participants,
    this.userHasJoined = false,
  });

  factory TournamentModel.fromJson(Map<String, dynamic> json) {
    return TournamentModel(
      id: json['id'],
      name: json['name'],
      grid: (json['grid'] as List)
          .map((row) => List<int>.from(row))
          .toList(),
      solution: (json['solution'] as List)
          .map((row) => List<int>.from(row))
          .toList(),
      difficulty: json['difficulty'],
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date']),
      status: json['status'],
      participants: json['participants'] ?? 0,
      userHasJoined: json['user_has_joined'] == true,
    );
  }

  // ── Temps restant jusqu'à la fin du tournoi (minuit) ──────────────────

  Duration get timeRemaining {
    final remaining = endDate.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Format court : "14h 23m" ou "00h 05m" pour les dernières minutes
  String get timeRemainingFormatted {
    final duration = timeRemaining;
    if (duration == Duration.zero) return 'Terminé';

    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    if (hours > 0) return '${hours}h ${minutes}m';
    return '${minutes}m';
  }

  /// Format long HH:MM:SS pour le compte à rebours live
  String get timeRemainingCountdown {
    final duration = timeRemaining;
    if (duration == Duration.zero) return '00:00:00';

    final h = duration.inHours.toString().padLeft(2, '0');
    final m = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final s = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  bool get isActive => status == 'active' && timeRemaining > Duration.zero;

  /// Libellé humain de la difficulté
  String get difficultyLabel {
    switch (difficulty.toLowerCase()) {
      case 'facile':    return 'Facile';
      case 'moyen':     return 'Moyen';
      case 'difficile': return 'Difficile';
      case 'extreme':   return 'Extrême';
      default:          return difficulty;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class TournamentParticipation {
  final int id;
  final int tournamentId;
  final int userId;
  final String username;
  final int score;
  final int time;
  final int rank;
  final DateTime createdAt;

  TournamentParticipation({
    required this.id,
    required this.tournamentId,
    required this.userId,
    required this.username,
    required this.score,
    required this.time,
    required this.rank,
    required this.createdAt,
  });

  factory TournamentParticipation.fromJson(Map<String, dynamic> json) {
    return TournamentParticipation(
      id: json['id'] ?? 0,
      tournamentId: json['tournament_id'] ?? 0,
      userId: json['user_id'] ?? 0,
      username: json['username'] ?? 'Inconnu',
      score: json['score'] ?? 0,
      time: json['time'] ?? 0,
      rank: json['rank'] ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  /// Vrai si le joueur a soumis un score (partie terminée)
  bool get hasScore => score > 0;

  /// Affichage du score : points ou "En cours..." si pas encore terminé
  String get scoreLabel => hasScore ? '$score pts' : 'En cours…';

  /// Affichage du temps : "mm:ss" ou "—" si pas encore terminé
  String get timeLabel {
    if (!hasScore) return '—';
    final m = (time ~/ 60).toString().padLeft(2, '0');
    final s = (time % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}