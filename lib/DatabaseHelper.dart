import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class UserDatabaseHelper {
  static final UserDatabaseHelper _instance = UserDatabaseHelper._internal();
  factory UserDatabaseHelper() => _instance;

  static Database? _database;

  UserDatabaseHelper._internal();

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
      onCreate: (db, version) async {
        print("Creating user_data table...");
        await db.execute('''
          CREATE TABLE user_data (
            id INTEGER PRIMARY KEY,
            username TEXT
          );
        ''');
      },
      onOpen: (db) async {
        // Ensure the table exists even if database existed but was missing the table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS user_data (
            id INTEGER PRIMARY KEY,
            username TEXT
          );
        ''');

        List<Map<String, dynamic>> tables = await db
            .rawQuery('SELECT name FROM sqlite_master WHERE type="table"');
        print("Tables in the database: $tables");
      },
    );
  }

  Future<void> insertUsername(String username) async {
    final db = await database;
    await db.insert(
      'user_data',
      {'id': 1, 'username': username},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    print("Username '$username' inserted or updated in the database.");
  }

  Future<String?> getUsername() async {
    final db = await database;
    try {
      List<Map<String, dynamic>> result =
          await db.query('user_data', where: 'id = ?', whereArgs: [1]);
      if (result.isNotEmpty) {
        return result.first['username'] as String?;
      }
    } catch (e) {
      print("Error reading username: $e");
    }
    return null;
  }

  Future<void> deleteDatabaseFile() async {
    String path = join(await getDatabasesPath(), 'user_data.db');
    await deleteDatabase(path);
    print("Database deleted: $path");
  }
}
