class SsRoute {
  final int routeId;
  final String routeName;

  SsRoute({
    required this.routeId,
    required this.routeName,
  });

  // Convert a Route object to a Map (for saving to a database or sending to an API)
  Map<String, dynamic> toMap() {
    return {
      'route_id': routeId,
      'route_name': routeName,
    };
  }

  // Create a Route object from a Map (when retrieving from a database or API)
  factory SsRoute.fromMap(Map<String, dynamic> map) {
    return SsRoute(
      routeId: map['route_id'] is String ? int.parse(map['route_id']) : map['route_id'],
      routeName: map['route_name'],
    );
  }

}
