import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/avatar_model.dart';
import '../widgets/avatar_widget.dart';
import '../config/theme.dart';
import 'home_screen.dart';

class AvatarSelectionScreen extends StatefulWidget {
  final bool canSkip;

  const AvatarSelectionScreen({
    Key? key,
    this.canSkip = true,
  }) : super(key: key);

  @override
  State<AvatarSelectionScreen> createState() => _AvatarSelectionScreenState();
}

class _AvatarSelectionScreenState extends State<AvatarSelectionScreen> 
    with SingleTickerProviderStateMixin {
  String? _selectedAvatarId;
  late TabController _tabController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: Avatars.categories.length,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _saveAvatar() async {
    if (_selectedAvatarId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez choisir un avatar'),
          backgroundColor: AppColors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.updateAvatar(_selectedAvatarId!);

    setState(() => _isLoading = false);

    if (mounted) {
      if (success) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage ?? 'Erreur lors de la sauvegarde'),
            backgroundColor: AppColors.red,
          ),
        );
      }
    }
  }

  Future<void> _skip() async {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choisis ton avatar'),
        automaticallyImplyLeading: false,
        actions: [
          if (widget.canSkip)
            TextButton(
              onPressed: _isLoading ? null : _skip,
              child: const Text(
                'Passer',
                style: TextStyle(
                  color: AppColors.gray500,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Header with selected avatar preview
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.blue.withOpacity(0.1),
                  AppColors.purple.withOpacity(0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                const Text(
                  'Sélectionne ton personnage',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Tu pourras le changer à tout moment',
                  style: TextStyle(
                    color: AppColors.gray500,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 20),
                
                // Selected avatar preview
                if (_selectedAvatarId != null)
                  AvatarWidget(
                    avatarId: _selectedAvatarId,
                    size: 100,
                    showBorder: true,
                    borderWidth: 4,
                  )
                else
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.gray200,
                      border: Border.all(
                        color: AppColors.gray300,
                        width: 3,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: const Icon(
                      Icons.help_outline,
                      size: 50,
                      color: AppColors.gray400,
                    ),
                  ),
              ],
            ),
          ),

          // Category tabs
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: AppColors.blue,
              unselectedLabelColor: AppColors.gray500,
              indicatorColor: AppColors.blue,
              tabs: Avatars.categories.map((category) {
                return Tab(text: category);
              }).toList(),
            ),
          ),

          // Avatar grid
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: Avatars.categories.map((category) {
                final avatars = Avatars.getByCategory(category);
                
                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: avatars.length,
                  itemBuilder: (context, index) {
                    final avatar = avatars[index];
                    final isSelected = _selectedAvatarId == avatar.id;

                    return AvatarSelectionItem(
                      avatar: avatar,
                      isSelected: isSelected,
                      onTap: () {
                        setState(() {
                          _selectedAvatarId = avatar.id;
                        });
                      },
                    );
                  },
                );
              }).toList(),
            ),
          ),

          // Bottom button
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading || _selectedAvatarId == null
                      ? null
                      : _saveAvatar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Confirmer',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}