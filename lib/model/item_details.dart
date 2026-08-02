import 'item.dart';

class ItemDetails extends Item {
  int? doDetailsId; // Auto-increment primary key (nullable)
  String doMasterId; // ID for the master record
  String finishGoodsCode; // Finish goods code
  String itemName; // Item name
  String unitName; // Unit name
  String tPrice; // Total price
  String packSize; // Pack size
  String nspPer; // NSP per unit
  String? nspOrg; // NSP original
  String? nspExtra; // NSP extra
  String originalNspPer; // To hold the original value for comparison
  String categoryId; // Category ID
  String subcategoryId; // Subcategory ID
  String offer;
  String qty;
  String amt;
  String? giftId; // New optional field

  ItemDetails({
    this.doDetailsId,
    required String itemId,
    required this.finishGoodsCode,
    required this.itemName,
    required this.unitName,
    required this.tPrice,
    required this.packSize,
    required this.nspPer,
    this.nspOrg,
    this.nspExtra,
    required this.originalNspPer,
    required this.categoryId,
    required this.subcategoryId,
    required this.doMasterId,
    this.offer = '',
    this.qty = '',
    this.amt = '',
    this.giftId,
  }) : super(
          itemId: itemId,
          finishGoodsCode: finishGoodsCode,
          itemName: itemName,
          unitName: unitName,
          tPrice: tPrice,
          packSize: packSize,
          nspPer: nspPer,
          categoryId: categoryId,
          subcategoryId: subcategoryId,
        );

  // Converts an Item object into an ItemDetails object
  factory ItemDetails.fromItem(Item item, String doMasterId) {
    return ItemDetails(
      itemId: item.itemId,
      finishGoodsCode: item.finishGoodsCode,
      itemName: item.itemName,
      unitName: item.unitName,
      tPrice: item.tPrice,
      packSize: item.packSize,
      nspPer: item.nspPer,
      originalNspPer: item.nspPer,
      nspOrg: item.nspPer,
      nspExtra: '0',
      categoryId: item.categoryId,
      subcategoryId: item.subcategoryId,
      doMasterId: doMasterId,
    );
  }

  // Converts ItemDetails to a Map for database operations
  @override
  Map<String, dynamic> toMap() {
    return {
      'do_master_id': doMasterId,
      'item_id': itemId,
      'finish_goods_code': finishGoodsCode,
      'item_name': itemName,
      'unit_name': unitName,
      't_price': tPrice,
      'pack_size': packSize,
      'nsp_per': nspPer,
      'nsp_org': nspOrg,
      'nsp_extra': nspExtra,
      'category_id': categoryId,
      'subcategory_id': subcategoryId,
      'offer': offer,
      'qty': qty,
      'amt': amt,
      'gift_id': giftId,
    };
  }

  // Creates an ItemDetails object from a Map
  factory ItemDetails.fromMap(Map<String, dynamic> json) {
    return ItemDetails(
      doDetailsId:
          json['do_details_id'] != null ? json['do_details_id'] as int : null,
      doMasterId: json['do_master_id'],
      itemId: json['item_id'],
      finishGoodsCode: json['finish_goods_code'],
      itemName: json['item_name'],
      unitName: json['unit_name'],
      tPrice: json['t_price'],
      packSize: json['pack_size'],
      nspPer: json['nsp_per'],
      originalNspPer: json['nsp_per'],
      nspOrg: json['nsp_org'],
      nspExtra: json['nsp_extra'],
      categoryId: json['category_id'],
      subcategoryId: json['subcategory_id'],
      offer: json['offer'] ?? '',
      qty: json['qty'] ?? '',
      amt: json['amt'] ?? '',
      giftId: json['gift_id'], // include gift_id parsing
    );
  }
}
