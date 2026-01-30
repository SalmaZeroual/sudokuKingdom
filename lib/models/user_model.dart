class UserModel {
  final int id;
  final String username;
  final String email;
  final int xp;
  final int level;
  final String? avatar;
  final int wins;
  final int streak;
  final String league;
  
  UserModel({
    required this.id,
    required this.username,
    required this.email,
    required this.xp,
    required this.level,
    this.avatar,
    required this.wins,
    required this.streak,
    required this.league,
  });
  
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      xp: json['xp'] ?? 0,
      level: json['level'] ?? 1,
      avatar: json['avatar'],
      wins: json['wins'] ?? 0,
      streak: json['streak'] ?? 0,
      league: json['league'] ?? 'Bronze I',
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'xp': xp,
      'level': level,
      'avatar': avatar,
      'wins': wins,
      'streak': streak,
      'league': league,
    };
  }
  
  String get rank {
    if (level < 5) return 'Apprenti';
    if (level < 10) return 'Écuyer';
    if (level < 20) return 'Chevalier';
    if (level < 35) return 'Baron';
    if (level < 50) return 'Duc';
    return 'Roi';
  }
}