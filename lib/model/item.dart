class Item {
  final String itemId;
  final String finishGoodsCode;
  final String itemName;
  final String unitName;
  final String tPrice;
  final String packSize;
  final String nspPer;
  final String categoryId; // No longer nullable, default to "N/A"
  final String subcategoryId; // No longer nullable, default to "N/A"

  Item({
    required this.itemId,
    required this.finishGoodsCode,
    required this.itemName,
    required this.unitName,
    required this.tPrice,
    required this.packSize,
    required this.nspPer,
    required this.categoryId, // Required, with "N/A" default
    required this.subcategoryId, // Required, with "N/A" default
  });

  factory Item.fromMap(Map<String, dynamic> json) {
    return Item(
      itemId: json['item_id'].toString(), // Ensure it's a String
      finishGoodsCode: json['finish_goods_code'].toString(),
      itemName: json['item_name'].toString(),
      unitName: json['unit_name'].toString(),
      tPrice: json['t_price'].toString(),
      packSize: json['pack_size'].toString(),
      nspPer: json['nsp_per'].toString(),
      categoryId: (json['category_id'] != null && json['category_id'].toString().isNotEmpty)
          ? json['category_id'].toString()
          : 'N/A', // Default to "N/A"
      subcategoryId: (json['subcategory_id'] != null && json['subcategory_id'].toString().isNotEmpty)
          ? json['subcategory_id'].toString()
          : 'N/A', // Default to "N/A"
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'item_id': itemId,
      'finish_goods_code': finishGoodsCode,
      'item_name': itemName,
      'unit_name': unitName,
      't_price': tPrice,
      'pack_size': packSize,
      'nsp_per': nspPer,
      'category_id': categoryId, // Always included, default is "N/A"
      'subcategory_id': subcategoryId, // Always included, default is "N/A"
    };
  }
}
