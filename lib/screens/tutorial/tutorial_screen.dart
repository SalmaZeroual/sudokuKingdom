import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/theme.dart';
import '../auth/login_screen.dart';

class TutorialScreen extends StatefulWidget {
  const TutorialScreen({Key? key}) : super(key: key);

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  
  final List<TutorialPage> _pages = [
    TutorialPage(
      icon: Icons.castle,
      title: 'Bienvenue dans\nSudoku Kingdom',
      description: 'Découvrez un Sudoku comme jamais auparavant avec des éléments RPG, des duels et des tournois !',
      color: AppColors.blue,
    ),
    TutorialPage(
      icon: Icons.grid_on,
      title: 'Complétez la grille',
      description: 'Remplissez chaque case avec des chiffres de 1 à 9. Chaque ligne, colonne et bloc 3x3 doit contenir tous les chiffres.',
      color: AppColors.green,
    ),
    TutorialPage(
      icon: Icons.edit,
      title: 'Mode Notes',
      description: 'Activez le mode notes pour ajouter des indices dans les cases. Parfait pour les grilles difficiles !',
      color: AppColors.purple,
    ),
    TutorialPage(
      icon: Icons.lightbulb,
      title: 'Utilisez les Boosters',
      description: 'Révélez une case, gelez le temps ou corrigez une erreur avec les boosters magiques !',
      color: AppColors.orange,
    ),
    TutorialPage(
      icon: Icons.emoji_events,
      title: 'Gagnez de l\'XP',
      description: 'Chaque victoire vous rapporte de l\'XP pour monter de niveau et débloquer de nouvelles compétences !',
      color: AppColors.yellow,
    ),
    TutorialPage(
      icon: Icons.sports_kabaddi,
      title: 'Défiez d\'autres joueurs',
      description: 'Affrontez des joueurs en temps réel dans des duels épiques et grimpez dans les classements !',
      color: AppColors.red,
    ),
  ];
  
  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
  
  Future<void> _completeTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tutorial_completed', true);
    
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _completeTutorial,
                child: const Text('Passer'),
              ),
            ),
            
            // Pages
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return _TutorialPageWidget(page: _pages[index]);
                },
              ),
            ),
            
            // Indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index ? AppColors.blue : AppColors.gray300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Navigation buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  if (_currentPage > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          _pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(color: AppColors.blue),
                        ),
                        child: const Text('Précédent'),
                      ),
                    ),
                  
                  if (_currentPage > 0) const SizedBox(width: 16),
                  
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (_currentPage < _pages.length - 1) {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        } else {
                          _completeTutorial();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        _currentPage < _pages.length - 1 ? 'Suivant' : 'Commencer',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class TutorialPage {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  
  const TutorialPage({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });
}

class _TutorialPageWidget extends StatelessWidget {
  final TutorialPage page;
  
  const _TutorialPageWidget({required this.page});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: page.color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              page.icon,
              size: 100,
              color: page.color,
            ),
          ),
          
          const SizedBox(height: 48),
          
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: page.color,
            ),
          ),
          
          const SizedBox(height: 24),
          
          Text(
            page.description,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.gray600,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}