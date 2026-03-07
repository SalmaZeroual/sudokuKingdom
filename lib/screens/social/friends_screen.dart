import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/friends_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/duel_provider.dart';
import '../../config/theme.dart';
import '../../models/friend_model.dart'; 
import '../../widgets/avatar_widget.dart';
import 'friend_profile_screen.dart';
import 'add_friend_screen.dart';
import '../chat/chat_screen.dart';
import '../duel/duel_game_screen.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({Key? key}) : super(key: key);

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final friendsProvider =
          Provider.of<FriendsProvider>(context, listen: false);
      friendsProvider.loadFriends();
      friendsProvider.loadPendingRequests();

      final duelProvider = Provider.of<DuelProvider>(context, listen: false);
      duelProvider.loadPendingDuelInvitations();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final friendsProvider = Provider.of<FriendsProvider>(context);
    final duelProvider = Provider.of<DuelProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Amis'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          if (friendsProvider.pendingCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${friendsProvider.pendingCount}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AddFriendScreen()),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: TabBar(
              controller: _tabController,
              indicatorColor: AppColors.blue,
              labelColor: AppColors.blue,
              unselectedLabelColor: AppColors.gray500,
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.people, size: 18),
                      const SizedBox(width: 6),
                      Text('Amis (${friendsProvider.friendCount})'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.mail, size: 18),
                      const SizedBox(width: 6),
                      const Text('Demandes'),
                      if (friendsProvider.pendingCount > 0) ...[
                        const SizedBox(width: 4),
                        _BadgeDot(color: AppColors.red),
                      ],
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.sports_kabaddi, size: 18),
                      const SizedBox(width: 6),
                      const Text('Duels'),
                      if (duelProvider.pendingInvitationsCount > 0) ...[
                        const SizedBox(width: 4),
                        _BadgeDot(color: AppColors.orange),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _FriendsListTab(),
          _PendingRequestsTab(),
          _DuelInvitationsTab(),
        ],
      ),
    );
  }
}

class _BadgeDot extends StatelessWidget {
  final Color color;
  const _BadgeDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

// ══════════════════════════════════════════════
// ✅ ONGLET 1 : Liste des amis AVEC RECHERCHE
// ══════════════════════════════════════════════
class _FriendsListTab extends StatefulWidget {
  @override
  State<_FriendsListTab> createState() => _FriendsListTabState();
}

class _FriendsListTabState extends State<_FriendsListTab> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final friendsProvider = Provider.of<FriendsProvider>(context);

    if (friendsProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (friendsProvider.friends.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 80, color: AppColors.gray300),
            const SizedBox(height: 16),
            Text(
              'Aucun ami pour le moment',
              style: TextStyle(
                fontSize: 18,
                color: AppColors.gray500,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ajoutez des amis pour jouer ensemble !',
              style: TextStyle(fontSize: 14, color: AppColors.gray400),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AddFriendScreen()),
              ),
              icon: const Icon(Icons.person_add),
              label: const Text('Ajouter des amis'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.blue,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      );
    }

    // ✅ Filtrer les amis localement par nom
    final filteredFriends = _searchQuery.isEmpty
        ? friendsProvider.friends
        : friendsProvider.friends
            .where((friend) => friend.username
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()))
            .toList();

    return Column(
      children: [
        // ✅ BARRE DE RECHERCHE
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
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
          child: TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            decoration: InputDecoration(
              hintText: 'Rechercher dans mes amis...',
              prefixIcon: Icon(Icons.search, color: AppColors.gray500),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, color: AppColors.gray500),
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          _searchQuery = '';
                        });
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
                vertical: 10,
              ),
            ),
          ),
        ),

        // ✅ LISTE DES AMIS FILTRÉS
        Expanded(
          child: filteredFriends.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off,
                          size: 80, color: AppColors.gray300),
                      const SizedBox(height: 16),
                      Text(
                        'Aucun ami trouvé',
                        style: TextStyle(
                          fontSize: 18,
                          color: AppColors.gray500,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Essayez avec un autre nom',
                        style: TextStyle(fontSize: 14, color: AppColors.gray400),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => friendsProvider.loadFriends(),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredFriends.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final friend = filteredFriends[index];
                      return _FriendCard(friend: friend);
                    },
                  ),
                ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════
