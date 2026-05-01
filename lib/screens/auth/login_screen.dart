import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/account_storage_service.dart';
import '../../config/theme.dart';
import 'register_screen.dart';
import 'email_verification_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _showFullForm = false; // true = formulaire complet, false = account switcher
  List<SavedAccount> _savedAccounts = [];
  SavedAccount? _selectedAccount; // compte sélectionné pour connexion rapide

  @override
  void initState() {
    super.initState();
    _loadSavedAccounts();
  }

  Future<void> _loadSavedAccounts() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final accounts = await authProvider.getSavedAccounts();
    setState(() {
      _savedAccounts = accounts;
      // Si aucun compte sauvegardé → aller directement au formulaire complet
      _showFullForm = accounts.isEmpty;
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────
  // Connexion depuis le formulaire complet
  // ─────────────────────────────────────────────────
  Future<void> _loginWithForm() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    // Est-ce la première fois avec cet email ?
    final isFirst = await AccountStorageService().isFirstLoginForEmail(email);

    bool savePassword = false;

    if (isFirst) {
      // Demander à l'utilisateur s'il veut garder le mot de passe
      savePassword = await _showSavePasswordDialog() ?? false;
    } else {
      // Compte déjà connu → vérifier s'il avait déjà sauvegardé
      final existing = _savedAccounts.firstWhere(
        (a) => a.email == email,
        orElse: () => SavedAccount(
          userId: 0, email: '', username: '', avatar: '', lastLogin: DateTime.now(),
        ),
      );
      savePassword = existing.savedPassword != null;
    }

    final success = await authProvider.login(email, password, savePassword: savePassword);
    _handleLoginResult(success, authProvider, email);
  }

  // ─────────────────────────────────────────────────
  // Connexion rapide depuis un compte sauvegardé
  // ─────────────────────────────────────────────────
  Future<void> _loginWithSavedAccount(SavedAccount account) async {
    setState(() => _selectedAccount = account);

    // Si mot de passe sauvegardé → connexion directe
    if (account.savedPassword != null) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.login(
        account.email,
        account.savedPassword!,
        savePassword: true,
      );
      _handleLoginResult(success, authProvider, account.email);
    } else {
      // Sinon → afficher uniquement le champ mot de passe
      _emailController.text = account.email;
      setState(() {
        _showFullForm = true;
        _selectedAccount = account;
      });
    }
  }

  void _handleLoginResult(bool success, AuthProvider authProvider, String email) {
    if (success && mounted) {
      Navigator.of(context).pushReplacementNamed('/home');
    } else if (mounted) {
      final errorMsg = authProvider.errorMessage ?? 'Erreur de connexion';
      setState(() => _selectedAccount = null);

      if (errorMsg.contains('Email non vérifié')) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Email non vérifié'),
            content: const Text('Votre email n\'a pas encore été vérifié. Voulez-vous recevoir un nouveau code ?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => EmailVerificationScreen(email: email),
                  ));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.blue,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Vérifier'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: AppColors.red),
        );
      }
    }
  }

  // ─────────────────────────────────────────────────
  // Dialog "Garder le mot de passe ?"
  // ─────────────────────────────────────────────────
  Future<bool?> _showSavePasswordDialog() async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Mémoriser le mot de passe ?',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Voulez-vous que Sudoku Kingdom mémorise votre mot de passe pour vous connecter plus rapidement ?',
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
  }

  // ─────────────────────────────────────────────────
  // Supprimer un compte de la liste (swipe ou long press)
  // ─────────────────────────────────────────────────
  Future<void> _removeAccount(SavedAccount account) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Retirer ce compte ?'),
        content: Text(
          'Le compte "${account.username}" sera retiré de la liste.\nVous pourrez toujours vous connecter manuellement.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Retirer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.removeSavedAccount(account.email);
      await _loadSavedAccounts();
    }
  }

  // ─────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 48),

              // Logo
              Icon(Icons.castle, size: 80, color: Theme.of(context).primaryColor),
              const SizedBox(height: 16),
              Text(
                'Sudoku Kingdom',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Connectez-vous pour jouer',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),

              const SizedBox(height: 40),

              // ── Account Switcher OU Formulaire complet ──
              if (!_showFullForm && _savedAccounts.isNotEmpty)
                _buildAccountSwitcher()
              else
                _buildFullForm(),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────
  // Account Switcher (style Instagram)
  // ─────────────────────────────────────────────────
  Widget _buildAccountSwitcher() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Choisissez un compte',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[600],
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),

        // Liste des comptes
        ..._savedAccounts.map((account) => _buildAccountTile(account)),

        const SizedBox(height: 16),

        // Bouton ajouter un compte
        OutlinedButton.icon(
          onPressed: () {
            setState(() {
              _showFullForm = true;
              _selectedAccount = null;
              _emailController.clear();
              _passwordController.clear();
            });
          },
          icon: const Icon(Icons.add),
          label: const Text('Ajouter un compte'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            side: BorderSide(color: Theme.of(context).primaryColor),
            foregroundColor: Theme.of(context).primaryColor,
          ),
        ),

        const SizedBox(height: 16),

        // Lien S'inscrire
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Pas de compte ? ', style: TextStyle(color: Colors.grey[600])),
            TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const RegisterScreen()),
              ),
              child: const Text('Créer un compte'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAccountTile(SavedAccount account) {
    final isLoading = _selectedAccount?.email == account.email &&
        Provider.of<AuthProvider>(context).isLoading;

    return Dismissible(
      key: Key(account.email),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        await _removeAccount(account);
        return false; // On gère la suppression nous-mêmes
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline, color: Colors.red),
      ),
      child: GestureDetector(
        onLongPress: () => _removeAccount(account),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: _buildAvatar(account),
            title: Text(
              account.username,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
            subtitle: Text(
              account.email,
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
            trailing: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : account.savedPassword != null
                    ? Icon(Icons.arrow_circle_right_outlined,
                        color: Theme.of(context).primaryColor, size: 28)
                    : Icon(Icons.lock_outline, color: Colors.grey[400], size: 22),
            onTap: isLoading ? null : () => _loginWithSavedAccount(account),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(SavedAccount account) {
    // Adapte selon ton système d'avatar
    // Si tu as des avatars emoji/image, remplace ici
    return CircleAvatar(
      radius: 24,
      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.15),
      child: Text(
        account.username.isNotEmpty ? account.username[0].toUpperCase() : '?',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────
  // Formulaire complet (email + password)
  // ─────────────────────────────────────────────────
  Widget _buildFullForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Si on vient d'un compte sélectionné, afficher son nom
          if (_selectedAccount != null) ...[
            Row(
              children: [
                _buildAvatar(_selectedAccount!),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedAccount!.username,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      _selectedAccount!.email,
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Seulement le champ mot de passe
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Mot de passe',
                prefixIcon: const Icon(Icons.lock_outlined),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer votre mot de passe';
                }
                return null;
              },
            ),
          ] else ...[
            // Formulaire complet
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email',
                prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Veuillez entrer votre email';
                if (!value.contains('@')) return 'Email invalide';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Mot de passe',
                prefixIcon: const Icon(Icons.lock_outlined),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Veuillez entrer votre mot de passe';
                return null;
              },
            ),
          ],

          const SizedBox(height: 24),

          // Bouton connexion
          Consumer<AuthProvider>(
            builder: (context, authProvider, _) {
              return ElevatedButton(
                onPressed: authProvider.isLoading ? null : _loginWithForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: authProvider.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Connexion',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              );
            },
          ),

          const SizedBox(height: 16),

          // Mot de passe oublié
          Center(
            child: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
              ),
              child: const Text(
                'Mot de passe oublié ?',
                style: TextStyle(color: AppColors.blue, fontWeight: FontWeight.w500),
              ),
            ),
          ),

          // Retour à la liste si des comptes existent
          if (_savedAccounts.isNotEmpty)
            Center(
              child: TextButton.icon(
                onPressed: () {
                  setState(() {
                    _showFullForm = false;
                    _selectedAccount = null;
                    _emailController.clear();
                    _passwordController.clear();
                  });
                },
                icon: const Icon(Icons.arrow_back, size: 16),
                label: const Text('Retour aux comptes'),
                style: TextButton.styleFrom(foregroundColor: Colors.grey[600]),
              ),
            ),

          const SizedBox(height: 16),

          // S'inscrire
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Pas de compte ? ', style: TextStyle(color: Colors.grey[600])),
              TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const RegisterScreen()),
                ),
                child: const Text('Créer un compte'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}