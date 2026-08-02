class TradeOffer {
  final int id;
  final String year;
  final String mon;
  final String offerName;
  final String itemList;
  final String minTaka;
  final String maxTaka;
  final String giftItemId;
  final String gitQty;
  final String giftItemName;
  final int comboId;

  final String status;
  final String entryBy;
  final String entryAt;

  TradeOffer({
    required this.id,
    required this.year,
    required this.mon,
    required this.offerName,
    required this.itemList,
    required this.minTaka,
    required this.maxTaka,
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
      'min_taka': minTaka,
      'max_taka': maxTaka,
      'gift_item_id': giftItemId,
      'git_qty': gitQty,
      'combo_id': comboId,
      'gift_item_name': giftItemName,
      'status': status,
      'entry_by': entryBy,
      'entry_at': entryAt,
    };
  }

  factory TradeOffer.fromMap(Map<String, dynamic> map) {
    return TradeOffer(
      id: map['id'] is int ? map['id'] : int.parse(map['id']),
      year: map['year'],
      mon: map['mon'],
      offerName: map['offer_name'],
      itemList: map['item_list'],
      minTaka: map['min_taka'],
      maxTaka: map['max_taka'],
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
