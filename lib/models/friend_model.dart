class FriendModel {
  final int id;
  final String username;
  final int level;
  final String? avatar;
  final int xp;
  final String league;
  final String? friendshipStatus;
  final DateTime? friendsSince;
  
  FriendModel({
    required this.id,
    required this.username,
    required this.level,
    this.avatar,
    required this.xp,
    required this.league,
    this.friendshipStatus,
    this.friendsSince,
  });
  
  factory FriendModel.fromJson(Map<String, dynamic> json) {
    return FriendModel(
      id: json['id'],
      username: json['username'],
      level: json['level'] ?? 1,
      avatar: json['avatar'],
      xp: json['xp'] ?? 0,
      league: json['league'] ?? 'Bronze I',
      friendshipStatus: json['friendship_status'],
      friendsSince: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
    );
  }
  
  bool get isOnline => false; // TODO: Implement online status
  
  String get statusText {
    if (friendshipStatus == null) return 'Pas ami';
    if (friendshipStatus == 'pending') return 'En attente';
    if (friendshipStatus == 'accepted') return 'Amis';
    return 'Inconnu';
  }
}

class FriendRequest {
  final int friendshipId;
  final int userId;
  final String username;
  final int level;
  final String? avatar;
  final int xp;
  final String league;
  final DateTime createdAt;
  
  FriendRequest({
    required this.friendshipId,
    required this.userId,
    required this.username,
    required this.level,
    this.avatar,
    required this.xp,
    required this.league,
    required this.createdAt,
  });
  
  factory FriendRequest.fromJson(Map<String, dynamic> json) {
    return FriendRequest(
      friendshipId: json['friendship_id'],
      userId: json['id'],
      username: json['username'],
      level: json['level'] ?? 1,
      avatar: json['avatar'],
      xp: json['xp'] ?? 0,
      league: json['league'] ?? 'Bronze I',
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}