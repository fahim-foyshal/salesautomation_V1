// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:salesautomation_V4/repositories/category_repository.dart';
// import 'package:salesautomation_V4/repositories/item_repository.dart';
// import 'package:salesautomation_V4/repositories/sub_category_repository.dart';
// import 'package:dropdown_button2/dropdown_button2.dart';
//
// import 'model/category.dart';
// import 'model/item.dart';
// import 'model/item_details.dart';
// import 'model/sub_category.dart';
//
// class AddItemsPage extends StatefulWidget {
//   const AddItemsPage({Key? key}) : super(key: key);
//
//   @override
//   State<AddItemsPage> createState() => _AddItemsPageState();
// }
//
// class _AddItemsPageState extends State<AddItemsPage> {
//   final ItemRepository itemRepository = ItemRepository();
//   final CategoryRepository categoryRepository = CategoryRepository();
//   final SubCategoryRepository subCategoryRepository = SubCategoryRepository();
//
//   List<Item> items = [];
//   List<ItemDetails> itemDetailsList = [];
//   List<Category> categories = [];
//   List<SubCategory> subCategories = [];
//   String? selectedCategory;
//   String? selectedSubCategory;
//   final TextEditingController categorySearchController = TextEditingController();
//   final TextEditingController subCategorySearchController = TextEditingController();
//
//   final List<Map<String, dynamic>> columns = [
//     {'name': 'Item', 'flex': 1},
//     {'name': 'Unit', 'flex': 1},
//     {'name': 'Stock', 'flex': 1},
//     {'name': 'TP', 'flex': 1},
//     {'name': 'NSP', 'flex': 1},
//     {'name': 'Offer %', 'flex': 1},
//     {'name': 'Qty', 'flex': 1},
//     {'name': 'Amt', 'flex': 1},
//   ];
//
//   @override
//   void initState() {
//     super.initState();
//     fetchItems();
//     fetchCategories();
//   }
//
//   @override
//   void dispose() {
//     categorySearchController.dispose();
//     subCategorySearchController.dispose();
//     super.dispose();
//   }
//
//   Future<void> fetchItems() async {
//     List<Item> fetchedItems = await itemRepository.getItems();
//     setState(() {
//       itemDetailsList = fetchedItems.map((item) => ItemDetails.fromItem(item)).toList();
//     });
//   }
//
//   Future<void> fetchCategories() async {
//     List<Category> fetchedCategories = await categoryRepository.getCategories();
//     setState(() {
//       categories = fetchedCategories;
//     });
//   }
//
//   Future<void> fetchSubCategories(String categoryId) async {
//     List<SubCategory> fetchedSubCategories = await subCategoryRepository.getSubCategories();
//     setState(() {
//       subCategories = fetchedSubCategories.where((sub) => sub.categoryId == categoryId).toList();
//       selectedSubCategory = null;
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Add Items'),
//         leading: IconButton(
//           icon: const Icon(Icons.menu),
//           onPressed: () {},
//         ),
//       ),
//       body: Column(
//         children: [
//           // Order Info Card
//           Card(
//             margin: const EdgeInsets.all(10),
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(10),
//               side: const BorderSide(color: Colors.blue, width: 1),
//             ),
//             child: Padding(
//               padding: const EdgeInsets.all(16.0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       const Text('Shop:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//                       Container(
//                         padding: const EdgeInsets.all(8),
//                         decoration: BoxDecoration(
//                           border: Border.all(color: Colors.blue),
//                           borderRadius: BorderRadius.circular(5),
//                         ),
//                         child: const Text(
//                           'DO NO : 1622647',
//                           style: TextStyle(color: Colors.blue, fontSize: 16),
//                         ),
//                       ),
//                     ],
//                   ),
//                   const Text('Arif Election', style: TextStyle(fontSize: 18)),
//                   const SizedBox(height: 10),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       RichText(
//                         text: const TextSpan(
//                           children: [
//                             TextSpan(
//                               text: 'Order Date: ',
//                               style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 16),
//                             ),
//                             TextSpan(
//                               text: '2025-03-12',
//                               style: TextStyle(color: Colors.black, fontSize: 16),
//                             ),
//                           ],
//                         ),
//                       ),
//                       const Text(
//                         '0',
//                         style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ),
//
//           // Filter Row with dropdown_button2
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 10),
//             child: Row(
//               children: [
//                 // Category Dropdown
//                 Expanded(
//                   child: DropdownButtonHideUnderline(
//                     child: DropdownButton2<String>(
//                       isExpanded: true,
//                       hint: Text(
//                         'Select Category',
//                         style: TextStyle(
//                           fontSize: 16,
//                           color: Theme.of(context).hintColor,
//                         ),
//                       ),
//                       items: categories
//                           .map((category) => DropdownMenuItem(
//                         value: category.id,
//                         child: Text(
//                           category.categoryName,
//                           style: const TextStyle(fontSize: 16),
//                         ),
//                       ))
//                           .toList(),
//                       value: selectedCategory,
//                       onChanged: (value) {
//                         setState(() {
//                           selectedCategory = value;
//                           fetchSubCategories(selectedCategory!);
//                         });
//                       },
//                       buttonStyleData: ButtonStyleData(
//                         padding: const EdgeInsets.symmetric(horizontal: 16),
//                         height: 40,
//                         width: double.infinity,
//                         decoration: BoxDecoration(
//                           borderRadius: BorderRadius.circular(5),
//                           border: Border.all(color: Colors.blue),
//                         ),
//                       ),
//                       dropdownStyleData: DropdownStyleData(
//                         maxHeight: 300,
//                         decoration: BoxDecoration(
//                           borderRadius: BorderRadius.circular(5),
//                         ),
//                         scrollbarTheme: ScrollbarThemeData(
//                           radius: const Radius.circular(40),
//                           thickness: MaterialStateProperty.all(6),
//                           thumbVisibility: MaterialStateProperty.all(true),
//                         ),
//                         offset: const Offset(0, 0),
//                         scrollPadding: EdgeInsets.zero,
//                       ),
//                       menuItemStyleData: const MenuItemStyleData(
//                         height: 40,
//                         padding: EdgeInsets.symmetric(horizontal: 8),
//                       ),
//                       dropdownSearchData: DropdownSearchData(
//                         searchController: categorySearchController,
//                         searchInnerWidgetHeight: 50,
//                         searchInnerWidget: Container(
//                           height: 50,
//                           padding: const EdgeInsets.only(
//                             top: 8,
//                             bottom: 4,
//                             right: 8,
//                             left: 8,
//                           ),
//                           child: TextFormField(
//                             expands: true,
//                             maxLines: null,
//                             controller: categorySearchController,
//                             decoration: InputDecoration(
//                               isDense: true,
//                               contentPadding: const EdgeInsets.symmetric(
//                                 horizontal: 10,
//                                 vertical: 8,
//                               ),
//                               hintText: 'Search for category...',
//                               hintStyle: const TextStyle(fontSize: 14),
//                               border: OutlineInputBorder(
//                                 borderRadius: BorderRadius.circular(5),
//                               ),
//                             ),
//                           ),
//                         ),
//                         searchMatchFn: (item, searchValue) {
//                           final categoryName = categories
//                               .firstWhere((category) => category.id == item.value)
//                               .categoryName;
//                           return categoryName
//                               .toLowerCase()
//                               .contains(searchValue.toLowerCase());
//                         },
//                       ),
//                     ),
//                   ),
//                 ),
//
//                 const SizedBox(width: 10),
//
//                 // Subcategory Dropdown
//                 Expanded(
//                   child: DropdownButtonHideUnderline(
//                     child: DropdownButton2<String>(
//                       isExpanded: true,
//                       hint: Text(
//                         'Select Subcategory',
//                         style: TextStyle(
//                           fontSize: 16,
//                           color: Theme.of(context).hintColor,
//                         ),
//                       ),
//                       items: subCategories
//                           .map((subcategory) => DropdownMenuItem(
//                         value: subcategory.id,
//                         child: Text(
//                           subcategory.subcategoryName,
//                           style: const TextStyle(fontSize: 16),
//                         ),
//                       ))
//                           .toList(),
//                       value: selectedSubCategory,
//                       onChanged: (value) {
//                         setState(() {
//                           selectedSubCategory = value;
//                         });
//                       },
//                       buttonStyleData: ButtonStyleData(
//                         padding: const EdgeInsets.symmetric(horizontal: 16),
//                         height: 40,
//                         width: double.infinity,
//                         decoration: BoxDecoration(
//                           borderRadius: BorderRadius.circular(5),
//                           border: Border.all(color: Colors.blue),
//                         ),
//                       ),
//                       dropdownStyleData: DropdownStyleData(
//                         maxHeight: 300,
//                         decoration: BoxDecoration(
//                           borderRadius: BorderRadius.circular(5),
//                         ),
//                         scrollbarTheme: ScrollbarThemeData(
//                           radius: const Radius.circular(40),
//                           thickness: MaterialStateProperty.all(6),
//                           thumbVisibility: MaterialStateProperty.all(true),
//                         ),
//                         offset: const Offset(0, 0),
//                         scrollPadding: EdgeInsets.zero,
//                       ),
//                       menuItemStyleData: const MenuItemStyleData(
//                         height: 40,
//                         padding: EdgeInsets.symmetric(horizontal: 8),
//                       ),
//                       dropdownSearchData: DropdownSearchData(
//                         searchController: subCategorySearchController,
//                         searchInnerWidgetHeight: 50,
//                         searchInnerWidget: Container(
//                           height: 50,
//                           padding: const EdgeInsets.only(
//                             top: 8,
//                             bottom: 4,
//                             right: 8,
//                             left: 8,
//                           ),
//                           child: TextFormField(
//                             expands: true,
//                             maxLines: null,
//                             controller: subCategorySearchController,
//                             decoration: InputDecoration(
//                               isDense: true,
//                               contentPadding: const EdgeInsets.symmetric(
//                                 horizontal: 10,
//                                 vertical: 8,
//                               ),
//                               hintText: 'Search for subcategory...',
//                               hintStyle: const TextStyle(fontSize: 14),
//                               border: OutlineInputBorder(
//                                 borderRadius: BorderRadius.circular(5),
//                               ),
//                             ),
//                           ),
//                         ),
//                         searchMatchFn: (item, searchValue) {
//                           if (subCategories.isEmpty) return false;
//                           try {
//                             final subcategoryName = subCategories
//                                 .firstWhere((subcat) => subcat.id == item.value)
//                                 .subcategoryName;
//                             return subcategoryName
//                                 .toLowerCase()
//                                 .contains(searchValue.toLowerCase());
//                           } catch (e) {
//                             return false;
//                           }
//                         },
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//
//           // Table Header using Flex
//           Container(
//             margin: const EdgeInsets.only(top: 10),
//             color: const Color(0xFF0066B3),
//             child: Padding(
//               padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
//               child: Row(
//                 children: columns.map((column) =>
//                     Expanded(
//                       flex: column['flex'],
//                       child: Text(
//                         column['name'],
//                         style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 8),
//                         textAlign: TextAlign.center,
//                       ),
//                     )
//                 ).toList(),
//               ),
//             ),
//           ),
//
//           // Table Content using ListView and Grid
//           Expanded(
//             child: ListView.builder(
//               itemCount: itemDetailsList.length,
//               itemBuilder: (context, index) {
//                 return _buildItemRow(itemDetailsList[index]);
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildItemRow(ItemDetails item) {
//     return Container(
//       decoration: const BoxDecoration(
//         border: Border(bottom: BorderSide(color: Colors.blue, width: 1)),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Item name and code
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   item.itemName,
//                   style: const TextStyle(fontWeight: FontWeight.bold),
//                 ),
//                 Text(
//                   item.finishGoodsCode,
//                   style: const TextStyle(color: Colors.grey),
//                 ),
//               ],
//             ),
//           ),
//
//           // Item details using Grid/Flex
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
//             child: Row(
//               children: [
//                 Expanded(flex: 1, child: Container()),
//
//                 // Unit
//                 Expanded(
//                   flex: 1,
//                   child: Text(
//                     item.unitName,
//                     style: const TextStyle(fontSize: 8),
//                     textAlign: TextAlign.center,
//                   ),
//                 ),
//
//                 // Stock (Assumed Default)
//                 Expanded(
//                   flex: 1,
//                   child: Text(
//                     '0',
//                     style: const TextStyle(fontSize: 8),
//                     textAlign: TextAlign.center,
//                   ),
//                 ),
//
//                 // TP
//                 Expanded(
//                   flex: 1,
//                   child: Text(
//                     item.tPrice,
//                     style: const TextStyle(fontSize: 8),
//                     textAlign: TextAlign.center,
//                   ),
//                 ),
//
//                 // NSP
//                 Expanded(
//                   flex: 1,
//                   child: Text(
//                     item.nspPer,
//                     style: const TextStyle(fontSize: 8),
//                     textAlign: TextAlign.center,
//                   ),
//                 ),
//
//                 // Offer %
//                 Expanded(
//                   flex: 1,
//                   child: Container(
//                     height: 35,
//                     padding: const EdgeInsets.symmetric(horizontal: 5),
//                     decoration: BoxDecoration(
//                       border: Border.all(color: Colors.blue),
//                       borderRadius: BorderRadius.circular(5),
//                     ),
//                     child: TextFormField(
//                       style: const TextStyle(fontSize: 8),
//                       initialValue: item.offer,
//                       textAlign: TextAlign.center,
//                       keyboardType: TextInputType.number,
//                       decoration: const InputDecoration(
//                         border: InputBorder.none,
//                         isCollapsed: true,
//                         contentPadding: EdgeInsets.symmetric(vertical: 9),
//                       ),
//                       onChanged: (value) {
//                         setState(() {
//                           item.offer = value;
//                         });
//                       },
//                     ),
//                   ),
//                 ),
//
//                 // Qty
//                 Expanded(
//                   flex: 1,
//                   child: Container(
//                     height: 35,
//                     margin: const EdgeInsets.symmetric(horizontal: 5),
//                     decoration: BoxDecoration(
//                       border: Border.all(color: Colors.blue),
//                       borderRadius: BorderRadius.circular(5),
//                     ),
//                     child: TextFormField(
//                       style: const TextStyle(fontSize: 8),
//                       initialValue: item.qty,
//                       textAlign: TextAlign.center,
//                       keyboardType: TextInputType.number,
//                       decoration: const InputDecoration(
//                         border: InputBorder.none,
//                         isCollapsed: true,
//                         contentPadding: EdgeInsets.symmetric(vertical: 9),
//                       ),
//                       onChanged: (value) {
//                         setState(() {
//                           item.qty = value;
//                         });
//                       },
//                     ),
//                   ),
//                 ),
//
//                 // Amt
//                 Expanded(
//                   flex: 1,
//                   child: Container(
//                     height: 35,
//                     decoration: BoxDecoration(
//                       border: Border.all(color: Colors.blue),
//                       borderRadius: BorderRadius.circular(5),
//                     ),
//                     child: TextFormField(
//                       style: const TextStyle(fontSize: 8),
//                       initialValue: item.amt,
//                       textAlign: TextAlign.center,
//                       keyboardType: TextInputType.number,
//                       decoration: const InputDecoration(
//                         border: InputBorder.none,
//                         isCollapsed: true,
//                         contentPadding: EdgeInsets.symmetric(vertical: 9),
//                       ),
//                       onChanged: (value) {
//                         setState(() {
//                           item.amt = value;
//                         });
//                       },
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }