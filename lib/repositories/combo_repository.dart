import 'package:sqflite/sqflite.dart';

import '../databases/combo_dao.dart';
import '../model/combo.dart';

class ComboRepository {
  final ComboDao comboDao;

  ComboRepository(this.comboDao);

  // Add a Combo
  Future<int> addCombo(Transaction txn, Combo combo) async {
    return await comboDao.insertComboWithTransaction(txn, combo);
  }

  // Get all routes
  Future<List<Combo>> getAllRoutes() async {
    return await comboDao.getAllCombo();
  }

  // Get Combo by ID
  Future<Combo?> getRouteById(int routeId) async {
    return await comboDao.getComboId(routeId);
  }

  // Delete a Combo
}
