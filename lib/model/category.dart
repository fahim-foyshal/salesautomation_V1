class Category {
  final String id;
  final String categoryName;

  Category({required this.id, required this.categoryName});

  factory Category.fromMap(Map<String, dynamic> json) {
    return Category(
      id: json['id'].toString(), // Convert int to String
      categoryName: json['category_name'].toString(),
    );
  }


  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category_name': categoryName,
    };
  }
}