// ONGLET 2 : Demandes d'amitié reçues
// ══════════════════════════════════════════════
class _PendingRequestsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final friendsProvider = Provider.of<FriendsProvider>(context);

    if (friendsProvider.pendingRequests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.mail_outline, size: 80, color: AppColors.gray300),
            const SizedBox(height: 16),
            Text(
              'Aucune demande en attente',
              style: TextStyle(fontSize: 18, color: AppColors.gray500),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: friendsProvider.pendingRequests.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final request = friendsProvider.pendingRequests[index];
        return _PendingRequestCard(request: request);
      },
    );
  }
}

// ══════════════════════════════════════════════
// ONGLET 3 : Invitations de Duel reçues
// ══════════════════════════════════════════════
class _DuelInvitationsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final duelProvider = Provider.of<DuelProvider>(context);

    if (duelProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (duelProvider.pendingInvitations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sports_kabaddi, size: 80, color: AppColors.gray300),
            const SizedBox(height: 16),
            Text(
              'Aucune invitation de duel',
              style: TextStyle(
                fontSize: 18,
                color: AppColors.gray500,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Vos amis peuvent vous inviter à jouer !',
              style: TextStyle(fontSize: 14, color: AppColors.gray400),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: duelProvider.pendingInvitations.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final invitation = duelProvider.pendingInvitations[index];
        return _DuelInvitationCard(invitation: invitation);
      },
    );
  }
}

// [Reste du code identique - je copie tes classes _DuelInvitationCard, _FriendCard, etc...]
// Je ne les réécris pas pour gagner de la place, mais elles sont identiques à ton fichier

// ══════════════════════════════════════════════
// CARTE : Invitation de Duel — ✅ Avatar réel
// ══════════════════════════════════════════════
class _DuelInvitationCard extends StatelessWidget {
  final DuelInvitation invitation;

  const _DuelInvitationCard({required this.invitation});

  Color _difficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'facile':
        return AppColors.green;
      case 'moyen':
        return AppColors.blue;
      case 'difficile':
        return AppColors.orange;
      case 'extreme':
      case 'extrême':
        return AppColors.red;
      default:
        return AppColors.gray500;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _difficultyColor(invitation.difficulty);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.orange.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: AppColors.orange.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AvatarWidget(
                avatarId: invitation.fromAvatarId,
                size: 48,
                showBorder: false,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      invitation.fromUsername,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.sports_kabaddi,
                            size: 13, color: AppColors.orange),
                        const SizedBox(width: 4),
                        const Text(
                          'Vous invite à un duel !',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  invitation.difficulty.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),
          Text(
            _timeAgo(invitation.createdAt),
            style: TextStyle(fontSize: 12, color: AppColors.gray500),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final dp =
                        Provider.of<DuelProvider>(context, listen: false);
                    final success =
                        await dp.acceptDuelInvitation(invitation.id);
                    if (context.mounted) {
                      if (success) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => DuelGameScreen()),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content:
                              const Text('Erreur lors de l\'acceptation'),
                          backgroundColor: AppColors.red,
                        ));
                      }
                    }
                  },
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Accepter'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final dp =
                        Provider.of<DuelProvider>(context, listen: false);
                    await dp.declineDuelInvitation(invitation.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Invitation refusée')),
                      );
                    }
                  },
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text('Refuser'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.red,
                    side: BorderSide(color: AppColors.red),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return 'Il y a ${diff.inDays}j';
    if (diff.inHours > 0) return 'Il y a ${diff.inHours}h';
    if (diff.inMinutes > 0) return 'Il y a ${diff.inMinutes}min';
    return 'À l\'instant';
  }
}

// [Le reste de ton code _FriendCard, _PendingRequestCard, etc. reste identique]
// Je copie-colle tes classes existantes sans modification

class _FriendCard extends StatelessWidget {
  final FriendModel friend;

