class Shop {
  final String dealerCode;
  final String shopName;
  final String routeId;
  final String latitude;
  final String longitude;

  Shop({
    required this.dealerCode,
    required this.shopName,
    required this.routeId,
    required this.latitude,
    required this.longitude,
  });

  // Convert a Shop into a Map object (for SQL insertion)
  Map<String, dynamic> toMap() {
    return {
      'dealer_code': dealerCode,
      'shop_name': shopName,
      'route_id': routeId,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  // Convert a Map object into a Shop (for reading from SQL)
  factory Shop.fromMap(Map<String, dynamic> map) {
    return Shop(
      dealerCode:
          map['dealer_code'].toString(), // Ensure dealerCode is a String
      shopName: map['shop_name'],
      routeId: map['route_id'].toString(), // Ensure routeId is a String
      latitude: map['latitude'].toString(),
      longitude: map['longitude'].toString(),
    );
  }
}
