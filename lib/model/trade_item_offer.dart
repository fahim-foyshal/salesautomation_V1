class TradeItemOffer {
  final int id;
  final String year;
  final String mon;
  final String offerName;
  final String itemList;
  final String minQty;
  final String maxQty;
  final String giftItemId;
  final String gitQty;
  final String giftItemName;
  final String status;
  final int comboId;
  final String entryBy;
  final String entryAt;

  TradeItemOffer({
    required this.id,
    required this.year,
    required this.mon,
    required this.offerName,
    required this.itemList,
    required this.minQty,
    required this.maxQty,
    required this.giftItemId,
    required this.gitQty,
    required this.giftItemName,
    required this.comboId,
    this.status = 'Active',
    this.entryBy = '',
    this.entryAt = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'year': year,
      'mon': mon,
      'offer_name': offerName,
      'item_list': itemList,
      'min_qty': minQty,
      'max_qty': maxQty,
      'gift_item_id': giftItemId,
      'git_qty': gitQty,
      'gift_item_name': giftItemName,
      'status': status,
      'combo_id': comboId,
      'entry_by': entryBy,
      'entry_at': entryAt,
    };
  }

  factory TradeItemOffer.fromMap(Map<String, dynamic> map) {
    return TradeItemOffer(
      id: map['id'] is int ? map['id'] : int.parse(map['id']),
      year: map['year'],
      mon: map['mon'],
      offerName: map['offer_name'],
      itemList: map['item_list'],
      minQty: map['min_qty'],
      maxQty: map['max_qty'],
      giftItemId: map['gift_item_id'],
      gitQty: map['git_qty'],
      giftItemName: map['gift_item_name'],
      status: map['status'] ?? 'Active',
      comboId: map['combo_id'],
      entryBy: map['entry_by'] ?? '',
      entryAt: map['entry_at'] ?? '',
    );
  }
}
