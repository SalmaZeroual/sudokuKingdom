// lib/widgets/share_result_sheet.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../services/share_service.dart';
import 'achievement_share_card.dart';

class ShareResultSheet extends StatefulWidget {
  final ShareCardData data;

  const ShareResultSheet({Key? key, required this.data}) : super(key: key);

  /// Appel unique depuis n'importe quel écran de résultat
  static Future<void> show(BuildContext context, ShareCardData data) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ShareResultSheet(data: data),
    );
  }

  @override
  State<ShareResultSheet> createState() => _ShareResultSheetState();
}

class _ShareResultSheetState extends State<ShareResultSheet> {
  final GlobalKey _cardKey = GlobalKey();
  bool _busy = false;
  bool _showFriends = false;

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final conversations =
        Provider.of<ChatProvider>(context).conversations;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        top: 0,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Handle ────────────────────────────────────────────────
          const SizedBox(height: 12),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: AppColors.gray300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // ── Titre ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: [
              Text(widget.data.emoji,
                  style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Text('Partager ta réussite',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold)),
            ]),
          ),
          const SizedBox(height: 16),

          // ── Aperçu carte ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: RepaintBoundary(
              key: _cardKey,
              child: AchievementShareCard(data: widget.data),
            ),
          ),
          const SizedBox(height: 20),

          // ── Boutons ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(children: [
              // Partage externe
              _Btn(
                icon: Icons.share_rounded,
                label: 'Facebook, Insta, WhatsApp…',
                color: AppColors.blue,
                busy: _busy,
                onTap: _shareExternal,
              ),
              const SizedBox(height: 10),

              // Partage interne — toggle liste amis
              _Btn(
                icon: Icons.people_alt_rounded,
                label: 'Envoyer à un ami dans l\'app',
                color: AppColors.purple,
                busy: false,
                onTap: () {
                  // Charger les conversations si pas encore fait
                  if (conversations.isEmpty) {
                    chatProvider.loadConversations();
                  }
                  setState(() => _showFriends = !_showFriends);
                },
              ),

              // ── Liste amis (conversations existantes) ─────────────
              if (_showFriends) ...[
                const SizedBox(height: 10),
                _buildFriendList(chatProvider, conversations),
              ],

              const SizedBox(height: 4),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Pas maintenant',
                    style: TextStyle(
                        color: AppColors.gray500, fontSize: 14)),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  // ── Liste des amis (basée sur les conversations existantes) ──────────────

  Widget _buildFriendList(
      ChatProvider chatProvider,
      List conversations) {
    if (chatProvider.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (conversations.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Text('Aucune conversation',
            style: TextStyle(color: AppColors.gray500),
            textAlign: TextAlign.center),
      );
    }

    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.gray200),
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        itemCount: conversations.length,
        separatorBuilder: (_, __) =>
            const Divider(height: 1, indent: 58),
        itemBuilder: (ctx, i) {
          final conv = conversations[i];
          return ListTile(
            dense: true,
            leading: CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.purple.withOpacity(0.15),
              child: Text(
                conv.friendUsername.isNotEmpty
                    ? conv.friendUsername[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  color: AppColors.purple,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(conv.friendUsername,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 14)),
            subtitle: Text('Niv. ${conv.friendLevel}',
                style: TextStyle(
                    fontSize: 11, color: AppColors.gray500)),
            trailing: GestureDetector(
              onTap: _busy
                  ? null
                  : () => _sendToFriend(
                      chatProvider, conv.friendId, conv.friendUsername),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _busy
                      ? AppColors.purple.withOpacity(0.4)
                      : AppColors.purple,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Text('Envoyer',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12)),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Actions ──────────────────────────────────────────────────────────────

  Future<void> _shareExternal() async {
    setState(() => _busy = true);
    await ShareService.instance.shareExternal(
      cardKey: _cardKey,
      data: widget.data,
      context: context,
    );
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _sendToFriend(
      ChatProvider chatProvider, int friendId, String username) async {
    setState(() => _busy = true);
    final ok = await ShareService.instance.shareToChat(
      cardKey: _cardKey,
      data: widget.data,
      friendId: friendId,
      chatProvider: chatProvider,
      context: context,
    );
    if (!mounted) return;
    setState(() { _busy = false; _showFriends = false; });
    if (ok) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('✅ Carte envoyée à $username !'),
        backgroundColor: AppColors.green,
      ));
    }
  }
}

// ── Bouton stylisé ────────────────────────────────────────────────────────────

class _Btn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool busy;
  final VoidCallback onTap;
  const _Btn({
    required this.icon,
    required this.label,
    required this.color,
    required this.busy,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: busy ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        width: double.infinity,
        padding:
            const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: busy ? color.withOpacity(0.55) : color,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: color.withOpacity(0.25),
                blurRadius: 6,
                offset: const Offset(0, 3)),
          ],
        ),
        child: Row(children: [
          busy
              ? const SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
              : Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 12),
          Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14)),
        ]),
      ),
    );
  }
}