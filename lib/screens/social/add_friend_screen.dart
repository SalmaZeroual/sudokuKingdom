import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/friends_provider.dart';
import '../../config/theme.dart';
import '../../models/friend_model.dart';
import '../../widgets/avatar_widget.dart';

class AddFriendScreen extends StatefulWidget {
  const AddFriendScreen({Key? key}) : super(key: key);

  @override
  State<AddFriendScreen> createState() => _AddFriendScreenState();
}

class _AddFriendScreenState extends State<AddFriendScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _searchByName = false; // false = par ID, true = par nom

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    final friendsProvider = Provider.of<FriendsProvider>(context, listen: false);

    if (value.isEmpty) {
      friendsProvider.clearSearch();
      return;
    }

    if (_searchByName) {
      // Recherche par nom : déclencher dès 2 caractères
      if (value.length >= 2) {
        friendsProvider.searchUsers(value);
      } else {
        friendsProvider.clearSearch();
      }
    } else {
      // Recherche par ID : seulement si exactement 10 chiffres
      if (value.length == 10 && RegExp(r'^\d{10}$').hasMatch(value)) {
        friendsProvider.searchUsers(value);
      } else {
        friendsProvider.clearSearch();
      }
    }
  }

  void _switchMode(bool byName) {
    setState(() {
      _searchByName = byName;
      _searchController.clear();
    });
    Provider.of<FriendsProvider>(context, listen: false).clearSearch();
  }

  @override
  Widget build(BuildContext context) {
    final friendsProvider = Provider.of<FriendsProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajouter un ami'),
      ),
      body: Column(
        children: [
          // ── Toggle ID / Nom ────────────────────────────────────────
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            decoration: BoxDecoration(
              color: AppColors.gray100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _switchMode(false),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: !_searchByName ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: !_searchByName ? [
                          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 4),
                        ] : [],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.badge, size: 16,
                              color: !_searchByName ? AppColors.blue : AppColors.gray500),
                          const SizedBox(width: 6),
                          Text('Par ID', style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: !_searchByName ? AppColors.blue : AppColors.gray500,
                          )),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _switchMode(true),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _searchByName ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: _searchByName ? [
                          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 4),
                        ] : [],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person_search, size: 16,
                              color: _searchByName ? AppColors.blue : AppColors.gray500),
                          const SizedBox(width: 6),
                          Text('Par nom', style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _searchByName ? AppColors.blue : AppColors.gray500,
                          )),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ✅ Search bar — adapts to mode
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  keyboardType: _searchByName ? TextInputType.text : TextInputType.number,
                  inputFormatters: _searchByName ? [] : [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  decoration: InputDecoration(
                    hintText: _searchByName
                        ? 'Rechercher par nom d\'utilisateur...'
                        : 'Entrez l\'ID à 10 chiffres...',
                    prefixIcon: Icon(
                      _searchByName ? Icons.person_search : Icons.badge,
                      color: AppColors.blue,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear, color: AppColors.gray500),
                            onPressed: () {
                              _searchController.clear();
                              friendsProvider.clearSearch();
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.gray100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // ✅ Indicateur du nombre de chiffres
                Text(
                  _searchByName
                      ? (_searchController.text.length >= 2
                          ? 'Recherche en cours...'
                          : 'Tapez au moins 2 caractères')
                      : '${_searchController.text.length}/10 chiffres',
                  style: TextStyle(
                    fontSize: 12,
                    color: _searchByName
                        ? AppColors.gray500
                        : (_searchController.text.length == 10
                            ? AppColors.green
                            : AppColors.gray500),
                  ),
                ),
              ],
            ),
          ),

          // Search results
          Expanded(
            child: _buildSearchResults(friendsProvider),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(FriendsProvider friendsProvider) {
    if (friendsProvider.isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    final text = _searchController.text;

    if (text.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _searchByName ? Icons.person_search : Icons.badge,
              size: 80,
              color: AppColors.blue.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Recherchez un ami',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: AppColors.gray500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchByName
                  ? 'Tapez un nom d\'utilisateur'
                  : 'Entrez l\'ID à 10 chiffres',
              style: TextStyle(fontSize: 14, color: AppColors.gray400),
            ),
            const SizedBox(height: 24),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.blue.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.blue, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _searchByName
                          ? 'Seuls les utilisateurs ayant activé "Par nom" dans leur profil apparaîtront.'
                          : 'Chaque utilisateur possède un ID unique à 10 chiffres visible dans son profil.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.gray700,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Mode ID : attendre 10 chiffres
    if (!_searchByName && text.length < 10) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.dialpad, size: 80, color: AppColors.orange.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text(
              'Continuez à taper...',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: AppColors.gray500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'L\'ID doit contenir exactement 10 chiffres (${text.length}/10)',
              style: TextStyle(fontSize: 14, color: AppColors.gray400),
            ),
          ],
        ),
      );
    }

    // Mode nom : attendre 2 caractères
    if (_searchByName && text.length < 2) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_search, size: 80, color: AppColors.blue.withOpacity(0.2)),
            const SizedBox(height: 16),
            Text(
              'Continuez à taper...',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: AppColors.gray500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tapez au moins 2 caractères',
              style: TextStyle(fontSize: 14, color: AppColors.gray400),
            ),
          ],
        ),
      );
    }

    if (friendsProvider.searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 80, color: AppColors.gray300),
            const SizedBox(height: 16),
            Text(
              'Aucun utilisateur trouvé',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: AppColors.gray500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchByName
                  ? 'Personne avec ce nom n\'a activé la recherche par nom'
                  : 'Vérifiez l\'ID à 10 chiffres',
              style: TextStyle(fontSize: 14, color: AppColors.gray400),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: friendsProvider.searchResults.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final user = friendsProvider.searchResults[index];
        return _UserCard(
          user: user,
          onAddFriend: () => _handleAddFriend(user),
        );
      },
    );
  }

  Future<void> _handleAddFriend(FriendModel user) async {
    final friendsProvider = Provider.of<FriendsProvider>(context, listen: false);
    final success = await friendsProvider.sendFriendRequest(user.id);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Demande envoyée à ${user.username}'
                : 'Erreur lors de l\'envoi',
          ),
          backgroundColor: success ? AppColors.green : AppColors.red,
        ),
      );
    }
  }
}

