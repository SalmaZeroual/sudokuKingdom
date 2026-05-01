import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/account_storage_service.dart'; // ✅ AJOUTÉ
import '../config/theme.dart';
import '../widgets/avatar_widget.dart';
import 'avatar_selection_screen.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  // ✅ AJOUTÉ : Logout intelligent avec dialog "garder le mot de passe"
  Future<void> _handleLogout(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    if (user == null) return;

    // 1. Confirmer la déconnexion
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.red),
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );

    if (shouldLogout != true || !context.mounted) return;

    // 2. Vérifier si le mot de passe est déjà sauvegardé pour ce compte
    final accounts = await authProvider.getSavedAccounts();
    final savedAccount = accounts.firstWhere(
      (a) => a.email == user.email,
      orElse: () => SavedAccount(
        userId: 0, email: '', username: '', avatar: '', lastLogin: DateTime.now(),
      ),
    );

    bool keepPassword = savedAccount.savedPassword != null;

    // 3. Si le mot de passe n'a jamais été mémorisé → demander
    if (!keepPassword && savedAccount.email.isNotEmpty && context.mounted) {
      final choice = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Mémoriser le mot de passe ?',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Voulez-vous que Sudoku Kingdom mémorise votre mot de passe pour vous reconnecter plus rapidement la prochaine fois ?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Non merci', style: TextStyle(color: Colors.grey[600])),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Mémoriser'),
            ),
          ],
        ),
      );

      if (choice == null || !context.mounted) return;
      keepPassword = choice;

      // Note: si choice == true mais qu'on n'a pas le mot de passe en clair ici,
      // on met un flag pour que le login_screen demande à la prochaine connexion.
      // Le mot de passe sera sauvegardé lors du prochain login().
      if (keepPassword) {
        await authProvider.setSavedPassword(user.email, '__ask_on_next_login__');
      }
    }

    await authProvider.logout(keepPassword: keepPassword);

    if (context.mounted) {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
          // ✅ MODIFIÉ : utilise _handleLogout au lieu de authProvider.logout() direct
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _handleLogout(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            AvatarWidget(
              avatarId: user?.avatar,
              size: 120,
              showEditButton: true,
              showBorder: true,
              borderWidth: 4,
              onEditTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const AvatarSelectionScreen(canSkip: false),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            Text(
              user?.username ?? 'Joueur',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),

            const SizedBox(height: 8),

            if (user?.uniqueId != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.blue.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.badge, size: 20, color: AppColors.blue),
                    const SizedBox(width: 8),
                    Text(
                      'ID: ${user!.uniqueId}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.blue,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(Icons.copy, size: 18, color: AppColors.blue),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: user.uniqueId!));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('✅ ID copié dans le presse-papier !'),
                            backgroundColor: AppColors.green,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      tooltip: 'Copier l\'ID',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.purple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.purple),
              ),
              child: Text(
                'Niveau ${user?.level ?? 1} - ${user?.rank ?? 'Apprenti'}',
                style: const TextStyle(
                  color: AppColors.purple,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 32),

            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.star,
                    value: '${user?.xp ?? 0}',
                    label: 'XP Total',
                    color: AppColors.yellow,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.emoji_events,
                    value: '${user?.wins ?? 0}',
                    label: 'Victoires',
                    color: AppColors.green,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.local_fire_department,
                    value: '${user?.streak ?? 0}',
                    label: 'Série',
                    color: AppColors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.workspace_premium,
                    value: user?.league ?? 'Bronze',
                    label: 'Ligue',
                    color: AppColors.blue,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            Container(
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
                      Icon(Icons.info_outline, color: AppColors.blue, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Pour ajouter des amis',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.gray700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Partagez votre ID unique à 10 chiffres avec vos amis. Ils pourront vous trouver en le tapant dans la recherche.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.gray600,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.gray50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.gray200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.email_outlined, color: AppColors.gray500),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      user?.email ?? '',
                      style: const TextStyle(fontSize: 16),
                    ),
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

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: AppColors.gray600),
          ),
        ],
      ),
    );
  }
}