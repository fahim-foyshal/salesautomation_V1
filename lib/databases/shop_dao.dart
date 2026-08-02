// Import your DatabaseHelper file

import 'package:sqflite/sqflite.dart';

import '../model/Shop.dart';
import 'database_helper.dart';

class ShopDao {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  // Insert a shop into the database
  Future<void> insertShop(Shop shop) async {
    final db = await _databaseHelper.database;
    await db.insert(
      'shops', // Table name
      shop.toMap(), // Convert the Shop object to a map
      conflictAlgorithm: ConflictAlgorithm
          .replace, // Replace if a shop with the same dealer_code exists
    );
  }

  Future<void> insertShopWithTransaction(Transaction txn, Shop shop) async {
    await txn.insert(
      'shops', // Table name
      shop.toMap(), // Convert the Shop object to a map
      conflictAlgorithm: ConflictAlgorithm
          .replace, // Replace if a shop with the same dealer_code exists
    );
  }

  // Get all shops from the database
  Future<List<Shop>> getAllShops() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('shops');

    return List.generate(maps.length, (i) {
      return Shop.fromMap(maps[i]); // Convert Map back to Shop object
    });
  }

  Future<List<Shop>> getShopsByRouteId(String routeId) async {
    final db = await await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'shops',
      where: 'route_id = ?',
      whereArgs: [routeId],
    );

    return List.generate(maps.length, (i) {
      return Shop.fromMap(maps[i]);
    });
  }

  // Get a specific shop by dealer code
  Future<Shop?> getShopByDealerCode(String dealerCode) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'shops',
      where: 'dealer_code = ?',
      whereArgs: [dealerCode],
    );

    if (maps.isNotEmpty) {
      return Shop.fromMap(maps.first); // Return the first matching shop
    }
    return null;
  }

  // Delete a shop by dealer code
  Future<void> deleteShop(String dealerCode) async {
    final db = await _databaseHelper.database;
    await db.delete(
      'shops',
      where: 'dealer_code = ?',
      whereArgs: [dealerCode],
    );
  }

  // Update a shop in the database
  Future<void> updateShop(Shop shop) async {
    final db = await _databaseHelper.database;
    await db.update(
      'shops',
      shop.toMap(),
      where: 'dealer_code = ?',
      whereArgs: [shop.dealerCode],
    );
  }
}
