class DoMaster {
  int? doOfflineId; // Primary key (Auto-generated)
  final String doNo; // do_no
  final String shopId; // shop_id
  final String doDate; // do_date
  String status; // do_date
  final String sentStatus; // sent_status (e.g., 'pending', 'sent')
  String tradeOfferApplied;
  String? comboId;
  String? endLatitude;
  String? endLongitude;
  String? note;
  String? type;

  DoMaster({
    this.doOfflineId,
    required this.status,
    required this.doNo,
    required this.shopId,
    required this.doDate,
    required this.sentStatus,
    required this.tradeOfferApplied,
    this.comboId,
    this.endLatitude,
    this.endLongitude,
    this.note,
    this.type,
  });

  // Convert a DoMaster into a Map for SQLite insertion
  Map<String, dynamic> toMap() {
    return {
      'do_no': doNo,
      'shop_id': shopId,
      'do_date': doDate,
      'sent_status': sentStatus, // Add sent_status here
      'status': status, // Add sent_status here
      'trade_offer_applied': tradeOfferApplied,
      'combo_id': comboId,
      'end_latitude': endLatitude,
      'end_longitude': endLongitude,
      'note': note,
      'type': type,
    };
  }

  // Convert a Map into a DoMaster object
  factory DoMaster.fromMap(Map<String, dynamic> map) {
    return DoMaster(
      doOfflineId: map['do_offline_id'],
      status: map['status'],
      doNo: map['do_no'],
      shopId: map['shop_id'],
      doDate: map['do_date'],
      sentStatus:
          map['sent_status'] ?? 'pending', // Default to 'pending' if null
      tradeOfferApplied: map['trade_offer_applied'],
      endLatitude: map['end_latitude'],
      endLongitude: map['end_longitude'],
      comboId: map['combo_id'],
      note: map['note'],
      type: map['type'],
    );
  }
}
