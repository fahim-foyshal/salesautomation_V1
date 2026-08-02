import 'package:sqflite/sqflite.dart';
import '../model/trade_offer_comission.dart';
import 'database_helper.dart';

class TradeOfferComissionDao {
  final tableName = 'trade_offer_comission';
  
  Future<Database> get database async => await DatabaseHelper.instance.database;

  // Insert a new trade offer comission
  Future<int> insert(TradeOfferComission tradeOfferComission) async {
    final db = await database;
    return await db.insert(tableName, tradeOfferComission.toMap());
  }

  // Insert a trade offer comission using a transaction
  Future<void> insertWithTransaction(Transaction txn, TradeOfferComission tradeOfferComission) async {
    await txn.insert(tableName, tradeOfferComission.toMap());
  }

  // Insert multiple trade offer comissions
  Future<void> insertAll(List<TradeOfferComission> tradeOfferComissions) async {
    final db = await database;
    final batch = db.batch();
    
    for (var offer in tradeOfferComissions) {
      batch.insert(tableName, offer.toMap());
    }
    
    await batch.commit(noResult: true);
  }

  // Get a trade offer comission by ID
  Future<TradeOfferComission?> getById(int id) async {
    final db = await database;
    final maps = await db.query(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return TradeOfferComission.fromMap(maps.first);
    }
    return null;
  }

  // Get all trade offer comissions
  Future<List<TradeOfferComission>> getAll() async {
    final db = await database;
    final maps = await db.query(tableName);
    
    return List.generate(maps.length, (i) {
      return TradeOfferComission.fromMap(maps[i]);
    });
  }

  // Get trade offer comissions by year and month
  Future<List<TradeOfferComission>> getByYearAndMonth(String year, String month) async {
    final db = await database;
    final maps = await db.query(
      tableName,
      where: 'year = ? AND mon = ?',
      whereArgs: [year, month],
    );
    
    return List.generate(maps.length, (i) {
      return TradeOfferComission.fromMap(maps[i]);
    });
  }

  // Update a trade offer comission
  Future<int> update(TradeOfferComission tradeOfferComission) async {
    final db = await database;
    return await db.update(
      tableName,
      tradeOfferComission.toMap(),
      where: 'id = ?',
      whereArgs: [tradeOfferComission.id],
    );
  }

  // Delete a trade offer comission
  Future<int> delete(int id) async {
    final db = await database;
    return await db.delete(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Delete all trade offer comissions
  Future<int> deleteAll() async {
    final db = await database;
    return await db.delete(tableName);
  }

  // Check if an item is part of any trade offer comission
  Future<bool> isItemInTradeOfferComission(String itemCode) async {
    final db = await database;
    final offers = await db.query(tableName);
    
    for (var offer in offers) {
      final itemList = offer['item_list'] as String;
      final items = itemList.split(',');
      if (items.contains(itemCode)) {
        return true;
      }
    }
    
    return false;
  }

  // Get all trade offer comissions that include a specific item
  Future<List<TradeOfferComission>> getOffersForItem(String itemCode) async {
    final db = await database;
    final allOffers = await db.query(tableName);
    final matchingOffers = <TradeOfferComission>[];
    
    for (var offer in allOffers) {
      final itemList = offer['item_list'] as String;
      final items = itemList.split(',');
      if (items.contains(itemCode)) {
        matchingOffers.add(TradeOfferComission.fromMap(offer));
      }
    }
    
    return matchingOffers;
  }
}