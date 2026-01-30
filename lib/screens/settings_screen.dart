import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/theme.dart';
import 'tutorial/tutorial_settings_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Section Aide
          Text(
            'AIDE',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.gray500,
            ),
          ),
          const SizedBox(height: 8),
          
          ListTile(
            leading: const Icon(Icons.help_outline, color: AppColors.blue),
            title: const Text('Revoir le tutoriel'),
            subtitle: const Text('Découvrez à nouveau comment jouer'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('tutorial_completed', false);
              
              if (context.mounted) {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const TutorialSettingsScreen()),
                );
              }
            },
          ),
          
          const Divider(),
          
          ListTile(
            leading: const Icon(Icons.info_outline, color: AppColors.blue),
            title: const Text('Comment jouer'),
            subtitle: const Text('Règles du Sudoku'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Comment jouer'),
                  content: const SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Règles du Sudoku :',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        Text('• Chaque ligne doit contenir les chiffres de 1 à 9'),
                        Text('• Chaque colonne doit contenir les chiffres de 1 à 9'),
                        Text('• Chaque bloc 3x3 doit contenir les chiffres de 1 à 9'),
                        SizedBox(height: 16),
                        Text(
                          'Astuces :',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        Text('• Utilisez le mode notes pour marquer les possibilités'),
                        Text('• Les cases initiales ne peuvent pas être modifiées'),
                        Text('• Les erreurs sont signalées en rouge'),
                        Text('• Utilisez les boosters en cas de difficulté'),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Compris'),
                    ),
                  ],
                ),
              );
            },
          ),
          
          const SizedBox(height: 24),
          
          // Section À propos
          Text(
            'À PROPOS',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.gray500,
            ),
          ),
          const SizedBox(height: 8),
          
          ListTile(
            leading: const Icon(Icons.castle, color: AppColors.purple),
            title: const Text('Version'),
            subtitle: const Text('1.0.0'),
          ),
          
          ListTile(
            leading: const Icon(Icons.code, color: AppColors.blue),
            title: const Text('Développé par'),
            subtitle: const Text('Sudoku Kingdom Team'),
          ),
        ],
      ),
    );
  }
}