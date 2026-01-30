import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/story_provider.dart';
import '../../config/theme.dart';
import '../../models/story_model.dart';
import 'story_game_screen.dart';

class KingdomDetailScreen extends StatefulWidget {
  final KingdomModel kingdom;
  
  const KingdomDetailScreen({Key? key, required this.kingdom}) : super(key: key);

  @override
  State<KingdomDetailScreen> createState() => _KingdomDetailScreenState();
}

class _KingdomDetailScreenState extends State<KingdomDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<StoryProvider>(context, listen: false)
          .loadChapters(widget.kingdom.id);
    });
  }
  
  Color get _kingdomColor {
    return Color(int.parse(widget.kingdom.color.replaceFirst('#', '0xFF')));
  }
  
  @override
  Widget build(BuildContext context) {
    final storyProvider = Provider.of<StoryProvider>(context);
    
    return Scaffold(
      body: storyProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                // App Bar avec le thème du royaume
                SliverAppBar(
                  expandedHeight: 250,
                  floating: false,
                  pinned: true,
                  flexibleSpace: FlexibleSpaceBar(
                    title: Text(
                      widget.kingdom.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(color: Colors.black45, blurRadius: 10),
                        ],
                      ),
                    ),
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            _kingdomColor,
                            _kingdomColor.withOpacity(0.6),
                          ],
                        ),
                      ),
                      child: Stack(
                        children: [
                          // Big icon
                          Center(
                            child: Opacity(
                              opacity: 0.2,
                              child: Text(
                                widget.kingdom.icon,
                                style: const TextStyle(fontSize: 150),
                              ),
                            ),
                          ),
                          // Character info
                          Positioned(
                            bottom: 80,
                            left: 20,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    widget.kingdom.character,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.kingdom.characterTitle,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Kingdom description
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.all(20),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _kingdomColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _kingdomColor.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.kingdom.description,
                          style: TextStyle(
                            fontSize: 15,
                            color: AppColors.gray700,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            _ProgressChip(
                              icon: Icons.check_circle,
                              label: '${widget.kingdom.completedChapters}/${widget.kingdom.totalChapters} chapitres',
                              color: AppColors.green,
                            ),
                            const SizedBox(width: 12),
                            _ProgressChip(
                              icon: Icons.star,
                              label: '${widget.kingdom.totalStars}/${widget.kingdom.maxStars} étoiles',
                              color: AppColors.yellow,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Artifacts section
                SliverToBoxAdapter(
                  child: _buildArtifactsSection(storyProvider),
                ),
                
                // Chapters title
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                    child: Row(
                      children: [
                        Text(
                          'Chapitres',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${storyProvider.chapters.length} chapitres',
                          style: TextStyle(
                            color: AppColors.gray500,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Chapters list
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final chapter = storyProvider.chapters[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _ChapterCard(
                            chapter: chapter,
                            kingdomColor: _kingdomColor,
                            onTap: () {
                              if (!chapter.isLocked) {
                                _startChapter(chapter);
                              } else {
                                _showLockedChapterDialog(chapter);
                              }
                            },
                          ),
                        );
                      },
                      childCount: storyProvider.chapters.length,
                    ),
                  ),
                ),
                
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
    );
  }
  
  Widget _buildArtifactsSection(StoryProvider storyProvider) {
    final artifacts = storyProvider.getKingdomArtifacts(widget.kingdom.id);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.gray50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.eco, color: _kingdomColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Artefacts du Royaume',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.gray900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: artifacts.map((artifact) {
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: artifact.collected 
                        ? _kingdomColor.withOpacity(0.1)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: artifact.collected
                          ? _kingdomColor
                          : AppColors.gray300,
                    ),
                  ),
                  child: Column(
                    children: [
                      Opacity(
                        opacity: artifact.collected ? 1.0 : 0.3,
                        child: Text(
                          artifact.icon,
                          style: const TextStyle(fontSize: 32),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        artifact.collected ? artifact.name : '???',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: artifact.collected
                              ? AppColors.gray900
                              : AppColors.gray400,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
  
  void _startChapter(StoryChapter chapter) async {
    // Show intro dialog with story text
    final shouldStart = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(chapter.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              chapter.storyText ?? '',
              style: TextStyle(
                fontSize: 15,
                color: AppColors.gray700,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _kingdomColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _kingdomColor.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.flag, color: _kingdomColor, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      chapter.objectiveText ?? '',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.gray900,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _kingdomColor,
            ),
            child: const Text('Commencer'),
          ),
        ],
      ),
    );
    
    if (shouldStart == true && context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => StoryGameScreen(
            chapter: chapter,
            kingdomColor: _kingdomColor,
          ),
        ),
      ).then((_) {
        // Reload chapters after completing a chapter
        Provider.of<StoryProvider>(context, listen: false)
            .loadChapters(widget.kingdom.id);
      });
    }
  }
  
  void _showLockedChapterDialog(StoryChapter chapter) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.lock, color: AppColors.orange),
            const SizedBox(width: 12),
            const Text('Chapitre verrouillé'),
          ],
        ),
        content: const Text(
          'Complétez le chapitre précédent pour débloquer celui-ci.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Compris'),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// CHAPTER CARD WIDGET
// ==========================================

class _ChapterCard extends StatelessWidget {
  final StoryChapter chapter;
  final Color kingdomColor;
  final VoidCallback onTap;
  
  const _ChapterCard({
    required this.chapter,
    required this.kingdomColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: chapter.isLocked 
              ? AppColors.gray100
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: chapter.isCompleted
                ? kingdomColor
                : chapter.isLocked
                    ? AppColors.gray300
                    : AppColors.gray200,
            width: chapter.isCompleted ? 2 : 1,
          ),
          boxShadow: [
            if (!chapter.isLocked)
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Row(
          children: [
            // Chapter number
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: chapter.isLocked
                    ? AppColors.gray300
                    : chapter.isCompleted
                        ? kingdomColor
                        : kingdomColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: chapter.isLocked
                    ? Icon(Icons.lock, color: AppColors.gray600, size: 20)
                    : chapter.isCompleted
                        ? Icon(Icons.check, color: Colors.white, size: 24)
                        : Text(
                            '${chapter.chapterOrder}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: kingdomColor,
                            ),
                          ),
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Chapter info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chapter.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: chapter.isLocked
                          ? AppColors.gray500
                          : AppColors.gray900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _getDifficultyColor(chapter.difficulty).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          chapter.difficultyLabel,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _getDifficultyColor(chapter.difficulty),
                          ),
                        ),
                      ),
                      if (chapter.isCompleted) ...[
                        const SizedBox(width: 8),
                        Row(
                          children: List.generate(3, (i) {
                            return Icon(
                              i < chapter.stars ? Icons.star : Icons.star_border,
                              size: 16,
                              color: i < chapter.stars 
                                  ? AppColors.yellow
                                  : AppColors.gray300,
                            );
                          }),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            
            // Arrow icon
            Icon(
              Icons.chevron_right,
              color: chapter.isLocked ? AppColors.gray400 : kingdomColor,
            ),
          ],
        ),
      ),
    );
  }
  
  Color _getDifficultyColor(String difficulty) {
    switch (difficulty) {
      case 'facile':
        return AppColors.green;
      case 'moyen':
        return AppColors.blue;
      case 'difficile':
        return AppColors.orange;
      case 'extreme':
        return AppColors.red;
      default:
        return AppColors.gray500;
    }
  }
}

// Helper widget
class _ProgressChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  
  const _ProgressChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}