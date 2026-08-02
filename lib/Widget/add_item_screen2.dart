import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:salesautomation_V4/repositories/category_repository.dart';
import 'package:salesautomation_V4/repositories/item_repository.dart';
import 'package:salesautomation_V4/repositories/sub_category_repository.dart';

import 'model/category.dart';
import 'model/item.dart';
import 'model/item_details.dart';
import 'model/sub_category.dart';

class AddItemsPage extends StatefulWidget {
  const AddItemsPage({Key? key}) : super(key: key);

  @override
  State<AddItemsPage> createState() => _AddItemsPageState();
}

class _AddItemsPageState extends State<AddItemsPage> {
  final ItemRepository itemRepository = ItemRepository();
  final CategoryRepository categoryRepository = CategoryRepository();
  final SubCategoryRepository subCategoryRepository = SubCategoryRepository();

  List<Item> items = [];
  List<ItemDetails> itemDetailsList = [];
  List<Category> categories = [];
  List<SubCategory> subCategories = [];
  String? selectedCategory;
  String? selectedSubCategory;
  final List<Map<String, dynamic>> columns = [
    {'name': 'Item', 'flex': 1},
    {'name': 'Unit', 'flex': 1},
    {'name': 'Stock', 'flex': 1},
    {'name': 'TP', 'flex': 1},
    {'name': 'NSP', 'flex': 1},
    {'name': 'Offer %', 'flex': 1},
    {'name': 'Qty', 'flex': 1},
    {'name': 'Amt', 'flex': 1},
  ];

  @override
  void initState() {
    super.initState();
    fetchItems();
    fetchCategories();
  }



  Future<void> fetchItems() async {
    List<Item> fetchedItems = await itemRepository.getItems();
    setState(() {
      itemDetailsList = fetchedItems.map((item) => ItemDetails.fromItem(item)).toList();
    });
  }

  Future<void> fetchCategories() async {
    List<Category> fetchedCategories = await categoryRepository.getCategories();
    setState(() {
      categories = fetchedCategories;
    });
  }

  Future<void> fetchSubCategories(String categoryId) async {
    List<SubCategory> fetchedSubCategories = await subCategoryRepository.getSubCategories();
    setState(() {
      subCategories = fetchedSubCategories.where((sub) => sub.categoryId == categoryId).toList();
      selectedSubCategory = null;
    });
  }

  void _showCategoryDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return ListView.builder(
          itemCount: categories.length,
          itemBuilder: (context, index) {
            return ListTile(
              title: Text(categories[index].categoryName),
              onTap: () {
                setState(() {
                  selectedCategory = categories[index].id;
                  fetchSubCategories(selectedCategory!);
                });
                Navigator.pop(context);
              },
            );
          },
        );
      },
    );
  }

  void _showSubCategoryDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return ListView.builder(
          itemCount: subCategories.length,
          itemBuilder: (context, index) {
            return ListTile(
              title: Text(subCategories[index].subcategoryName),
              onTap: () {
                setState(() {
                  selectedSubCategory = subCategories[index].id;
                });
                Navigator.pop(context);
              },
            );
          },
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Items'),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {},
        ),
      ),
      body: Column(
        children: [
          // Order Info Card
          Card(
            margin: const EdgeInsets.all(10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: const BorderSide(color: Colors.blue, width: 1),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Shop:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.blue),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: const Text(
                          'DO NO : 1622647',
                          style: TextStyle(color: Colors.blue, fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                  const Text('Arif Election', style: TextStyle(fontSize: 18)),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      RichText(
                        text: const TextSpan(
                          children: [
                            TextSpan(
                              text: 'Order Date: ',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 16),
                            ),
                            TextSpan(
                              text: '2025-03-12',
                              style: TextStyle(color: Colors.black, fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                      const Text(
                        '0',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Filter Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _showCategoryDialog,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.blue),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        selectedCategory != null ? categories.firstWhere((cat) => cat.id == selectedCategory).categoryName : 'Select Category',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: _showSubCategoryDialog,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.blue),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        selectedSubCategory != null ? subCategories.firstWhere((sub) => sub.id == selectedSubCategory).subcategoryName : 'Select Subcategory',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Table Header using Flex
          Container(
            margin: const EdgeInsets.only(top: 10),
            color: const Color(0xFF0066B3),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
              child: Row(
                children: columns.map((column) =>
                    Expanded(
                      flex: column['flex'],
                      child: Text(
                        column['name'],
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold,fontSize: 8),
                        textAlign: TextAlign.center,
                      ),
                    )
                ).toList(),
              ),
            ),
          ),

          // Table Content using ListView and Grid
          Expanded(
            child: ListView.builder(
              itemCount: itemDetailsList.length, // ✅ Use the new list
              itemBuilder: (context, index) {
                return _buildItemRow(itemDetailsList[index]); // ✅ Pass `ItemDetails`
              },
            ),
          ),

        ],
      ),
    );
  }

  Widget _buildItemRow(ItemDetails item) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.blue, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Item name and code
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.itemName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  item.finishGoodsCode,
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),

          // Item details using Grid/Flex
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: Row(
              children: [
                Expanded(flex: 1, child: Container()),

                // Unit
                Expanded(
                  flex: 1,
                  child: Text(
                    item.unitName,
                    style: const TextStyle(fontSize: 8),
                    textAlign: TextAlign.center,
                  ),
                ),

                // Stock (Assumed Default)
                Expanded(
                  flex: 1,
                  child: Text(
                    '0',
                    style: const TextStyle(fontSize: 8),
                    textAlign: TextAlign.center,
                  ),
                ),

                // TP
                Expanded(
                  flex: 1,
                  child: Text(
                    item.tPrice,
                    style: const TextStyle(fontSize: 8),
                    textAlign: TextAlign.center,
                  ),
                ),

                // NSP
                Expanded(
                  flex: 1,
                  child: Text(
                    item.nspPer,
                    style: const TextStyle(fontSize: 8),
                    textAlign: TextAlign.center,
                  ),
                ),

                // Offer %
                Expanded(
                  flex: 1,
                  child: Container(
                    height: 35,
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.blue),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: TextFormField(
                      style: const TextStyle(fontSize: 8),
                      initialValue: item.offer,
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isCollapsed: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 9),
                      ),
                      onChanged: (value) {
                        setState(() {
                          item.offer = value;
                        });
                      },
                    ),
                  ),
                ),

                // Qty
                Expanded(
                  flex: 1,
                  child: Container(
                    height: 35,
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.blue),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: TextFormField(
                      style: const TextStyle(fontSize: 8),
                      initialValue: item.qty,
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isCollapsed: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 9),
                      ),
                      onChanged: (value) {
                        setState(() {
                          item.qty = value;
                        });
                      },
                    ),
                  ),
                ),

                // Amt
                Expanded(
                  flex: 1,
                  child: Container(
                    height: 35,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.blue),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: TextFormField(
                      style: const TextStyle(fontSize: 8),
                      initialValue: item.amt,
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isCollapsed: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 9),
                      ),
                      onChanged: (value) {
                        setState(() {
                          item.amt = value;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

}