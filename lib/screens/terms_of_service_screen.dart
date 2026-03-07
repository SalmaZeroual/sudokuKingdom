import 'package:flutter/material.dart';
import '../config/theme.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Conditions d\'utilisation'),
        backgroundColor: AppColors.orange,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Conditions d\'Utilisation',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.orange,
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
              '1. Acceptation des conditions',
              'En utilisant Sudoku Kingdom, vous acceptez ces conditions d\'utilisation. Si vous n\'acceptez pas ces conditions, veuillez ne pas utiliser notre service.\n\n'
              'Nous nous réservons le droit de modifier ces conditions à tout moment. Les modifications prennent effet dès leur publication.',
            ),
            
            _buildSection(
              '2. Description du service',
              'Sudoku Kingdom est une application de jeu de Sudoku proposant :\n\n'
              '• Plusieurs niveaux de difficulté\n'
              '• Mode solo et mode duel\n'
              '• Tournois et classements\n'
              '• Système de progression et de récompenses\n'
              '• Fonctionnalités sociales (amis, chat)\n\n'
              'Nous nous efforçons de maintenir le service disponible 24h/24, mais ne garantissons pas une disponibilité ininterrompue.',
            ),
            
            _buildSection(
              '3. Compte utilisateur',
              'Pour utiliser certaines fonctionnalités, vous devez créer un compte. Vous vous engagez à :\n\n'
              '• Fournir des informations exactes et à jour\n'
              '• Maintenir la sécurité de votre mot de passe\n'
              '• Ne pas partager votre compte\n'
              '• Nous informer immédiatement de toute utilisation non autorisée\n\n'
              'Vous êtes responsable de toutes les activités effectuées depuis votre compte.',
            ),
            
            _buildSection(
              '4. Règles de conduite',
              'En utilisant Sudoku Kingdom, vous vous engagez à :\n\n'
              '✅ Respecter les autres joueurs\n'
              '✅ Ne pas tricher ou utiliser de programmes tiers\n'
              '✅ Ne pas harceler, insulter ou menacer d\'autres utilisateurs\n'
              '✅ Ne pas partager de contenu inapproprié\n'
              '✅ Respecter les lois applicables\n\n'
              '❌ Interdictions :\n'
              '• Utilisation de bots ou scripts automatisés\n'
              '• Exploitation de bugs ou failles\n'
              '• Usurpation d\'identité\n'
              '• Spam ou sollicitation commerciale\n'
              '• Contenu haineux, violent ou illégal',
            ),
            
            _buildSection(
              '5. Propriété intellectuelle',
              'Tous les contenus de Sudoku Kingdom (logos, graphismes, code, textes) sont protégés par le droit d\'auteur et appartiennent à Sudoku Kingdom Team.\n\n'
              'Vous disposez d\'une licence limitée, non exclusive et révocable pour utiliser l\'application à des fins personnelles et non commerciales.\n\n'
              'Il est strictement interdit de :\n'
              '• Copier, modifier ou distribuer notre contenu\n'
              '• Décompiler ou procéder à l\'ingénierie inverse\n'
              '• Utiliser notre marque sans autorisation',
            ),
            
            _buildSection(
              '6. Achats et paiements',
              'Certaines fonctionnalités peuvent être payantes :\n\n'
              '• Les prix sont indiqués en devise locale\n'
              '• Les paiements sont traités par des prestataires tiers sécurisés\n'
              '• Les achats de boosters et contenus virtuels sont définitifs\n'
              '• Aucun remboursement sauf erreur technique avérée\n\n'
              'Vous êtes responsable de tous les frais associés à votre compte.',
            ),
            
            _buildSection(
              '7. Résiliation et suspension',
              'Nous nous réservons le droit de suspendre ou supprimer votre compte sans préavis en cas de :\n\n'
              '• Violation de ces conditions d\'utilisation\n'
              '• Comportement frauduleux ou trompeur\n'
              '• Utilisation abusive du service\n'
              '• Activité illégale\n\n'
              'Vous pouvez supprimer votre compte à tout moment depuis les paramètres.\n\n'
              'En cas de suppression, vous perdez tous vos progrès et achats.',
            ),
            
            _buildSection(
              '8. Limitation de responsabilité',
              'Sudoku Kingdom est fourni "tel quel". Nous ne garantissons pas :\n\n'
              '• L\'absence d\'erreurs ou de bugs\n'
              '• La disponibilité continue du service\n'
              '• La compatibilité avec tous les appareils\n\n'
              'Nous ne sommes pas responsables de :\n\n'
              '• La perte de données ou de progression\n'
              '• Les dommages indirects ou consécutifs\n'
              '• Les pertes de gains ou d\'opportunités\n\n'
              'Notre responsabilité est limitée au montant payé par vous au cours des 12 derniers mois.',
            ),
            
            _buildSection(
              '9. Contenu utilisateur',
              'Vous pouvez créer du contenu (pseudo, messages, avatar) :\n\n'
              '• Vous conservez les droits sur votre contenu\n'
              '• Vous nous accordez une licence mondiale pour l\'afficher\n'
              '• Vous garantissez détenir tous les droits nécessaires\n'
              '• Nous pouvons supprimer tout contenu inapproprié\n\n'
              'Le contenu inapproprié inclut : harcèlement, discours haineux, pornographie, violence, spam.',
            ),
            
            _buildSection(
              '10. Modifications du service',
              'Nous nous réservons le droit de :\n\n'
              '• Modifier ou interrompre le service à tout moment\n'
              '• Ajouter ou supprimer des fonctionnalités\n'
              '• Changer les règles du jeu ou le système de points\n'
              '• Mettre fin au service avec un préavis de 30 jours\n\n'
              'Nous ferons notre possible pour vous informer des changements majeurs.',
            ),
            
            _buildSection(
              '11. Loi applicable et juridiction',
              'Ces conditions sont régies par les lois françaises.\n\n'
              'En cas de litige, vous acceptez la compétence exclusive des tribunaux français.\n\n'
              'Si une disposition est jugée invalide, les autres restent en vigueur.',
            ),
            
            _buildSection(
              '12. Contact',
              'Pour toute question concernant ces conditions :\n\n'
              '📧 Email : support@sudokukingdom.app\n'
              '📧 Questions légales : legal@sudokukingdom.app\n'
              '🌐 Site web : sudokukingdom.app',
            ),
            
            const SizedBox(height: 32),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.orange.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.verified_user, color: AppColors.orange),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Votre confiance est importante',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.gray700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Nous nous engageons à offrir un environnement de jeu sûr, équitable et amusant pour tous.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.gray600,
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
              color: AppColors.orange,
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