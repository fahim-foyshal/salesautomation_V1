import 'package:sqflite/sqflite.dart';

import '../databases/category_dao.dart';
import '../model/category.dart';

class CategoryRepository {
  final CategoryDao categoryDao = CategoryDao();

  Future<int> addCategory(Transaction txn,Category category) async => await categoryDao.insertCategoryWithTransaction(txn,category);
  Future<List<Category>> getCategories() async => await categoryDao.getAllCategories();
  Future<int> updateCategory(Category category) async => await categoryDao.updateCategory(category);
  Future<int> deleteCategory(String id) async => await categoryDao.deleteCategory(id);
}
