class AvatarModel {
  final String id;
  final String name;
  final String emoji;
  final String gradient1;
  final String gradient2;
  final String category;

  const AvatarModel({
    required this.id,
    required this.name,
    required this.emoji,
    required this.gradient1,
    required this.gradient2,
    required this.category,
  });

  factory AvatarModel.fromJson(Map<String, dynamic> json) {
    return AvatarModel(
      id: json['id'],
      name: json['name'],
      emoji: json['emoji'],
      gradient1: json['gradient1'],
      gradient2: json['gradient2'],
      category: json['category'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'emoji': emoji,
      'gradient1': gradient1,
      'gradient2': gradient2,
      'category': category,
    };
  }
}

// ==========================================
// LISTE DES AVATARS DISPONIBLES
// ==========================================
class Avatars {
  static const List<AvatarModel> all = [
    // 👑 ROYAUTÉ (5 avatars)
    AvatarModel(
      id: 'king',
      name: 'Roi',
      emoji: '👑',
      gradient1: '#FFD700',
      gradient2: '#FFA500',
      category: 'Royauté',
    ),
    AvatarModel(
      id: 'queen',
      name: 'Reine',
      emoji: '👸',
      gradient1: '#FF69B4',
      gradient2: '#FF1493',
      category: 'Royauté',
    ),
    AvatarModel(
      id: 'prince',
      name: 'Prince',
      emoji: '🤴',
      gradient1: '#4169E1',
      gradient2: '#0000CD',
      category: 'Royauté',
    ),
    AvatarModel(
      id: 'princess',
      name: 'Princesse',
      emoji: '👸🏻',
      gradient1: '#FFB6C1',
      gradient2: '#FF69B4',
      category: 'Royauté',
    ),
    AvatarModel(
      id: 'crown',
      name: 'Couronne',
      emoji: '👑',
      gradient1: '#DAA520',
      gradient2: '#B8860B',
      category: 'Royauté',
    ),
    
    // ⚔️ GUERRIERS (6 avatars)
    AvatarModel(
      id: 'knight',
      name: 'Chevalier',
      emoji: '🛡️',
      gradient1: '#708090',
      gradient2: '#2F4F4F',
      category: 'Guerriers',
    ),
    AvatarModel(
      id: 'ninja',
      name: 'Ninja',
      emoji: '🥷',
      gradient1: '#000000',
      gradient2: '#1C1C1C',
      category: 'Guerriers',
    ),
    AvatarModel(
      id: 'viking',
      name: 'Viking',
      emoji: '🪓',
      gradient1: '#8B4513',
      gradient2: '#A0522D',
      category: 'Guerriers',
    ),
    AvatarModel(
      id: 'samurai',
      name: 'Samouraï',
      emoji: '⚔️',
      gradient1: '#DC143C',
      gradient2: '#8B0000',
      category: 'Guerriers',
    ),
    AvatarModel(
      id: 'wizard',
      name: 'Magicien',
      emoji: '🧙',
      gradient1: '#4B0082',
      gradient2: '#8B008B',
      category: 'Guerriers',
    ),
    AvatarModel(
      id: 'archer',
      name: 'Archer',
      emoji: '🏹',
      gradient1: '#228B22',
      gradient2: '#006400',
      category: 'Guerriers',
    ),
    
    // 🐉 CRÉATURES (6 avatars)
    AvatarModel(
      id: 'dragon',
      name: 'Dragon',
      emoji: '🐉',
      gradient1: '#FF4500',
      gradient2: '#FF6347',
      category: 'Créatures',
    ),
    AvatarModel(
      id: 'unicorn',
      name: 'Licorne',
      emoji: '🦄',
      gradient1: '#FF69B4',
      gradient2: '#DDA0DD',
      category: 'Créatures',
    ),
    AvatarModel(
      id: 'phoenix',
      name: 'Phénix',
      emoji: '🔥',
      gradient1: '#FF4500',
      gradient2: '#FFD700',
      category: 'Créatures',
    ),
    AvatarModel(
      id: 'wolf',
      name: 'Loup',
      emoji: '🐺',
      gradient1: '#696969',
      gradient2: '#2F4F4F',
      category: 'Créatures',
    ),
    AvatarModel(
      id: 'eagle',
      name: 'Aigle',
      emoji: '🦅',
      gradient1: '#8B4513',
      gradient2: '#A0522D',
      category: 'Créatures',
    ),
    AvatarModel(
      id: 'lion',
      name: 'Lion',
      emoji: '🦁',
      gradient1: '#DAA520',
      gradient2: '#B8860B',
      category: 'Créatures',
    ),
    
    // 🎯 SYMBOLES (5 avatars)
    AvatarModel(
      id: 'star',
      name: 'Étoile',
      emoji: '⭐',
      gradient1: '#FFD700',
      gradient2: '#FFA500',
      category: 'Symboles',
    ),
    AvatarModel(
      id: 'diamond',
      name: 'Diamant',
      emoji: '💎',
      gradient1: '#00CED1',
      gradient2: '#4682B4',
      category: 'Symboles',
    ),
    AvatarModel(
      id: 'trophy',
      name: 'Trophée',
      emoji: '🏆',
      gradient1: '#FFD700',
      gradient2: '#DAA520',
      category: 'Symboles',
    ),
    AvatarModel(
      id: 'lightning',
      name: 'Éclair',
      emoji: '⚡',
      gradient1: '#FFD700',
      gradient2: '#FFFF00',
      category: 'Symboles',
    ),
    AvatarModel(
      id: 'fire',
      name: 'Feu',
      emoji: '🔥',
      gradient1: '#FF4500',
      gradient2: '#FF6347',
      category: 'Symboles',
    ),
    
    // 🎮 GAMING (5 avatars)
    AvatarModel(
      id: 'rocket',
      name: 'Fusée',
      emoji: '🚀',
      gradient1: '#4169E1',
      gradient2: '#0000CD',
      category: 'Gaming',
    ),
    AvatarModel(
      id: 'robot',
      name: 'Robot',
      emoji: '🤖',
      gradient1: '#708090',
      gradient2: '#2F4F4F',
      category: 'Gaming',
    ),
    AvatarModel(
      id: 'alien',
      name: 'Alien',
      emoji: '👽',
      gradient1: '#32CD32',
      gradient2: '#228B22',
      category: 'Gaming',
    ),
    AvatarModel(
      id: 'ghost',
      name: 'Fantôme',
      emoji: '👻',
      gradient1: '#F0F8FF',
      gradient2: '#E6E6FA',
      category: 'Gaming',
    ),
    AvatarModel(
      id: 'skull',
      name: 'Crâne',
      emoji: '💀',
      gradient1: '#2F4F4F',
      gradient2: '#000000',
      category: 'Gaming',
    ),
    
    // 🌟 NATURE (3 avatars)
    AvatarModel(
      id: 'rainbow',
      name: 'Arc-en-ciel',
      emoji: '🌈',
      gradient1: '#FF69B4',
      gradient2: '#4169E1',
      category: 'Nature',
    ),
    AvatarModel(
      id: 'moon',
      name: 'Lune',
      emoji: '🌙',
      gradient1: '#4682B4',
      gradient2: '#191970',
      category: 'Nature',
    ),
    AvatarModel(
      id: 'sun',
      name: 'Soleil',
      emoji: '☀️',
      gradient1: '#FFD700',
      gradient2: '#FFA500',
      category: 'Nature',
    ),
  ];

  // Get avatar by ID
  static AvatarModel? getById(String id) {
    try {
      return all.firstWhere((avatar) => avatar.id == id);
    } catch (e) {
      return null;
    }
  }

  // Get avatars by category
  static List<AvatarModel> getByCategory(String category) {
    return all.where((avatar) => avatar.category == category).toList();
  }

  // Get all categories
  static List<String> get categories {
    return all.map((avatar) => avatar.category).toSet().toList();
  }

  // Default avatar (crown)
  static AvatarModel get defaultAvatar => all[4]; // Crown
}