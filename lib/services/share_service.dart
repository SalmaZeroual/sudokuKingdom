// lib/services/share_service.dart

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../providers/chat_provider.dart';
import 'api_service.dart';
import '../widgets/achievement_share_card.dart';

class ShareService {
  ShareService._();
  static final ShareService instance = ShareService._();

  // ── 1. Capture RepaintBoundary → bytes PNG ────────────────────────────────

  Future<Uint8List?> captureCard(GlobalKey key) async {
    try {
      final boundary =
          key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;
      final img = await boundary.toImage(pixelRatio: 3.0);
      final data = await img.toByteData(format: ui.ImageByteFormat.png);
      return data?.buffer.asUint8List();
    } catch (e) {
      debugPrint('captureCard error: $e');
      return null;
    }
  }

  Future<String?> _saveTemp(Uint8List bytes) async {
    try {
      final dir = await getTemporaryDirectory();
      final f = File(
          '${dir.path}/achievement_${DateTime.now().millisecondsSinceEpoch}.png');
      await f.writeAsBytes(bytes);
      return f.path;
    } catch (e) {
      debugPrint('_saveTemp error: $e');
      return null;
    }
  }

  // ── 2. Partage EXTERNE (Facebook, Insta, WhatsApp…) ──────────────────────

  Future<void> shareExternal({
    required GlobalKey cardKey,
    required ShareCardData data,
    BuildContext? context,
  }) async {
    final bytes = await captureCard(cardKey);
    if (bytes == null) {
      _snack(context, 'Impossible de capturer la carte');
      return;
    }
    final path = await _saveTemp(bytes);
    if (path == null) {
      _snack(context, 'Erreur de sauvegarde');
      return;
    }
    await Share.shareXFiles(
      [XFile(path, mimeType: 'image/png')],
      text: _buildText(data),
      subject: 'Sudoku Kingdom — Ma réussite 🏆',
    );
  }

  // ── 3. Partage INTERNE dans le chat existant ──────────────────────────────
  // Utilise ton ChatProvider existant :
  //   • getOrCreateConversation(friendId) → conversationId
  //   • sendMessage(conversationId, content)

  Future<bool> shareToChat({
    required GlobalKey cardKey,
    required ShareCardData data,
    required int friendId,
    required ChatProvider chatProvider,
    BuildContext? context,
  }) async {
    try {
      // 1. Obtenir ou créer la conversation
      final conversationId =
          await chatProvider.getOrCreateConversation(friendId);
      if (conversationId == null) throw Exception('Conversation introuvable');

      // 2. Construire le texte de la carte
      final text = _buildText(data);

      // 3. Envoyer via ton sendMessage existant
      final ok = await chatProvider.sendMessage(conversationId, text);
      return ok;
    } catch (e) {
      debugPrint('shareToChat error: $e');
      _snack(context, 'Erreur lors de l\'envoi');
      return false;
    }
  }

  // ── Texte pré-rempli ──────────────────────────────────────────────────────

  String _buildText(ShareCardData data) {
    final buf = StringBuffer();
    buf.writeln('${data.emoji} Sudoku Kingdom — ${data.typeLabel}');
    buf.writeln('');
    buf.writeln('⏱  ${data.time}');
    buf.writeln('⭐  ${data.score} pts');
    buf.writeln('❌  ${data.mistakes} erreurs');
    if (data.rank != null) {
      buf.writeln('🏅  #${data.rank} / ${data.totalPlayers ?? '?'} joueurs');
    }
    buf.writeln('');
    buf.writeln('${data.difficultyEmoji} ${data.difficulty}  •  Niv. ${data.level}');
    buf.writeln('');
    buf.writeln('🎮 Joue aussi : ${ShareCardData.appLink}');
    return buf.toString().trim();
  }

  void _snack(BuildContext? ctx, String msg) {
    if (ctx == null || !ctx.mounted) return;
    ScaffoldMessenger.of(ctx)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }
}