import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'providers/auth_provider.dart';
import 'providers/game_provider.dart';
import 'providers/duel_provider.dart';
import 'providers/tournament_provider.dart';
import 'providers/story_provider.dart'; 
import 'providers/friends_provider.dart';
import 'providers/chat_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home_screen.dart';
import 'config/theme.dart';

void main() async {
  // ✅ Initialiser Flutter bindings
  WidgetsFlutterBinding.ensureInitialized();
  
  // ✅ Initialiser les locales pour intl
  await initializeDateFormatting('fr_FR', null);
  
  // ✅ Configurer timeago en français
  timeago.setLocaleMessages('fr', timeago.FrMessages());
  
  runApp(const SudokuKingdomApp());
}

class SudokuKingdomApp extends StatelessWidget {
  const SudokuKingdomApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => GameProvider()),
        ChangeNotifierProvider(create: (_) => DuelProvider()),
        ChangeNotifierProvider(create: (_) => TournamentProvider()),
        ChangeNotifierProvider(create: (_) => StoryProvider()), 
        ChangeNotifierProvider(create: (_) => FriendsProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
      ],
      child: MaterialApp(
        title: 'Sudoku Kingdom',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        
        // ✅ Ajouter les localisations
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('fr', 'FR'),
        ],
        locale: const Locale('fr', 'FR'),
        
        home: const SplashScreen(),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/home': (context) => const HomeScreen(),
        },
      ),
    );
  }
}