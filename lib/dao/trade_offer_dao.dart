import 'package:sqflite/sqflite.dart';
import '../model/trade_offer.dart';
import '../databases/database_helper.dart';

class TradeOfferDao {
  final tableName = 'trade_offer';

  Future<Database> get database async => await DatabaseHelper.instance.database;

  // Insert a new trade offer
  Future<int> insert(TradeOffer tradeOffer) async {
    final db = await database;
    return await db.insert(tableName, tradeOffer.toMap());
  }

  // Insert multiple trade offers
  Future<void> insertAll(List<TradeOffer> tradeOffers) async {
    final db = await database;
    final batch = db.batch();

    for (var offer in tradeOffers) {
      batch.insert(tableName, offer.toMap());
    }

    await batch.commit(noResult: true);
  }

  // Get a trade offer by ID
  Future<TradeOffer?> getById(int id) async {
    final db = await database;
    final maps = await db.query(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return TradeOffer.fromMap(maps.first);
    }
    return null;
  }

  // Get all trade offers
  Future<List<TradeOffer>> getAll() async {
    final db = await database;
    final maps = await db.query(tableName);

    return List.generate(maps.length, (i) {
      return TradeOffer.fromMap(maps[i]);
    });
  }

  // Get active trade offers
  Future<List<TradeOffer>> getActiveOffers() async {
    final db = await database;
    final maps = await db.query(
      tableName,
      where: 'status = ?',
      whereArgs: ['Active'],
    );

    return List.generate(maps.length, (i) {
      return TradeOffer.fromMap(maps[i]);
    });
  }

  // Get trade offers by year and month
  Future<List<TradeOffer>> getByYearAndMonth(String year, String month) async {
    final db = await database;
    final maps = await db.query(
      tableName,
      where: 'year = ? AND mon = ?',
      whereArgs: [year, month],
    );

    return List.generate(maps.length, (i) {
      return TradeOffer.fromMap(maps[i]);
    });
  }

  // Update a trade offer
  Future<int> update(TradeOffer tradeOffer) async {
    final db = await database;
    return await db.update(
      tableName,
      tradeOffer.toMap(),
      where: 'id = ?',
      whereArgs: [tradeOffer.id],
    );
  }

  // Delete a trade offer
  Future<int> delete(int id) async {
    final db = await database;
    return await db.delete(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Delete all trade offers
  Future<int> deleteAll() async {
    final db = await database;
    return await db.delete(tableName);
  }

  // Check if an item is part of any active trade offer
  Future<bool> isItemInActiveOffer(String itemCode) async {
    final db = await database;
    final activeOffers = await db.query(
      tableName,
      where: 'status = ?',
      whereArgs: ['Active'],
    );

    for (var offer in activeOffers) {
      final itemList = offer['item_list'] as String;
      final items = itemList.split(',');
      if (items.contains(itemCode)) {
        return true;
      }
    }

    return false;
  }

  // Get all trade offers that include a specific item
  Future<List<TradeOffer>> getOffersForItem(String itemCode) async {
    final db = await database;
    final allOffers = await db.query(tableName);
    final matchingOffers = <TradeOffer>[];

    for (var offer in allOffers) {
      final itemList = offer['item_list'] as String;
      final items = itemList.split(',');
      if (items.contains(itemCode)) {
        matchingOffers.add(TradeOffer.fromMap(offer));
      }
    }

    return matchingOffers;
  }
}
