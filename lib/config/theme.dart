import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: Colors.white,
    primaryColor: const Color(0xFF3B82F6),
    
    textTheme: GoogleFonts.poppinsTextTheme().apply(
      bodyColor: const Color(0xFF1F2937),
      displayColor: const Color(0xFF111827),
    ),
    
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF3B82F6),
      secondary: Color(0xFF8B5CF6),
      surface: Colors.white,
      error: Color(0xFFEF4444),
    ),
    
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      elevation: 0,
      iconTheme: IconThemeData(color: Color(0xFF1F2937)),
      titleTextStyle: TextStyle(
        color: Color(0xFF111827),
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
    
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
  );
}

class AppColors {
  static const blue = Color(0xFF3B82F6);
  static const red = Color(0xFFEF4444);
  static const green = Color(0xFF10B981);
  static const yellow = Color(0xFFFBBF24);
  static const purple = Color(0xFF8B5CF6);
  static const orange = Color(0xFFF97316);
  
  static const gray50 = Color(0xFFF9FAFB);
  static const gray100 = Color(0xFFF3F4F6);
  static const gray200 = Color(0xFFE5E7EB);
  static const gray300 = Color(0xFFD1D5DB);
  static const gray400 = Color(0xFF9CA3AF);
  static const gray500 = Color(0xFF6B7280);
  static const gray600 = Color(0xFF4B5563);
  static const gray700 = Color(0xFF374151);
  static const gray900 = Color(0xFF111827);

  // Highlighting cellules Sudoku
  static const highlightSelected = Color(0xFFBBDEFB);     // Cellule sélectionnée - Bleu clair
  static const highlightSameNumber = Color(0xFF90CAF9);   // Même chiffre - Bleu moyen (brille fort)
  static const highlightRowCol = Color(0xFFE3F2FD);       // Ligne/Colonne - Bleu très clair
  static const highlightBox = Color(0xFFF5F5F5);          // Boîte 3x3 - Gris très clair
  
  // Variantes de bleu pour les chiffres
  static const blueDark = Color(0xFF1976D2);              // Bleu foncé pour chiffres identiques
  static const blueLight = Color(0xFF64B5F6);             // Bleu clair pour chiffres joueur
}