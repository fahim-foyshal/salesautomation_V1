import 'package:sqflite/sqflite.dart';
import '../model/category.dart';
import 'database_helper.dart';

class CategoryDao {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  // Insert a category into the database
  Future<int> insertCategory(Category category) async {
    final db = await _databaseHelper.database;
    return await db.insert(
      'category',
      category.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
  Future<int> insertCategoryWithTransaction(Transaction txn,Category category) async {

    return await txn.insert(
      'category',
      category.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Get all categories from the database
  Future<List<Category>> getAllCategories() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('category');
    return List.generate(maps.length, (i) {
      return Category.fromMap(maps[i]);
    });
  }

  // Get a single category by ID
  Future<Category?> getCategoryById(String categoryId) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'category',
      where: 'id = ?',
      whereArgs: [categoryId],
    );
    if (maps.isNotEmpty) {
      return Category.fromMap(maps.first);
    }
    return null;
  }

  // Update a category
  Future<int> updateCategory(Category category) async {
    final db = await _databaseHelper.database;
    return await db.update(
      'category',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  // Delete a category by ID
  Future<int> deleteCategory(String categoryId) async {
    final db = await _databaseHelper.database;
    return await db.delete(
      'category',
      where: 'id = ?',
      whereArgs: [categoryId],
    );
  }
}
