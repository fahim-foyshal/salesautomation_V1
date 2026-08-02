import 'package:sqflite/sqflite.dart';
import '../model/trade_offer.dart';

class TradeOfferRepository {
  final tableName = 'trade_offer';

  Future<void> addTradeOffer(Transaction txn, TradeOffer tradeOffer) async {
    await txn.insert(
      tableName,
      tradeOffer.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<TradeOffer>> getAllTradeOffers(Database db) async {
    final List<Map<String, dynamic>> maps = await db.query(tableName);
    return List.generate(maps.length, (i) {
      return TradeOffer.fromMap(maps[i]);
    });
  }

  Future<List<TradeOffer>> getActiveTradeOffers(Database db) async {
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'status = ?',
      whereArgs: ['Active'],
    );
    return List.generate(maps.length, (i) {
      return TradeOffer.fromMap(maps[i]);
    });
  }

  Future<TradeOffer?> getTradeOfferById(Database db, int id) async {
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

  Future<void> deleteAllTradeOffers(Database db) async {
    await db.delete(tableName);
  }
}
