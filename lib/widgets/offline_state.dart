import 'package:flutter/material.dart';
import '../config/theme.dart';

/// ✅ NOUVEAU : état "Pas de connexion" réutilisable, dans le même style que
/// celui du Tournoi. À utiliser partout où une coupure réseau ne doit pas
/// être confondue avec une liste réellement vide (aucun ami, aucune
/// invitation, aucun résultat de recherche...).
class OfflineState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const OfflineState({
    super.key,
    this.message = 'Impossible de charger ces données pour le moment.',
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off, size: 64, color: AppColors.gray300),
            const SizedBox(height: 16),
            const Text(
              'Pas de connexion',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.gray400),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}