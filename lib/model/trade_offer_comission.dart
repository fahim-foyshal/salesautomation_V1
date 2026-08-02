class TradeOfferComission {
  final int id;
  final String year;
  final String mon;
  final String offerName;
  final String itemGroup;
  final String itemList;
  final String minQty;
  final String maxQty;
  final String freeQty;
  final int comboId;

  final String tradeComPer;

  TradeOfferComission({
    required this.id,
    required this.year,
    required this.mon,
    required this.offerName,
    required this.itemGroup,
    required this.itemList,
    required this.minQty,
    required this.maxQty,
    required this.freeQty,
    required this.comboId,
    required this.tradeComPer,
  });

  // Convert a TradeOfferComission object into a Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'year': year,
      'mon': mon,
      'offer_name': offerName,
      'item_group': itemGroup,
      'item_list': itemList,
      'min_qty': minQty,
      'max_qty': maxQty,
      'free_qty': freeQty,
      'combo_id': comboId,
      'trade_com_per': tradeComPer,
    };
  }

  // Create a TradeOfferComission object from a Map
  factory TradeOfferComission.fromMap(Map<String, dynamic> map) {
    return TradeOfferComission(
      id: map['id'] is int ? map['id'] : int.parse(map['id']),
      year: map['year'],
      mon: map['mon'],
      offerName: map['offer_name'],
      itemGroup: map['item_group'],
      itemList: map['item_list'],
      minQty: map['min_qty'],
      maxQty: map['max_qty'],
      freeQty: map['free_qty'],
      comboId: map['combo_id'],
      tradeComPer: map['trade_com_per'],
    );
  }
}
