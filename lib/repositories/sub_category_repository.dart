import 'package:flutter/cupertino.dart';
import 'package:sqflite/sqflite.dart';

import '../databases/sub_category_dao.dart';
import '../model/sub_category.dart';

class SubCategoryRepository {
  final SubCategoryDao subCategoryDao = SubCategoryDao();

  Future<int> addSubCategory(Transaction txn,SubCategory subCategory) async => await subCategoryDao.insertSubCategoryWithTransaction(txn,subCategory);
  Future<List<SubCategory>> getSubCategories() async => await subCategoryDao.getAllSubCategories();
  Future<int> updateSubCategory(SubCategory subCategory) async => await subCategoryDao.updateSubCategory(subCategory);
  Future<int> deleteSubCategory(String id) async => await subCategoryDao.deleteSubCategory(id);
}
