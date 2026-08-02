import 'package:sqflite/sqflite.dart';

import '../model/combo.dart';
import 'database_helper.dart'; // Use sqflite for local database

class ComboDao {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  // Insert a route into the database
  Future<int> insertCombo(Combo route) async {
    final db = await _databaseHelper.database;
    return db.insert(
      'combos', // Your table name
      route.toMap(),
      conflictAlgorithm: ConflictAlgorithm
          .replace, // Replace existing route if conflict occurs
    );
  }

  Future<int> insertComboWithTransaction(Transaction txn, Combo combo) async {
    return txn.insert(
      'combos', // Your table name
      combo.toMap(),
      conflictAlgorithm: ConflictAlgorithm
          .replace, // Replace existing route if conflict occurs
    );
  }

  // Get all routes from the database
  Future<List<Combo>> getAllCombo() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'combos',
      where: 'status = ?',
      whereArgs: [1],
    );
    return List.generate(maps.length, (i) {
      return Combo.fromMap(maps[i]);
    });
  }

  // Get a single route by its ID
  Future<Combo?> getComboId(int comboId) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'combos',
      where: 'id = ?',
      whereArgs: [comboId],
    );
    if (maps.isNotEmpty) {
      return Combo.fromMap(maps.first);
    }
    return null;
  }

  // Update a route
}
