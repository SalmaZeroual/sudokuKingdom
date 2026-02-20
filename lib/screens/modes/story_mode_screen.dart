import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/story_provider.dart';
import '../../config/theme.dart';
import '../../models/story_model.dart';
import '../story/kingdom_detail_screen.dart';

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
      Provider.of<StoryProvider>(context, listen: false).loadKingdoms();
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final storyProvider = Provider.of<StoryProvider>(context);
    
    return Scaffold(
      body: storyProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                // App Bar avec stats globales
                SliverAppBar(
                  expandedHeight: 200,
                  floating: false,
                  pinned: true,
                  flexibleSpace: FlexibleSpaceBar(
                    title: const Text(
                      'Les Royaumes Mystiques',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            color: Colors.black26,
                            blurRadius: 10,
                          ),
                        ],
                      ),
                    ),
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.purple,
                            AppColors.blue,
                          ],
                        ),
                      ),
                      child: Stack(
                        children: [
                          // Decorative stars
                          Positioned(
                            top: 40,
                            right: 30,
                            child: Icon(
                              Icons.star,
                              color: Colors.white.withOpacity(0.3),
                              size: 40,
                            ),
                          ),
                          Positioned(
                            top: 80,
                            left: 40,
                            child: Icon(
                              Icons.auto_stories,
                              color: Colors.white.withOpacity(0.2),
                              size: 60,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  actions: [
  // BOUTON POUR GÉNÉRER LES 50 CHAPITRES
  IconButton(
    icon: const Icon(Icons.add_circle),
    tooltip: 'Générer les chapitres',
    onPressed: () async {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Text('Génération des chapitres...'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Création de 50 chapitres en cours...'),
            ],
          ),
        ),
      );
      
      final storyProvider = Provider.of<StoryProvider>(context, listen: false);
      final result = await storyProvider.initializeChapters();
      
      Navigator.of(context).pop(); // Close loading dialog
      
      if (result && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ 50 chapitres créés avec succès !'),
            backgroundColor: Colors.green,
          ),
        );
        storyProvider.loadKingdoms();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur lors de la génération'),
            backgroundColor: Colors.red,
          ),
        );
      }
    },
  ),
  IconButton(
    icon: const Icon(Icons.bar_chart),
    onPressed: () => _showStatsDialog(context),
  ),
],
                ),
                
                // Progress card
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.all(20),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.blue.withOpacity(0.1),
                          AppColors.purple.withOpacity(0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.blue.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _StatBadge(
                              icon: Icons.check_circle,
                              label: 'Chapitres',
                              value: '${storyProvider.stats.totalCompleted}/50',
                              color: AppColors.green,
                            ),
                            _StatBadge(
                              icon: Icons.star,
                              label: 'Étoiles',
                              value: '${storyProvider.stats.totalStars}/150',
                              color: AppColors.yellow,
                            ),
                            _StatBadge(
                              icon: Icons.eco,
                              label: 'Artefacts',
                              value: '${storyProvider.stats.artifactsCollected}/10',
                              color: AppColors.purple,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: storyProvider.getOverallProgress(),
                            minHeight: 10,
                            backgroundColor: Colors.white,
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.blue),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${(storyProvider.getOverallProgress() * 100).toInt()}% complété',
                          style: TextStyle(
                            color: AppColors.gray600,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Kingdoms grid
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final kingdom = storyProvider.kingdoms[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: _KingdomCard(
                            kingdom: kingdom,
                            artifacts: storyProvider.getKingdomArtifacts(kingdom.id),
                            onTap: () {
                              if (kingdom.unlocked) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => KingdomDetailScreen(kingdom: kingdom),
                                  ),
                                );
                              } else {
                                _showLockedDialog(context, kingdom);
                              }
                            },
                          ),
                        );
                      },
                      childCount: storyProvider.kingdoms.length,
                    ),
                  ),
                ),
                
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
    );
  }
  
  void _showStatsDialog(BuildContext context) {
    final stats = Provider.of<StoryProvider>(context, listen: false).stats;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.bar_chart, color: AppColors.blue),
            SizedBox(width: 12),
            Text('Statistiques'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _StatRow(
              label: 'Chapitres complétés',
              value: '${stats.totalCompleted} / 50',
            ),
            _StatRow(
              label: 'Étoiles collectées',
              value: '${stats.totalStars} / 150',
            ),
            _StatRow(
              label: 'Artefacts trouvés',
              value: '${stats.artifactsCollected} / 10',
            ),
            Divider(height: 24),
            _StatRow(
              label: 'Meilleur temps',
              value: stats.formattedBestTime,
            ),
            _StatRow(
              label: 'Temps moyen',
              value: stats.formattedAvgTime,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Fermer'),
          ),
        ],
      ),
    );
  }
  
  void _showLockedDialog(BuildContext context, KingdomModel kingdom) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.lock, color: AppColors.orange),
            SizedBox(width: 12),
            Text('Royaume verrouillé'),
          ],
        ),
        content: Text(
          'Complétez tous les chapitres du royaume précédent pour débloquer "${kingdom.name}".',
          style: TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Compris'),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// KINGDOM CARD WIDGET
// ==========================================

class _KingdomCard extends StatelessWidget {
  final KingdomModel kingdom;
  final List<ArtifactModel> artifacts;
  final VoidCallback onTap;
  
  const _KingdomCard({
    required this.kingdom,
    required this.artifacts,
    required this.onTap,
  });

  Color _parseColor(String colorStr) {
    return Color(int.parse(colorStr.replaceFirst('#', '0xFF')));
  }

  @override
  Widget build(BuildContext context) {
    final color = _parseColor(kingdom.color);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: kingdom.unlocked
                ? [color, color.withOpacity(0.7)]
                : [AppColors.gray400, AppColors.gray300],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: kingdom.unlocked 
                  ? color.withOpacity(0.3) 
                  : Colors.black12,
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background pattern
            Positioned(
              top: -20,
              right: -20,
              child: Opacity(
                opacity: 0.1,
                child: Text(
                  kingdom.icon,
                  style: TextStyle(fontSize: 120),
                ),
              ),
            ),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Icon
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            kingdom.icon,
                            style: TextStyle(fontSize: 28),
                          ),
                        ),
                      ),
                      
                      const SizedBox(width: 12),
                      
                      // Kingdom info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              kingdom.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              kingdom.character,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Lock icon
                      if (!kingdom.unlocked)
                        Icon(
                          Icons.lock,
                          color: Colors.white,
                          size: 28,
                        ),
                    ],
                  ),
                  
                  const Spacer(),
                  
                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: kingdom.progress,
                      minHeight: 8,
                      backgroundColor: Colors.white.withOpacity(0.3),
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Stats row
                  Row(
                    children: [
                      _MiniStat(
                        icon: Icons.check_circle_outline,
                        value: '${kingdom.completedChapters}/${kingdom.totalChapters}',
                      ),
                      const SizedBox(width: 12),
                      _MiniStat(
                        icon: Icons.star_outline,
                        value: '${kingdom.totalStars}/${kingdom.maxStars}',
                      ),
                      const Spacer(),
                      // Artifacts
                      ...artifacts.map((a) => Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Opacity(
                          opacity: a.collected ? 1.0 : 0.3,
                          child: Text(
                            a.icon,
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      )).toList(),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Helper widgets
class _StatBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  
  const _StatBadge({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.gray900,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: AppColors.gray500,
          ),
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String value;
  
  const _MiniStat({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 16),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  
  const _StatRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: AppColors.gray600)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.gray900,
            ),
          ),
        ],
      ),
    );
  }
}