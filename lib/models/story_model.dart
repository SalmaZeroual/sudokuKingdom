class StoryChapter {
  final int id;
  final int chapterId;
  final String title;
  final String description;
  final List<List<int>> grid;
  final List<List<int>> solution;
  final String difficulty;
  final int chapterOrder;
  final bool isCompleted;
  final bool isLocked;
  
  StoryChapter({
    required this.id,
    required this.chapterId,
    required this.title,
    required this.description,
    required this.grid,
    required this.solution,
    required this.difficulty,
    required this.chapterOrder,
    this.isCompleted = false,
    this.isLocked = false,
  });
  
  factory StoryChapter.fromJson(Map<String, dynamic> json) {
    return StoryChapter(
      id: json['id'],
      chapterId: json['chapter_id'],
      title: json['title'],
      description: json['description'],
      grid: (json['grid'] as List).map((row) => List<int>.from(row)).toList(),
      solution: (json['solution'] as List).map((row) => List<int>.from(row)).toList(),
      difficulty: json['difficulty'],
      chapterOrder: json['chapter_order'],
      isCompleted: json['is_completed'] ?? false,
      isLocked: json['is_locked'] ?? false,
    );
  }
  
  double get progress {
    if (isCompleted) return 1.0;
    return 0.0;
  }
}