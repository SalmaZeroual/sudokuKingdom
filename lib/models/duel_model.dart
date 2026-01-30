class DuelModel {
  final int? id;
  final int player1Id;
  final int? player2Id;
  final String player1Name;
  final String? player2Name;
  final List<List<int>> grid;
  final List<List<int>> solution;
  final String difficulty;
  final int? winnerId;
  final String status;
  final DateTime createdAt;
  
  // Progress tracking
  final int player1Progress;
  final int player2Progress;
  final int player1Mistakes;
  final int player2Mistakes;
  
  DuelModel({
    this.id,
    required this.player1Id,
    this.player2Id,
    required this.player1Name,
    this.player2Name,
    required this.grid,
    required this.solution,
    required this.difficulty,
    this.winnerId,
    this.status = 'waiting',
    required this.createdAt,
    this.player1Progress = 0,
    this.player2Progress = 0,
    this.player1Mistakes = 0,
    this.player2Mistakes = 0,
  });
  
  factory DuelModel.fromJson(Map<String, dynamic> json) {
    return DuelModel(
      id: json['id'],
      player1Id: json['player1_id'],
      player2Id: json['player2_id'],
      player1Name: json['player1_name'],
      player2Name: json['player2_name'],
      grid: (json['grid'] as List).map((row) => List<int>.from(row)).toList(),
      solution: (json['solution'] as List).map((row) => List<int>.from(row)).toList(),
      difficulty: json['difficulty'],
      winnerId: json['winner_id'],
      status: json['status'] ?? 'waiting',
      createdAt: DateTime.parse(json['created_at']),
      player1Progress: json['player1_progress'] ?? 0,
      player2Progress: json['player2_progress'] ?? 0,
      player1Mistakes: json['player1_mistakes'] ?? 0,
      player2Mistakes: json['player2_mistakes'] ?? 0,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'player1_id': player1Id,
      'player2_id': player2Id,
      'player1_name': player1Name,
      'player2_name': player2Name,
      'grid': grid,
      'solution': solution,
      'difficulty': difficulty,
      'winner_id': winnerId,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'player1_progress': player1Progress,
      'player2_progress': player2Progress,
      'player1_mistakes': player1Mistakes,
      'player2_mistakes': player2Mistakes,
    };
  }
}