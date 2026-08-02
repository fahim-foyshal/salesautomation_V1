import 'package:sqflite/sqflite.dart';
import '../model/sub_category.dart';
import 'database_helper.dart';

class SubCategoryDao {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  // Insert a subcategory into the database
  Future<int> insertSubCategory(SubCategory subCategory) async {
    final db = await _databaseHelper.database;
    return await db.insert(
      'sub_category',
      subCategory.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }  Future<int> insertSubCategoryWithTransaction(Transaction txn,SubCategory subCategory) async {

    return await txn.insert(
      'sub_category',
      subCategory.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Get all subcategories from the database
  Future<List<SubCategory>> getAllSubCategories() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('sub_category');
    return List.generate(maps.length, (i) {
      return SubCategory.fromMap(maps[i]);
    });
  }

  // Get a single subcategory by ID
  Future<SubCategory?> getSubCategoryById(String subCategoryId) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'sub_category',
      where: 'id = ?',
      whereArgs: [subCategoryId],
    );
    if (maps.isNotEmpty) {
      return SubCategory.fromMap(maps.first);
    }
    return null;
  }

  // Update a subcategory
  Future<int> updateSubCategory(SubCategory subCategory) async {
    final db = await _databaseHelper.database;
    return await db.update(
      'sub_category',
      subCategory.toMap(),
      where: 'id = ?',
      whereArgs: [subCategory.id],
    );
  }

  // Delete a subcategory by ID
  Future<int> deleteSubCategory(String subCategoryId) async {
    final db = await _databaseHelper.database;
    return await db.delete(
      'sub_category',
      where: 'id = ?',
      whereArgs: [subCategoryId],
    );
  }
}
