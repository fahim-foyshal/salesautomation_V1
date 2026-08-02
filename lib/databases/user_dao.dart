import 'package:sqflite/sqflite.dart';
import '../model/user.dart';
import 'database_helper.dart';  // Assuming you have DatabaseHelper defined
  // Your User model

class UserDao {

  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  // Insert a new user into the database
  Future<int> saveUser(User user) async {
    final db = await _databaseHelper.database;
    return db.insert('ss_user', user.toMap());
  }
  // Insert a new user within a transaction
  Future<int> saveUserInTransaction(Transaction txn, User user) async {
    return txn.insert('ss_user', user.toMap());
  }


  // Get all users from the database
  Future<List<User>> getAllUsers() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('ss_user');

    return List.generate(maps.length, (i) {
      return User.fromMap(maps[i]);
    });
  }

  // Get a specific user by user_id
  Future<User?> getUserById(int userId) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'ss_user',
      where: 'user_id = ?',
      whereArgs: [userId],
    );

    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  // Update a user in the database
  Future<int> updateUser(User user) async {
    final db = await _databaseHelper.database;
    return db.update(
      'ss_user',
      user.toMap(),
      where: 'user_id = ?',
      whereArgs: [user.userId],
    );
  }

  // Delete a user from the database
  Future<int> deleteUser(int userId) async {
    final db = await _databaseHelper.database;
    return db.delete(
      'ss_user',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  // Check if a user exists by username
  Future<bool> isUserExist(String username) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'ss_user',
      where: 'username = ?',
      whereArgs: [username],
    );
    return maps.isNotEmpty;
  }
}
