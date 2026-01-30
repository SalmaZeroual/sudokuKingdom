class BoosterModel {
  final int id;
  final int userId;
  final String boosterType;
  final int quantity;
  
  BoosterModel({
    required this.id,
    required this.userId,
    required this.boosterType,
    required this.quantity,
  });
  
  factory BoosterModel.fromJson(Map<String, dynamic> json) {
    return BoosterModel(
      id: json['id'],
      userId: json['user_id'],
      boosterType: json['booster_type'],
      quantity: json['quantity'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'booster_type': boosterType,
      'quantity': quantity,
    };
  }
  
  String get icon {
    switch (boosterType) {
      case 'reveal_cell':
        return '🔮';
      case 'freeze_time':
        return '⏱️';
      case 'swap_cells':
        return '🔄';
      default:
        return '⭐';
    }
  }
  
  String get displayName {
    switch (boosterType) {
      case 'reveal_cell':
        return 'Case Magique';
      case 'freeze_time':
        return 'Gel Temps';
      case 'swap_cells':
        return 'Swap';
      default:
        return 'Booster';
    }
  }
}