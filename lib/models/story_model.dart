// ==========================================
// KINGDOM MODEL
// ==========================================

class KingdomModel {
  final int id;
  final String name;
  final String description;
  final String icon;
  final String color;
  final String character;
  final String characterTitle;
  final bool unlocked;
  final int completedChapters;
  final int totalChapters;
  final int totalStars;
  final int maxStars;
  
  KingdomModel({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.character,
    required this.characterTitle,
    required this.unlocked,
    this.completedChapters = 0,
    this.totalChapters = 10,
    this.totalStars = 0,
    this.maxStars = 30,
  });
  
  factory KingdomModel.fromJson(Map<String, dynamic> json) {
    return KingdomModel(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      icon: json['icon'],
      color: json['color'],
      character: json['character'],
      characterTitle: json['characterTitle'],
      unlocked: json['unlocked'] ?? false,
      completedChapters: json['completed_chapters'] ?? 0,
      totalChapters: json['total_chapters'] ?? 10,
      totalStars: json['total_stars'] ?? 0,
      maxStars: json['max_stars'] ?? 30,
    );
  }
  
  double get progress => totalChapters > 0 ? completedChapters / totalChapters : 0.0;
  
  bool get isCompleted => completedChapters >= totalChapters;
}

// ==========================================
// STORY CHAPTER MODEL
// ==========================================

class StoryChapter {
  final int id;
  final int kingdomId;
  final int chapterId;
  final String title;
  final String description;
  final List<List<int>>? grid;
  final List<List<int>>? solution;
  final String difficulty;
  final int chapterOrder;
  final String? storyText;
  final String? objectiveText;
  final bool isCompleted;
  final bool isLocked;
  final int stars;
  final int timeTaken;
  final int mistakes;
  final String? completedAt;
  
  StoryChapter({
    required this.id,
    required this.kingdomId,
    required this.chapterId,
    required this.title,
    required this.description,
    this.grid,
    this.solution,
    required this.difficulty,
    required this.chapterOrder,
    this.storyText,
    this.objectiveText,
    this.isCompleted = false,
    this.isLocked = false,
    this.stars = 0,
    this.timeTaken = 0,
    this.mistakes = 0,
    this.completedAt,
  });
  
  factory StoryChapter.fromJson(Map<String, dynamic> json) {
    return StoryChapter(
      id: json['id'],
      kingdomId: json['kingdom_id'],
      chapterId: json['chapter_id'],
      title: json['title'],
      description: json['description'],
      grid: json['grid'] != null 
          ? (json['grid'] as List).map((row) => List<int>.from(row)).toList()
          : null,
      solution: json['solution'] != null
          ? (json['solution'] as List).map((row) => List<int>.from(row)).toList()
          : null,
      difficulty: json['difficulty'],
      chapterOrder: json['chapter_order'],
      storyText: json['story_text'],
      objectiveText: json['objective_text'],
      isCompleted: json['is_completed'] ?? false,
      isLocked: json['is_locked'] ?? false,
      stars: json['stars'] ?? 0,
      timeTaken: json['time_taken'] ?? 0,
      mistakes: json['mistakes'] ?? 0,
      completedAt: json['completed_at'],
    );
  }
  
  String get difficultyLabel {
    switch (difficulty) {
      case 'facile':
        return 'Facile';
      case 'moyen':
        return 'Moyen';
      case 'difficile':
        return 'Difficile';
      case 'extreme':
        return 'Extrême';
      default:
        return 'Moyen';
    }
  }
  
  String get formattedTime {
    final minutes = timeTaken ~/ 60;
    final seconds = timeTaken % 60;
    return '${minutes}:${seconds.toString().padLeft(2, '0')}';
  }
}

// ==========================================
// ARTIFACT MODEL
// ==========================================

class ArtifactModel {
  final int id;
  final String name;
  final String icon;
  final int kingdomId;
  final String description;
  final bool collected;
  final String? collectedAt;
  
  ArtifactModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.kingdomId,
    required this.description,
    this.collected = false,
    this.collectedAt,
  });
  
  factory ArtifactModel.fromJson(Map<String, dynamic> json) {
    return ArtifactModel(
      id: json['id'],
      name: json['name'],
      icon: json['icon'],
      kingdomId: json['kingdom_id'],
      description: json['description'],
      collected: json['collected'] ?? false,
      collectedAt: json['collected_at'],
    );
  }
  
  static List<ArtifactModel> getAllArtifacts() {
    return [
      // Kingdom 1: Forêt
      ArtifactModel(
        id: 11,
        name: 'Couronne de Feuilles',
        icon: '🌿',
        kingdomId: 1,
        description: 'Symbole du pouvoir de la nature',
      ),
      ArtifactModel(
        id: 12,
        name: 'Sceptre de Vie',
        icon: '🌿',
        kingdomId: 1,
        description: 'Bâton capable de faire fleurir les plantes',
      ),
      // Kingdom 2: Désert
      ArtifactModel(
        id: 21,
        name: 'Urne Ancienne',
        icon: '🏺',
        kingdomId: 2,
        description: 'Vase contenant du sable du temps',
      ),
      ArtifactModel(
        id: 22,
        name: 'Amulette du Mirage',
        icon: '🏺',
        kingdomId: 2,
        description: 'Pendentif qui révèle les illusions',
      ),
      // Kingdom 3: Océan
      ArtifactModel(
        id: 31,
        name: 'Trident de Cristal',
        icon: '🔱',
        kingdomId: 3,
        description: 'Arme légendaire des profondeurs',
      ),
      ArtifactModel(
        id: 32,
        name: 'Perle des Profondeurs',
        icon: '🔱',
        kingdomId: 3,
        description: 'Gemme lumineuse des abysses',
      ),
      // Kingdom 4: Montagnes
      ArtifactModel(
        id: 41,
        name: 'Gemme de Glace',
        icon: '❄️',
        kingdomId: 4,
        description: 'Cristal éternel du sommet',
      ),
      ArtifactModel(
        id: 42,
        name: 'Bâton du Sommet',
        icon: '❄️',
        kingdomId: 4,
        description: 'Bâton des moines de l\'altitude',
      ),
      // Kingdom 5: Cosmos
      ArtifactModel(
        id: 51,
        name: 'Étoile Filante',
        icon: '⭐',
        kingdomId: 5,
        description: 'Fragment d\'une étoile morte',
      ),
      ArtifactModel(
        id: 52,
        name: 'Orbe Cosmique',
        icon: '⭐',
        kingdomId: 5,
        description: 'Sphère contenant l\'univers',
      ),
    ];
  }
}

// ==========================================
// STORY STATS MODEL
// ==========================================

class StoryStatsModel {
  final int totalCompleted;
  final int totalStars;
  final int artifactsCollected;
  final int bestTime;
  final double avgTime;
  
  StoryStatsModel({
    this.totalCompleted = 0,
    this.totalStars = 0,
    this.artifactsCollected = 0,
    this.bestTime = 0,
    this.avgTime = 0.0,
  });
  
  factory StoryStatsModel.fromJson(Map<String, dynamic> json) {
    return StoryStatsModel(
      totalCompleted: json['total_completed'] ?? 0,
      totalStars: json['total_stars'] ?? 0,
      artifactsCollected: json['artifacts_collected'] ?? 0,
      bestTime: json['best_time'] ?? 0,
      avgTime: (json['avg_time'] ?? 0.0).toDouble(),
    );
  }
  
  String get formattedBestTime {
    final minutes = bestTime ~/ 60;
    final seconds = bestTime % 60;
    return '${minutes}:${seconds.toString().padLeft(2, '0')}';
  }
  
  String get formattedAvgTime {
    final minutes = avgTime ~/ 60;
    final seconds = (avgTime % 60).round();
    return '${minutes}:${seconds.toString().padLeft(2, '0')}';
  }
  
  double get completionRate => totalCompleted / 50;
  
  double get starsRate => totalStars / 150; // 50 chapters * 3 stars
  
  double get artifactsRate => artifactsCollected / 10; // 10 total artifacts
}