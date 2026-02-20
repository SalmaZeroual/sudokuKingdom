import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/auth_provider.dart';
import '../config/theme.dart';
import '../services/api_service.dart';
import 'tutorial/tutorial_settings_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _soundEnabled = true;
  bool _vibrationsEnabled = true;
  bool _notificationsEnabled = true;
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }
  
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _soundEnabled = prefs.getBool('sound_enabled') ?? true;
      _vibrationsEnabled = prefs.getBool('vibrations_enabled') ?? true;
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
    });
  }
  
  Future<void> _saveSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ==========================================
          // SECTION PROFIL
          // ==========================================
          _buildSectionHeader('PROFIL'),
          const SizedBox(height: 8),
          
          ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.blue.withOpacity(0.1),
              child: Icon(Icons.person, color: AppColors.blue),
            ),
            title: Text(user?.username ?? 'Utilisateur'),
            subtitle: Text(user?.email ?? 'email@example.com'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _showEditProfileDialog(context),
          ),
          
          ListTile(
            leading: const Icon(Icons.lock_outline, color: AppColors.orange),
            title: const Text('Changer le mot de passe'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _showChangePasswordDialog(context),
          ),
          
          const Divider(height: 32),
          
          // ==========================================
          // SECTION PRÉFÉRENCES
          // ==========================================
          _buildSectionHeader('PRÉFÉRENCES'),
          const SizedBox(height: 8),
          
          SwitchListTile(
            secondary: const Icon(Icons.volume_up, color: AppColors.blue),
            title: const Text('Sons'),
            subtitle: const Text('Activer les effets sonores'),
            value: _soundEnabled,
            onChanged: (value) {
              setState(() => _soundEnabled = value);
              _saveSetting('sound_enabled', value);
            },
          ),
          
          SwitchListTile(
            secondary: const Icon(Icons.vibration, color: AppColors.purple),
            title: const Text('Vibrations'),
            subtitle: const Text('Retour haptique'),
            value: _vibrationsEnabled,
            onChanged: (value) {
              setState(() => _vibrationsEnabled = value);
              _saveSetting('vibrations_enabled', value);
            },
          ),
          
          SwitchListTile(
            secondary: const Icon(Icons.notifications_outlined, color: AppColors.yellow),
            title: const Text('Notifications'),
            subtitle: const Text('Recevoir les notifications'),
            value: _notificationsEnabled,
            onChanged: (value) {
              setState(() => _notificationsEnabled = value);
              _saveSetting('notifications_enabled', value);
            },
          ),
          
          const Divider(height: 32),
          
          // ==========================================
          // SECTION AIDE
          // ==========================================
          _buildSectionHeader('AIDE'),
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
          
          ListTile(
            leading: const Icon(Icons.info_outline, color: AppColors.green),
            title: const Text('Comment jouer'),
            subtitle: const Text('Règles du Sudoku'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _showHowToPlayDialog(context),
          ),
          
          ListTile(
            leading: const Icon(Icons.bug_report_outlined, color: AppColors.red),
            title: const Text('Signaler un bug'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _showReportBugDialog(context),
          ),
          
          const Divider(height: 32),
          
          // ==========================================
          // SECTION NOS AUTRES JEUX
          // ==========================================
          _buildSectionHeader('NOS AUTRES JEUX'),
          const SizedBox(height: 8),
          
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2C3E50), Color(0xFF34495E)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('♔', style: TextStyle(fontSize: 24)),
            ),
            title: const Text('Chess Kingdom'),
            subtitle: const Text('Devenez maître des échecs'),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.blue,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Jouer',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            onTap: () => _launchURL('https://chesskingdom.app'),
          ),
          
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.purple, Color(0xFF9333EA)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('🎯', style: TextStyle(fontSize: 24)),
            ),
            title: const Text('Puzzle Kingdom'),
            subtitle: const Text('Maître des énigmes - Bientôt disponible'),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.gray300,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Bientôt',
                style: TextStyle(
                  color: AppColors.gray700,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.orange, AppColors.red],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('🃏', style: TextStyle(fontSize: 24)),
            ),
            title: const Text('Cards Kingdom'),
            subtitle: const Text('Jeux de cartes classiques - Bientôt disponible'),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.gray300,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Bientôt',
                style: TextStyle(
                  color: AppColors.gray700,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          
          const Divider(height: 32),
          
          // ==========================================
          // SECTION À PROPOS
          // ==========================================
          _buildSectionHeader('À PROPOS'),
          const SizedBox(height: 8),
          
          ListTile(
            leading: const Icon(Icons.castle, color: AppColors.purple),
            title: const Text('Version'),
            subtitle: const Text('1.0.0 (Build 1)'),
          ),
          
          ListTile(
            leading: const Icon(Icons.code, color: AppColors.blue),
            title: const Text('Développé par'),
            subtitle: const Text('Sudoku Kingdom Team'),
          ),
          
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined, color: AppColors.green),
            title: const Text('Politique de confidentialité'),
            trailing: const Icon(Icons.open_in_new, size: 16),
            onTap: () => _launchURL('https://sudokukingdom.app/privacy'),
          ),
          
          ListTile(
            leading: const Icon(Icons.description_outlined, color: AppColors.orange),
            title: const Text('Conditions d\'utilisation'),
            trailing: const Icon(Icons.open_in_new, size: 16),
            onTap: () => _launchURL('https://sudokukingdom.app/terms'),
          ),
          
          const SizedBox(height: 32),
          
          // Bouton Déconnexion
          Center(
            child: TextButton.icon(
              onPressed: () => _showLogoutDialog(context),
              icon: const Icon(Icons.logout, color: AppColors.red),
              label: const Text(
                'Se déconnecter',
                style: TextStyle(color: AppColors.red),
              ),
            ),
          ),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }
  
  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: AppColors.gray500,
        letterSpacing: 0.5,
      ),
    );
  }
  
  // ==========================================
  // DIALOGUES
  // ==========================================
  
  void _showEditProfileDialog(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUsername = authProvider.user?.username ?? '';
    final controller = TextEditingController(text: currentUsername);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifier le profil'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Nom d\'utilisateur',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Email: ${authProvider.user?.email}',
              style: TextStyle(
                color: AppColors.gray500,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newUsername = controller.text.trim();
              
              // Validation
              if (newUsername.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('❌ Le nom ne peut pas être vide'),
                    backgroundColor: AppColors.red,
                  ),
                );
                return;
              }
              
              if (newUsername.length < 3) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('❌ Le nom doit contenir au moins 3 caractères'),
                    backgroundColor: AppColors.red,
                  ),
                );
                return;
              }
              
              if (newUsername == currentUsername) {
                Navigator.of(context).pop();
                return;
              }
              
              // Show loading
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(
                  child: CircularProgressIndicator(),
                ),
              );
              
              // Call API
              final success = await authProvider.updateUsername(newUsername);
              
              // Hide loading
              if (context.mounted) {
                Navigator.of(context).pop();
              }
              
              // Close dialog
              if (context.mounted) {
                Navigator.of(context).pop();
              }
              
              // Show result
              if (context.mounted) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Profil mis à jour'),
                      backgroundColor: AppColors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('❌ ${authProvider.errorMessage ?? "Erreur lors de la mise à jour"}'),
                      backgroundColor: AppColors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.blue),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }
  
  void _showChangePasswordDialog(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool obscureOld = true;
    bool obscureNew = true;
    bool obscureConfirm = true;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Changer le mot de passe'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: oldPasswordController,
                  obscureText: obscureOld,
                  decoration: InputDecoration(
                    labelText: 'Ancien mot de passe',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(obscureOld ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => obscureOld = !obscureOld),
                    ),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: newPasswordController,
                  obscureText: obscureNew,
                  decoration: InputDecoration(
                    labelText: 'Nouveau mot de passe',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(obscureNew ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => obscureNew = !obscureNew),
                    ),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: obscureConfirm,
                  decoration: InputDecoration(
                    labelText: 'Confirmer le mot de passe',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(obscureConfirm ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => obscureConfirm = !obscureConfirm),
                    ),
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                // Validation
                final oldPassword = oldPasswordController.text;
                final newPassword = newPasswordController.text;
                final confirmPassword = confirmPasswordController.text;
                
                if (oldPassword.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('❌ Veuillez entrer votre ancien mot de passe'),
                      backgroundColor: AppColors.red,
                    ),
                  );
                  return;
                }
                
                if (newPassword.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('❌ Veuillez entrer un nouveau mot de passe'),
                      backgroundColor: AppColors.red,
                    ),
                  );
                  return;
                }
                
                if (newPassword.length < 6) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('❌ Le mot de passe doit contenir au moins 6 caractères'),
                      backgroundColor: AppColors.red,
                    ),
                  );
                  return;
                }
                
                if (newPassword != confirmPassword) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('❌ Les mots de passe ne correspondent pas'),
                      backgroundColor: AppColors.red,
                    ),
                  );
                  return;
                }
                
                if (oldPassword == newPassword) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('❌ Le nouveau mot de passe doit être différent de l\'ancien'),
                      backgroundColor: AppColors.red,
                    ),
                  );
                  return;
                }
                
                // Show loading
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                );
                
                // Call API
                final success = await authProvider.changePassword(oldPassword, newPassword);
                
                // Hide loading
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
                
                // Close dialog
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
                
                // Show result
                if (context.mounted) {
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✅ Mot de passe modifié avec succès'),
                        backgroundColor: AppColors.green,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('❌ ${authProvider.errorMessage ?? "Erreur lors du changement de mot de passe"}'),
                        backgroundColor: AppColors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.blue),
              child: const Text('Modifier'),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showHowToPlayDialog(BuildContext context) {
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
                '🎯 Règles du Sudoku :',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 12),
              Text('• Chaque ligne doit contenir les chiffres de 1 à 9'),
              Text('• Chaque colonne doit contenir les chiffres de 1 à 9'),
              Text('• Chaque bloc 3x3 doit contenir les chiffres de 1 à 9'),
              SizedBox(height: 16),
              Text(
                '💡 Astuces :',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 12),
              Text('• Utilisez le mode notes pour marquer les possibilités'),
              Text('• Les cases initiales ne peuvent pas être modifiées'),
              Text('• Les erreurs sont signalées en rouge'),
              Text('• Utilisez les boosters en cas de difficulté'),
              Text('• Attention : 3 erreurs = Game Over !'),
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
  }
  
  void _showReportBugDialog(BuildContext context) {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Signaler un bug'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Décrivez le problème rencontré :'),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: 'Décrivez le bug en détail...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Envoyer le rapport de bug au backend
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✅ Merci pour votre retour !'),
                  backgroundColor: AppColors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.blue),
            child: const Text('Envoyer'),
          ),
        ],
      ),
    );
  }
  
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              await authProvider.logout();
              
              if (context.mounted) {
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.red),
            child: const Text('Déconnecter'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible d\'ouvrir le lien')),
        );
      }
    }
  }
}