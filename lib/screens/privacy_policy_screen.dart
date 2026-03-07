import 'package:flutter/material.dart';
import '../config/theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Politique de confidentialité'),
        backgroundColor: AppColors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Politique de Confidentialité',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.blue,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Dernière mise à jour : ${_getFormattedDate()}',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.gray500,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 24),
            
            _buildSection(
              '1. Introduction',
              'Bienvenue sur Sudoku Kingdom. Nous respectons votre vie privée et nous nous engageons à protéger vos données personnelles. Cette politique de confidentialité vous informe sur la manière dont nous collectons, utilisons et protégeons vos informations.',
            ),
            
            _buildSection(
              '2. Données collectées',
              'Nous collectons les informations suivantes :\n\n'
              '• Informations de compte : nom d\'utilisateur, adresse e-mail\n'
              '• Données de jeu : scores, progression, statistiques\n'
              '• Données techniques : type d\'appareil, version du système d\'exploitation\n'
              '• Données d\'utilisation : temps de jeu, fonctionnalités utilisées',
            ),
            
            _buildSection(
              '3. Utilisation des données',
              'Vos données sont utilisées pour :\n\n'
              '• Gérer votre compte et vous authentifier\n'
              '• Sauvegarder votre progression dans le jeu\n'
              '• Améliorer votre expérience de jeu\n'
              '• Vous envoyer des notifications importantes\n'
              '• Analyser et améliorer nos services\n'
              '• Assurer la sécurité de notre plateforme',
            ),
            
            _buildSection(
              '4. Partage des données',
              'Nous ne vendons jamais vos données personnelles. Vos informations peuvent être partagées uniquement dans les cas suivants :\n\n'
              '• Avec votre consentement explicite\n'
              '• Pour respecter une obligation légale\n'
              '• Pour protéger nos droits et notre sécurité\n'
              '• Avec des prestataires de services tiers (hébergement, analytics) sous contrat strict de confidentialité',
            ),
            
            _buildSection(
              '5. Sécurité des données',
              'Nous mettons en œuvre des mesures de sécurité techniques et organisationnelles pour protéger vos données :\n\n'
              '• Chiffrement des mots de passe\n'
              '• Connexions sécurisées (HTTPS)\n'
              '• Accès restreint aux données\n'
              '• Sauvegardes régulières\n'
              '• Surveillance continue des systèmes',
            ),
            
            _buildSection(
              '6. Vos droits',
              'Conformément au RGPD, vous disposez des droits suivants :\n\n'
              '• Droit d\'accès à vos données\n'
              '• Droit de rectification\n'
              '• Droit à l\'effacement (droit à l\'oubli)\n'
              '• Droit à la portabilité\n'
              '• Droit d\'opposition\n'
              '• Droit de limitation du traitement\n\n'
              'Pour exercer ces droits, contactez-nous à : privacy@sudokukingdom.app',
            ),
            
            _buildSection(
              '7. Cookies et technologies similaires',
              'Nous utilisons des cookies et technologies similaires pour :\n\n'
              '• Maintenir votre session active\n'
              '• Mémoriser vos préférences\n'
              '• Analyser l\'utilisation de l\'application\n\n'
              'Vous pouvez gérer vos préférences de cookies dans les paramètres de votre appareil.',
            ),
            
            _buildSection(
              '8. Conservation des données',
              'Nous conservons vos données aussi longtemps que nécessaire pour :\n\n'
              '• Fournir nos services\n'
              '• Respecter nos obligations légales\n'
              '• Résoudre des litiges\n\n'
              'En cas de suppression de compte, vos données sont effacées sous 30 jours, sauf obligation légale de conservation.',
            ),
            
            _buildSection(
              '9. Protection des mineurs',
              'Notre service est destiné aux personnes de 13 ans et plus. Nous ne collectons pas sciemment d\'informations auprès d\'enfants de moins de 13 ans. Si vous pensez que nous avons collecté des données d\'un mineur, contactez-nous immédiatement.',
            ),
            
            _buildSection(
              '10. Modifications de cette politique',
              'Nous pouvons modifier cette politique de confidentialité. En cas de changement important, nous vous informerons par :\n\n'
              '• Notification dans l\'application\n'
              '• E-mail à l\'adresse enregistrée\n\n'
              'Votre utilisation continue après modification vaut acceptation.',
            ),
            
            _buildSection(
              '11. Contact',
              'Pour toute question concernant cette politique de confidentialité :\n\n'
              '📧 Email : privacy@sudokukingdom.app\n'
              '📍 Adresse : Sudoku Kingdom Team\n'
              '🌐 Site web : sudokukingdom.app',
            ),
            
            const SizedBox(height: 32),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.blue.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppColors.blue),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Cette politique est conforme au RGPD (Règlement Général sur la Protection des Données)',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.gray700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.blue,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.gray700,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
  
  String _getFormattedDate() {
    final now = DateTime.now();
    final months = [
      'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
      'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'
    ];
    return '${now.day} ${months[now.month - 1]} ${now.year}';
  }
}