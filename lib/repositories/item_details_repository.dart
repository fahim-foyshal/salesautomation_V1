import '../databases/item_details_dao.dart';
import '../model/item_details.dart';

class ItemDetailsRepository {
  final ItemDetailsDao itemDetailsDao = ItemDetailsDao();

  Future<int> addOrUpdateItemDetails(ItemDetails item) async {
    return await itemDetailsDao.insertOrUpdateItemDetails(item);
  }

  Future<List<ItemDetails>> getItemDetails() async {
    return await itemDetailsDao.getAllItemDetails();
  }
}
