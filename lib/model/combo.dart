class Combo {
  final int id;
  final String name;
  final int status;

  Combo({
    required this.id,
    required this.name,
    required this.status,
  });

  // Convert a Route object to a Map (for saving to a database or sending to an API)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'status': status,
    };
  }

  // Create a Route object from a Map (when retrieving from a database or API)
  factory Combo.fromMap(Map<String, dynamic> map) {
    return Combo(
      id: map['id'] is String ? int.parse(map['id']) : map['id'],
      name: map['name'],
      status:
          map['status'] is String ? int.parse(map['status']) : map['status'],
    );
  }
}
