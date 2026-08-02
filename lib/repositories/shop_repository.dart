// Import your Shop model file

import 'package:sqflite/sqflite.dart';

import '../databases/shop_dao.dart';
import '../model/Shop.dart';

class ShopRepository {
  final ShopDao _shopDao = ShopDao();

  // Insert a shop into the database
  Future<void> insertShop(Transaction txn, Shop shop) async {
    await _shopDao.insertShopWithTransaction(txn, shop);
  }

  // Get all shops from the database
  Future<List<Shop>> getAllShops() async {
    return await _shopDao.getAllShops();
  }
  // Add this method to your ShopRepository class

  Future<List<Shop>> getShopsByRouteId(String routeId) async {
    return await _shopDao.getShopsByRouteId(routeId);
  }

  // Get a specific shop by dealer code
  Future<Shop?> getShopByDealerCode(String dealerCode) async {
    return await _shopDao.getShopByDealerCode(dealerCode);
  }

  // Delete a shop by dealer code
  Future<void> deleteShop(String dealerCode) async {
    await _shopDao.deleteShop(dealerCode);
  }

  // Update a shop in the database
  Future<void> updateShop(Shop shop) async {
    await _shopDao.updateShop(shop);
  }
}
