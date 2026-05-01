class AppConstants {
  // API
  static const String baseUrl = 'http://localhost:3000/api';
  static const String socketUrl = 'http://localhost:3000';
  //static const String baseUrl = 'http://172.18.236.53:3000/api';
  //static const String socketUrl = 'http://l172.18.236.53:3000';
  
  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String userIdKey = 'user_id';
  static const String usernameKey = 'username';
  
  // Game Settings
  static const int gridSize = 9;
  static const int subGridSize = 3;
  
  // Difficulty Levels
  static const Map<String, int> difficultyXP = {
    'facile': 50,
    'moyen': 100,
    'difficile': 200,
    'extreme': 500,
  };
  
  static const Map<String, int> difficultyEmptyCells = {
    'facile': 30,
    'moyen': 40,
    'difficile': 50,
    'extreme': 60,
  };
  
  // Booster Types
  static const String boosterRevealCell = 'reveal_cell';
  static const String boosterFreezeTime = 'freeze_time';
  static const String boosterSwapCells = 'swap_cells';
  
  // Game Modes
  static const String modeClassic = 'classic';
  static const String modeDuel = 'duel';
  static const String modeTournament = 'tournament';
  static const String modeStory = 'story';
}