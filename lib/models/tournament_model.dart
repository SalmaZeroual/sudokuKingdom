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
  });
  
  factory TournamentModel.fromJson(Map<String, dynamic> json) {
    return TournamentModel(
      id: json['id'],
      name: json['name'],
      grid: (json['grid'] as List).map((row) => List<int>.from(row)).toList(),
      solution: (json['solution'] as List).map((row) => List<int>.from(row)).toList(),
      difficulty: json['difficulty'],
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date']),
      status: json['status'],
      participants: json['participants'] ?? 0,
    );
  }
  
  Duration get timeRemaining {
    return endDate.difference(DateTime.now());
  }
  
  String get timeRemainingFormatted {
    final duration = timeRemaining;
    final days = duration.inDays;
    final hours = duration.inHours % 24;
    final minutes = duration.inMinutes % 60;
    return '${days}j ${hours}h ${minutes}m';
  }
}

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
      id: json['id'],
      tournamentId: json['tournament_id'],
      userId: json['user_id'],
      username: json['username'],
      score: json['score'],
      time: json['time'],
      rank: json['rank'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}