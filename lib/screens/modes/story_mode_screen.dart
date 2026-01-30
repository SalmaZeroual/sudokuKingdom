import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/story_provider.dart';
import '../../config/theme.dart';
import '../../models/story_model.dart';

class StoryModeScreen extends StatefulWidget {
  const StoryModeScreen({Key? key}) : super(key: key);

  @override
  State<StoryModeScreen> createState() => _StoryModeScreenState();
}

class _StoryModeScreenState extends State<StoryModeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<StoryProvider>(context, listen: false).loadChapters();
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final storyProvider = Provider.of<StoryProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mode Énigme'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: storyProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.purple.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.auto_stories,
                          color: AppColors.purple,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Mode Énigme',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Vivez une aventure épique',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.gray500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Story Chapters
                  Text(
                    'Chapitres disponibles',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  if (storyProvider.chapters.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: Text('Aucun chapitre disponible pour le moment'),
                      ),
                    )
                  else
                    ...storyProvider.chapters.map((chapter) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _StoryChapterCard(chapter: chapter),
                      );
                    }).toList(),
                ],
              ),
            ),
    );
  }
}

class _StoryChapterCard extends StatelessWidget {
  final StoryChapter chapter;
  
  const _StoryChapterCard({required this.chapter});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: chapter.isLocked
          ? null
          : () {
              // Navigate to game screen for this chapter
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Lancement du chapitre: ${chapter.title}'),
                ),
              );
            },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: chapter.isLocked
                ? [AppColors.gray300, AppColors.gray200]
                : chapter.isCompleted
                    ? [AppColors.green, const Color(0xFF059669)]
                    : [AppColors.purple, const Color(0xFF7C3AED)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            if (!chapter.isLocked)
              BoxShadow(
                color: (chapter.isCompleted ? AppColors.green : AppColors.purple).withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Chapitre ${chapter.chapterOrder}',
                  style: const TextStyle(
color: Colors.white,
fontWeight: FontWeight.bold,
fontSize: 12,
),
),
),
if (chapter.isLocked)
const Icon(Icons.lock, color: Colors.white, size: 24)
else if (chapter.isCompleted)
const Icon(Icons.check_circle, color: Colors.white, size: 24),
],
),
        const SizedBox(height: 12),
        
        Text(
          chapter.title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        
        const SizedBox(height: 8),
        
        Text(
          chapter.description,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 14,
          ),
        ),
        
        if (!chapter.isLocked && !chapter.isCompleted) ...[
          const SizedBox(height: 16),
          
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: chapter.progress,
              backgroundColor: Colors.white.withOpacity(0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 8,
            ),
          ),
          
          const SizedBox(height: 8),
          
          Text(
            '${(chapter.progress * 100).toInt()}% complété',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 12,
            ),
          ),
        ],
        
        if (chapter.isCompleted) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.star, color: AppColors.yellow, size: 16),
                SizedBox(width: 4),
                Text(
                  'Terminé',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    ),
  ),
);
}
}
