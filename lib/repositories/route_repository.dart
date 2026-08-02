import 'package:sqflite/sqflite.dart';

import '../databases/route_dao.dart';
import '../model/route.dart';

class RouteRepository {
  final RouteDao routeDao;

  RouteRepository(this.routeDao);

  // Add a route
  Future<int> addRoute(Transaction txn, SsRoute route) async {
    return await routeDao.insertRouteWithTransaction(txn,route);
  }

  // Get all routes
  Future<List<SsRoute>> getAllRoutes() async {
    return await routeDao.getAllRoutes();
  }

  // Get route by ID
  Future<SsRoute?> getRouteById(int routeId) async {
    return await routeDao.getRouteById(routeId);
  }

  // Delete a route
  Future<int> deleteRoute(int routeId) async {
    return await routeDao.deleteRoute(routeId);
  }

  // Update a route
  Future<int> updateRoute(SsRoute route) async {
    return await routeDao.updateRoute(route);
  }
}