  const _FriendCard({required this.friend});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => FriendProfileScreen(friendId: friend.id),
        ),
      ),
      child: Container(
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
            Stack(
              clipBehavior: Clip.none,
              children: [
                AvatarWidget(
                  avatarId: friend.avatar,
                  size: 56,
                  showBorder: false,
                ),
                if (friend.isOnline)
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: AppColors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          friend.username,
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
                          'Niv. ${friend.level}',
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
                      Icon(Icons.military_tech,
                          size: 14, color: _leagueColor(friend.league)),
                      const SizedBox(width: 4),
                      Text(friend.league,
                          style: TextStyle(
                              fontSize: 13, color: AppColors.gray600)),
                      const SizedBox(width: 12),
                      Icon(Icons.stars, size: 14, color: AppColors.yellow),
                      const SizedBox(width: 4),
                      Text('${friend.xp} XP',
                          style: TextStyle(
                              fontSize: 13, color: AppColors.gray600)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: friend.isOnline
                              ? AppColors.green
                              : AppColors.gray400,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        friend.isOnline ? 'En ligne' : 'Hors ligne',
                        style: TextStyle(
                          fontSize: 11,
                          color: friend.isOnline
                              ? AppColors.green
                              : AppColors.gray400,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.message, color: AppColors.blue),
                  onPressed: () => _openChat(context, friend),
                  tooltip: 'Envoyer un message',
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: AppColors.gray500),
                  onSelected: (value) {
                    if (value == 'remove') {
                      _showRemoveDialog(context, friend);
                    } else if (value == 'profile') {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) =>
                            FriendProfileScreen(friendId: friend.id),
                      ));
                    } else if (value == 'invite') {
                      if (friend.isOnline) {
                        _showInviteDialog(context, friend);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                '${friend.username} est hors ligne, impossible d\'inviter.'),
                            backgroundColor: AppColors.gray600,
                          ),
                        );
                      }
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'profile',
                      child: Row(children: [
                        Icon(Icons.person, size: 20),
                        SizedBox(width: 12),
                        Text('Voir le profil'),
                      ]),
                    ),
                    PopupMenuItem(
                      value: 'invite',
                      child: Row(
                        children: [
                          Icon(
                            Icons.sports_kabaddi,
                            size: 20,
                            color: friend.isOnline
                                ? AppColors.red
                                : AppColors.gray400,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            friend.isOnline
                                ? 'Inviter à jouer'
                                : 'Inviter à jouer (hors ligne)',
                            style: TextStyle(
                              color: friend.isOnline
                                  ? Colors.black
                                  : AppColors.gray400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'remove',
                      child: Row(children: [
                        Icon(Icons.person_remove,
                            size: 20, color: AppColors.red),
                        SizedBox(width: 12),
                        Text('Retirer',
                            style: TextStyle(color: AppColors.red)),
                      ]),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showInviteDialog(BuildContext context, FriendModel friend) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.sports_kabaddi, color: AppColors.red),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Inviter ${friend.username}',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                        color: AppColors.green, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                  Text('En ligne',
                      style:
                          TextStyle(fontSize: 12, color: AppColors.green)),
                ],
              ),
              const SizedBox(height: 20),
              const Text('Choisissez la difficulté :'),
              const SizedBox(height: 16),
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _DifficultyButton(
                          label: 'Facile',
                          color: AppColors.green,
                          onTap: () {
                            Navigator.of(ctx).pop();
                            _inviteToDuel(context, friend, 'facile');
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _DifficultyButton(
                          label: 'Moyen',
                          color: AppColors.blue,
                          onTap: () {
                            Navigator.of(ctx).pop();
                            _inviteToDuel(context, friend, 'moyen');
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _DifficultyButton(
                          label: 'Difficile',
                          color: AppColors.orange,
                          onTap: () {
                            Navigator.of(ctx).pop();
                            _inviteToDuel(context, friend, 'difficile');
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _DifficultyButton(
                          label: 'Extrême',
                          color: AppColors.red,
                          onTap: () {
                            Navigator.of(ctx).pop();
                            _inviteToDuel(context, friend, 'extreme');
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.center,
                child: TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Annuler'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _inviteToDuel(
      BuildContext context, FriendModel friend, String difficulty) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12)),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Envoi de l\'invitation...'),
            ],
          ),
        ),
      ),
    );

    try {
      final duelProvider =
          Provider.of<DuelProvider>(context, listen: false);
      await duelProvider.challengeFriend(friend.id, difficulty);

      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Invitation envoyée à ${friend.username} ! En attente de sa réponse.',
            ),
            backgroundColor: AppColors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: AppColors.red,
        ));
      }
    }
  }

  void _showRemoveDialog(BuildContext context, FriendModel friend) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Retirer cet ami ?'),
        content: Text(
            'Êtes-vous sûr de vouloir retirer ${friend.username} de vos amis ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final fp =
                  Provider.of<FriendsProvider>(context, listen: false);
              final success = await fp.removeFriend(friend.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(success
                      ? 'Ami retiré avec succès'
                      : 'Erreur lors de la suppression'),
                  backgroundColor:
                      success ? AppColors.green : AppColors.red,
                ));
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.red),
            child: const Text('Retirer'),
          ),
        ],
      ),
    );
  }

  Color _leagueColor(String league) {
    if (league.contains('Bronze')) return const Color(0xFFCD7F32);
    if (league.contains('Silver')) return const Color(0xFFC0C0C0);
    if (league.contains('Gold')) return const Color(0xFFFFD700);
    if (league.contains('Platinum')) return const Color(0xFFE5E4E2);
    if (league.contains('Diamond')) return const Color(0xFFB9F2FF);
    if (league.contains('Master')) return const Color(0xFF9B59B6);
    return AppColors.gray500;
  }

  Future<void> _openChat(BuildContext context, FriendModel friend) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ouverture de la conversation...'),
        duration: Duration(seconds: 1),
      ),
    );

    try {
      final chatProvider =
          Provider.of<ChatProvider>(context, listen: false);
      await chatProvider.loadConversations();
      final conversationId =
          await chatProvider.getOrCreateConversation(friend.id);

      if (conversationId != null && conversationId > 0 && context.mounted) {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => ChatScreen(
            conversationId: conversationId,
            friendId: friend.id,
            friendUsername: friend.username,
          ),
        ));
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              'Impossible d\'ouvrir la conversation avec ${friend.username}'),
          backgroundColor: AppColors.red,
          duration: const Duration(seconds: 3),
        ));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: AppColors.red,
          duration: const Duration(seconds: 3),
        ));
      }
    }
  }
}

