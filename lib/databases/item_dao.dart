import 'package:sqflite/sqflite.dart';
import '../model/item.dart';
import 'database_helper.dart';

class ItemDao {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  // Insert an item into the database
  Future<int> insertItem(Item item) async {
    final db = await _databaseHelper.database;
    return await db.insert(
      'item',
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }  Future<int> insertItemWithTransaction(Transaction txn,Item item) async {
    final db = await _databaseHelper.database;
    return await txn.insert(
      'item',
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Get all items from the database
  Future<List<Item>> getAllItems() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('item');
    return List.generate(maps.length, (i) {
      return Item.fromMap(maps[i]);
    });
  }

  // Get a single item by ID
  Future<Item?> getItemById(String itemId) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'item',
      where: 'item_id = ?',
      whereArgs: [itemId],
    );
    if (maps.isNotEmpty) {
      return Item.fromMap(maps.first);
    }
    return null;
  }

  // Update an item
  Future<int> updateItem(Item item) async {
    final db = await _databaseHelper.database;
    return await db.update(
      'item',
      item.toMap(),
      where: 'item_id = ?',
      whereArgs: [item.itemId],
    );
  }

  // Delete an item by ID
  Future<int> deleteItem(String itemId) async {
    final db = await _databaseHelper.database;
    return await db.delete(
      'item',
      where: 'item_id = ?',
      whereArgs: [itemId],
    );
  }
}
