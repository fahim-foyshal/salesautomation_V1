class SubCategory {
  final String id;
  final String subcategoryName;
  final String categoryId;

  SubCategory({
    required this.id,
    required this.subcategoryName,
    required this.categoryId,
  });

  factory SubCategory.fromMap(Map<String, dynamic> json) {
    return SubCategory(
      id: json['id'].toString(), // Ensure it's always a String
      subcategoryName: json['subcategory_name'].toString(), // Ensure it's always a String
      categoryId: json['category_id'].toString(), // Ensure it's always a String
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'subcategory_name': subcategoryName,
      'category_id': categoryId,
    };
  }
}
