import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/game_model.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();
  
  Database? _database;
  
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }
  
  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'sudoku_kingdom.db');
    
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }
  
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE games (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        grid TEXT,
        solution TEXT,
        difficulty TEXT,
        mode TEXT,
        status TEXT,
        time_elapsed INTEGER,
        mistakes INTEGER,
        created_at TEXT,
        completed_at TEXT
      )
    ''');
    
    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');
  }
  
  Future<int> saveGame(GameModel game) async {
    final db = await database;
    return await db.insert('games', game.toJson());
  }
  
  Future<List<GameModel>> getGames() async {
    final db = await database;
    final maps = await db.query('games', orderBy: 'created_at DESC');
    
    return List.generate(maps.length, (i) {
      return GameModel.fromJson(maps[i]);
    });
  }
  
  Future<void> deleteGame(int id) async {
    final db = await database;
    await db.delete('games', where: 'id = ?', whereArgs: [id]);
  }
  
  Future<void> saveSetting(String key, String value) async {
    final db = await database;
    await db.insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
  
  Future<String?> getSetting(String key) async {
    final db = await database;
    final maps = await db.query('settings', where: 'key = ?', whereArgs: [key]);
    
    if (maps.isEmpty) return null;
    return maps.first['value'] as String?;
  }
}