import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku_kingdom/main.dart';

void main() {
  testWidgets('Test d\'affichage de l\'écran de démarrage', (WidgetTester tester) async {
    // 1. Charge l'application
    await tester.pumpWidget(const SudokuKingdomApp());

    // 2. Vérifie que le titre du jeu est présent
    expect(find.text('Sudoku Kingdom'), findsOneWidget);

    // 3. Vérifie que l'icône de château (votre logo) est bien là
    expect(find.byIcon(Icons.castle), findsOneWidget);

    // 4. Vérifie que l'indicateur de chargement est affiché
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    
    // Note: On ne teste pas le bouton "+" ici car il n'existe pas 
    // dans votre interface de Splash Screen ou d'Auth.
  });
}