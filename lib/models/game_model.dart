class GameModel {
  final int? id;
  final int userId;
  final List<List<int>> grid;
  final List<List<int>> solution;
  final String difficulty;
  final String mode;
  final String status;
  final int timeElapsed;
  final int mistakes;
  final DateTime createdAt;
  final DateTime? completedAt;
  
  GameModel({
    this.id,
    required this.userId,
    required this.grid,
    required this.solution,
    required this.difficulty,
    required this.mode,
    this.status = 'in_progress',
    this.timeElapsed = 0,
    this.mistakes = 0,
    required this.createdAt,
    this.completedAt,
  });
  
  factory GameModel.fromJson(Map<String, dynamic> json) {
    return GameModel(
      id: json['id'],
      userId: json['user_id'],
      grid: (json['grid'] as List).map((row) => List<int>.from(row)).toList(),
      solution: (json['solution'] as List).map((row) => List<int>.from(row)).toList(),
      difficulty: json['difficulty'],
      mode: json['mode'],
      status: json['status'] ?? 'in_progress',
      timeElapsed: json['time_elapsed'] ?? 0,
      mistakes: json['mistakes'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
      completedAt: json['completed_at'] != null 
          ? DateTime.parse(json['completed_at']) 
          : null,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'grid': grid,
      'solution': solution,
      'difficulty': difficulty,
      'mode': mode,
      'status': status,
      'time_elapsed': timeElapsed,
      'mistakes': mistakes,
      'created_at': createdAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
    };
  }
  
  GameModel copyWith({
    List<List<int>>? grid,
    String? status,
    int? timeElapsed,
    int? mistakes,
    DateTime? completedAt,
  }) {
    return GameModel(
      id: id,
      userId: userId,
      grid: grid ?? this.grid,
      solution: solution,
      difficulty: difficulty,
      mode: mode,
      status: status ?? this.status,
      timeElapsed: timeElapsed ?? this.timeElapsed,
      mistakes: mistakes ?? this.mistakes,
      createdAt: createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}