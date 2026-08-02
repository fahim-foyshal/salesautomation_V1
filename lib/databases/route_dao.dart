import 'package:sqflite/sqflite.dart';


import '../model/route.dart';
import 'database_helper.dart';  // Use sqflite for local database

class RouteDao {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  // Insert a route into the database
  Future<int> insertRoute(SsRoute route) async {
    final db = await _databaseHelper.database;
    return  db.insert(
      'routes', // Your table name
      route.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,  // Replace existing route if conflict occurs
    );
  }
  Future<int> insertRouteWithTransaction(Transaction txn, SsRoute route) async {
    return txn.insert(
      'routes', // Your table name
      route.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace, // Replace existing route if conflict occurs
    );
  }


  // Get all routes from the database
  Future<List<SsRoute>> getAllRoutes() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('routes');
    return List.generate(maps.length, (i) {
      return SsRoute.fromMap(maps[i]);
    });
  }

  // Get a single route by its ID
  Future<SsRoute?> getRouteById(int routeId) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'routes',
      where: 'route_id = ?',
      whereArgs: [routeId],
    );
    if (maps.isNotEmpty) {
      return SsRoute.fromMap(maps.first);
    }
    return null;
  }

  // Delete a route by its ID
  Future<int> deleteRoute(int routeId) async {
    final db = await _databaseHelper.database;
    return await db.delete(
      'routes',
      where: 'route_id = ?',
      whereArgs: [routeId],
    );
  }

  // Update a route
  Future<int> updateRoute(SsRoute route) async {
    final db = await _databaseHelper.database;
    return await db.update(
      'routes',
      route.toMap(),
      where: 'route_id = ?',
      whereArgs: [route.routeId],
    );
  }
}
