import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/draw_model.dart';
import '../models/settings_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('lucky_numbers.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE draws (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        winning_numbers TEXT NOT NULL,
        mode TEXT NOT NULL,
        winners_count INTEGER NOT NULL,
        date TEXT NOT NULL,
        min_range INTEGER NOT NULL,
        max_range INTEGER NOT NULL,
        allow_duplicates INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE settings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        min_default INTEGER NOT NULL DEFAULT 1,
        max_default INTEGER NOT NULL DEFAULT 100,
        default_winners_count INTEGER NOT NULL DEFAULT 1,
        theme TEXT NOT NULL DEFAULT 'system',
        sound_enabled INTEGER NOT NULL DEFAULT 1,
        vibration_enabled INTEGER NOT NULL DEFAULT 1,
        animations_enabled INTEGER NOT NULL DEFAULT 1,
        allow_duplicates INTEGER NOT NULL DEFAULT 0,
        draw_mode TEXT NOT NULL DEFAULT 'random'
      )
    ''');

    await db.execute('''
      CREATE TABLE statistics (
        number INTEGER PRIMARY KEY,
        frequency INTEGER NOT NULL DEFAULT 0,
        last_drawn TEXT
      )
    ''');

    await db.insert('settings', {
      'min_default': 1,
      'max_default': 100,
      'default_winners_count': 1,
      'theme': 'system',
      'sound_enabled': 1,
      'vibration_enabled': 1,
      'animations_enabled': 1,
      'allow_duplicates': 0,
      'draw_mode': 'random',
    });
  }

  Future<int> insertDraw(Draw draw) async {
    final db = await database;
    
    for (var number in draw.winningNumbers) {
      await _updateStatistics(db, number);
    }
    
    return await db.insert('draws', draw.toMap());
  }

  Future<void> _updateStatistics(Database db, int number) async {
    final result = await db.query(
      'statistics',
      where: 'number = ?',
      whereArgs: [number],
    );

    if (result.isEmpty) {
      await db.insert('statistics', {
        'number': number,
        'frequency': 1,
        'last_drawn': DateTime.now().toIso8601String(),
      });
    } else {
      final currentFreq = result.first['frequency'] as int;
      await db.update(
        'statistics',
        {
          'frequency': currentFreq + 1,
          'last_drawn': DateTime.now().toIso8601String(),
        },
        where: 'number = ?',
        whereArgs: [number],
      );
    }
  }

  Future<List<Draw>> getAllDraws() async {
    final db = await database;
    final result = await db.query('draws', orderBy: 'date DESC');
    return result.map((map) => Draw.fromMap(map)).toList();
  }

  Future<List<Draw>> getDrawsPaginated(int offset, int limit) async {
    final db = await database;
    final result = await db.query(
      'draws',
      orderBy: 'date DESC',
      limit: limit,
      offset: offset,
    );
    return result.map((map) => Draw.fromMap(map)).toList();
  }

  Future<void> deleteDraw(int id) async {
    final db = await database;
    await db.delete(
      'draws',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteAllDraws() async {
    final db = await database;
    await db.delete('draws');
    await db.delete('statistics');
  }

  Future<int> getDrawsCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM draws');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<AppSettings> getSettings() async {
    final db = await database;
    final result = await db.query('settings', limit: 1);
    
    if (result.isEmpty) {
      return AppSettings();
    }
    
    return AppSettings.fromMap(result.first);
  }

  Future<void> updateSettings(AppSettings settings) async {
    final db = await database;
    await db.update(
      'settings',
      settings.toMap(),
      where: 'id = ?',
      whereArgs: [settings.id ?? 1],
    );
  }

  Future<List<Map<String, dynamic>>> getStatistics() async {
    final db = await database;
    final totalDraws = await getDrawsCount();
    
    if (totalDraws == 0) return [];
    
    final result = await db.query(
      'statistics',
      orderBy: 'frequency DESC',
    );
    
    return result.map((map) {
      final frequency = map['frequency'] as int;
      return {
        ...map,
        'percentage': (frequency / totalDraws) * 100,
      };
    }).toList();
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
