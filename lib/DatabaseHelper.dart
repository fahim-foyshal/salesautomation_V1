import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;

  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'user_data.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE user (id INTEGER PRIMARY KEY, username TEXT)',
        );
      },
    );
  }

  Future<void> setUsername(String username) async {
    final db = await database;
    // Check if user already exists
    final List<Map<String, dynamic>> existingUser = await db.query(
      'user',
      where: 'id = ?',
      whereArgs: [1],
    );

    if (existingUser.isNotEmpty) {
      // User exists, update
      await db.update(
        'user',
        {'username': username},
        where: 'id = ?',
        whereArgs: [1],
      );
    } else {
      // User does not exist, insert
      await db.insert(
        'user',
        {'id': 1, 'username': username},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<String?> getUsername() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'user',
      where: 'id = ?',
      whereArgs: [1],
    );

    if (maps.isNotEmpty) {
      return maps.first['username'] as String?;
    } else {
      return null;
    }
  }
}
