import 'dart:isolate';

import 'package:sqflite/sqflite.dart';

import '../databases/item_dao.dart';
import '../model/item.dart';

class ItemRepository {
  final ItemDao itemDao = ItemDao();

  Future<int> addItem(Transaction txn,Item item) async => await itemDao.insertItemWithTransaction(txn,item);
  Future<List<Item>> getItems() async => await itemDao.getAllItems();
  Future<int> updateItem(Item item) async => await itemDao.updateItem(item);
  Future<int> deleteItem(String itemId) async => await itemDao.deleteItem(itemId);
}
