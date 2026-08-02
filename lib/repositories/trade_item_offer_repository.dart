import 'package:salesautomation_V4/model/trade_item_offer.dart';
import 'package:sqflite/sqflite.dart';
import '../model/trade_offer.dart';

class TradeItemOfferRepository {
  final tableName = 'trade_item_offer';

  Future<void> addTradeItemOffer(
      Transaction txn, TradeItemOffer tradeItemOffer) async {
    await txn.insert(
      tableName,
      tradeItemOffer.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<TradeOffer>> getAllTradeItemOffers(Database db) async {
    final List<Map<String, dynamic>> maps = await db.query(tableName);
    return List.generate(maps.length, (i) {
      return TradeOffer.fromMap(maps[i]);
    });
  }

  Future<List<TradeOffer>> getActiveTradeItemOffers(Database db) async {
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'status = ?',
      whereArgs: ['Active'],
    );
    return List.generate(maps.length, (i) {
      return TradeOffer.fromMap(maps[i]);
    });
  }

  Future<TradeOffer?> getTradeItemOfferById(Database db, int id) async {
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return TradeOffer.fromMap(maps.first);
    }
    return null;
  }

  Future<void> deleteAllTradeItemOffers(Database db) async {
    await db.delete(tableName);
  }
}