class _DifficultyButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _DifficultyButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 72,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.35),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }
}

class _PendingRequestCard extends StatelessWidget {
  final FriendRequest request;

  const _PendingRequestCard({required this.request});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.blue.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: AppColors.blue.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AvatarWidget(
                avatarId: request.avatar,
                size: 48,
                showBorder: false,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.username,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Niv. ${request.level}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.blue,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.military_tech,
                            size: 12, color: AppColors.gray500),
                        const SizedBox(width: 2),
                        Text(request.league,
                            style: TextStyle(
                                fontSize: 12, color: AppColors.gray600)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _timeAgo(request.createdAt),
            style: TextStyle(fontSize: 12, color: AppColors.gray500),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final fp =
                        Provider.of<FriendsProvider>(context, listen: false);
                    final success =
                        await fp.acceptFriendRequest(request.friendshipId);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(success
                            ? 'Demande acceptée !'
                            : 'Erreur lors de l\'acceptation'),
                        backgroundColor:
                            success ? AppColors.green : AppColors.red,
                      ));
                    }
                  },
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Accepter'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final fp =
                        Provider.of<FriendsProvider>(context, listen: false);
                    final success =
                        await fp.rejectFriendRequest(request.friendshipId);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(success
                            ? 'Demande refusée'
                            : 'Erreur lors du refus'),
                        backgroundColor:
                            success ? AppColors.gray600 : AppColors.red,
                      ));
                    }
                  },
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text('Refuser'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.red,
                    side: BorderSide(color: AppColors.red),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0)
      return 'Il y a ${diff.inDays} jour${diff.inDays > 1 ? 's' : ''}';
    if (diff.inHours > 0)
      return 'Il y a ${diff.inHours} heure${diff.inHours > 1 ? 's' : ''}';
    if (diff.inMinutes > 0)
      return 'Il y a ${diff.inMinutes} minute${diff.inMinutes > 1 ? 's' : ''}';
    return 'À l\'instant';
  }
}