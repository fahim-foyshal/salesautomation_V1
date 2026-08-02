import 'package:sqflite/sqflite.dart';
import '../databases/trade_offer_comission_dao.dart';
import '../model/trade_offer_comission.dart';

class TradeOfferComissionRepository {
  final TradeOfferComissionDao _tradeOfferComissionDao =
      TradeOfferComissionDao();

  // Add a trade offer comission
  Future<int> addTradeOfferComission(
      TradeOfferComission tradeOfferComission) async {
    return await _tradeOfferComissionDao.insert(tradeOfferComission);
  }

  // Add a trade offer comission using a transaction
  Future<void> addTradeOfferComissionWithTransaction(
      Transaction txn, TradeOfferComission tradeOfferComission) async {
    await _tradeOfferComissionDao.insertWithTransaction(
        txn, tradeOfferComission);
  }

  // Add multiple trade offer comissions
  Future<void> addTradeOfferComissions(
      List<TradeOfferComission> tradeOfferComissions) async {
    await _tradeOfferComissionDao.insertAll(tradeOfferComissions);
  }

  // Get a trade offer comission by ID
  Future<TradeOfferComission?> getTradeOfferComissionById(int id) async {
    return await _tradeOfferComissionDao.getById(id);
  }

  // Get all trade offer comissions
  Future<List<TradeOfferComission>> getAllTradeOfferComissions() async {
    return await _tradeOfferComissionDao.getAll();
  }

  // Get trade offer comissions by year and month
  Future<List<TradeOfferComission>> getTradeOfferComissionsByYearAndMonth(
      String year, String month) async {
    return await _tradeOfferComissionDao.getByYearAndMonth(year, month);
  }

  // Update a trade offer comission
  Future<int> updateTradeOfferComission(
      TradeOfferComission tradeOfferComission) async {
    return await _tradeOfferComissionDao.update(tradeOfferComission);
  }

  // Delete a trade offer comission
  Future<int> deleteTradeOfferComission(int id) async {
    return await _tradeOfferComissionDao.delete(id);
  }

  // Delete all trade offer comissions
  Future<int> deleteAllTradeOfferComissions() async {
    return await _tradeOfferComissionDao.deleteAll();
  }

  // Check if an item is part of any trade offer comission
  Future<bool> isItemInTradeOfferComission(String itemCode) async {
    return await _tradeOfferComissionDao.isItemInTradeOfferComission(itemCode);
  }

  // Get all trade offer comissions that include a specific item
  Future<List<TradeOfferComission>> getTradeOfferComissionsForItem(
      String itemCode) async {
    return await _tradeOfferComissionDao.getOffersForItem(itemCode);
  }
}