class _UserCard extends StatelessWidget {
  final FriendModel user;
  final VoidCallback onAddFriend;

  const _UserCard({
    required this.user,
    required this.onAddFriend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gray200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // ✅ Avatar réel
          AvatarWidget(
            avatarId: user.avatar,
            size: 56,
            showBorder: false,
          ),

          const SizedBox(width: 16),

          // User info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        user.username,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Niv. ${user.level}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.blue,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.military_tech,
                      size: 14,
                      color: _getLeagueColor(user.league),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      user.league,
                      style: TextStyle(
                          fontSize: 13, color: AppColors.gray600),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.stars, size: 14, color: AppColors.yellow),
                    const SizedBox(width: 4),
                    Text(
                      '${user.xp} XP',
                      style: TextStyle(
                          fontSize: 13, color: AppColors.gray600),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Action button
          _buildActionButton(),
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    if (user.friendshipStatus == 'accepted') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, size: 16, color: AppColors.green),
            const SizedBox(width: 6),
            Text(
              'Amis',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.green),
            ),
          ],
        ),
      );
    }

    if (user.friendshipStatus == 'pending') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.schedule, size: 16, color: AppColors.orange),
            const SizedBox(width: 6),
            Text(
              'En attente',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.orange),
            ),
          ],
        ),
      );
    }

    return ElevatedButton.icon(
      onPressed: onAddFriend,
      icon: const Icon(Icons.person_add, size: 16),
      label: const Text('Ajouter'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.blue,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 0,
      ),
    );
  }

  Color _getLeagueColor(String league) {
    if (league.contains('Bronze')) return const Color(0xFFCD7F32);
    if (league.contains('Silver')) return const Color(0xFFC0C0C0);
    if (league.contains('Gold')) return const Color(0xFFFFD700);
    if (league.contains('Platinum')) return const Color(0xFFE5E4E2);
    if (league.contains('Diamond')) return const Color(0xFFB9F2FF);
    if (league.contains('Master')) return const Color(0xFF9B59B6);
    return AppColors.gray500;
  }
}