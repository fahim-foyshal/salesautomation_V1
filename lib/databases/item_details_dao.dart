import 'package:sqflite/sqflite.dart';
import '../model/item_details.dart';
import 'database_helper.dart';

class ItemDetailsDao {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  // Insert or update item details in the separate table
  Future<int> insertOrUpdateItemDetails(ItemDetails item) async {
    final db = await _databaseHelper.database;
    return await db.insert(
      'item_details',
      item.toMap(), // Use the toMap method to convert the ItemDetails to a Map
      conflictAlgorithm: ConflictAlgorithm.replace, // Ensures update if exists
    );
  }

  Future<int> UpdateItemDetails(ItemDetails item) async {
    final db = await _databaseHelper.database;

    return await db.update(
      'item_details',
      item.toMap(),
      where: 'do_master_id = ?',
      whereArgs: [
        item.doMasterId
      ], // make sure your ItemDetails has do_master_id property
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Fetch all item details from the separate table
  Future<List<ItemDetails>> getAllItemDetails() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('item_details');

    return maps.map((map) {
      return ItemDetails.fromMap(
          map); // Use fromMap to convert Map to ItemDetails
    }).toList();
  }

  // Fetch item details by do_master_id
  Future<List<ItemDetails>> getItemDetailsByMasterId(String doMasterId) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'item_details',
      where: 'do_master_id = ?', // Query the table where do_master_id matches
      whereArgs: [doMasterId], // Pass the do_master_id to the query
    );

    return maps.map((map) {
      return ItemDetails.fromMap(
          map); // Use fromMap to convert Map to ItemDetails
    }).toList();
  }

  // Delete item details by do_master_id
  Future<int> deleteItemDetailsByMasterId(ItemDetails item) async {
    final db = await _databaseHelper.database;
    return await db.delete(
      'item_details', // Table name
      where: 'do_details_id = ?', // Condition to match the do_master_id
      whereArgs: [item.doDetailsId], // Pass the do_master_id to the query
    );
  }

  Future<int> deleteItemDetailsGiftItemByMasterId(ItemDetails item) async {
    final db = await _databaseHelper.database;
    return await db.delete(
      'item_details', // Table name
      where:
          'do_master_id = ? AND gift_id = 2', // Condition to match the do_master_id
      whereArgs: [item.doMasterId], // Pass the do_master_id to the query
    );
  }

  Future<int> deleteItemDetailsGiftByMasterId(ItemDetails item) async {
    final db = await _databaseHelper.database;
    return await db.delete(
      'item_details', // Table name
      where:
          'do_master_id = ? AND gift_id = 1', // Condition to match the do_master_id
      whereArgs: [item.doMasterId], // Pass the do_master_id to the query
    );
  }
}
