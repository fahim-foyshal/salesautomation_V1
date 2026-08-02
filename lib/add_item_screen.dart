import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:salesautomation_V4/databases/combo_dao.dart';
import 'package:salesautomation_V4/databases/database_helper.dart';
import 'package:salesautomation_V4/databases/do_master_dao.dart';
import 'package:salesautomation_V4/databases/item_dao.dart';
import 'package:salesautomation_V4/model/Shop.dart';
import 'package:salesautomation_V4/model/combo.dart';
import 'package:salesautomation_V4/model/do_master.dart';
import 'package:salesautomation_V4/model/trade_offer.dart';
import 'package:salesautomation_V4/model/trade_offer_comission.dart';
import 'package:salesautomation_V4/repositories/category_repository.dart';
import 'package:salesautomation_V4/repositories/combo_repository.dart';
import 'package:salesautomation_V4/repositories/item_repository.dart';
import 'package:salesautomation_V4/repositories/sub_category_repository.dart';
import 'package:salesautomation_V4/route_and_shop_selection_screen.dart';
import 'package:salesautomation_V4/NavigatonPage.dart';
import 'databases/item_details_dao.dart';
import 'model/category.dart';
import 'model/item.dart';
import 'model/item_details.dart';
import 'model/sub_category.dart';

class AddItemsPage extends StatefulWidget {
  final DoMaster doOfflineId;
  final Shop shopId;

  const AddItemsPage(
      {super.key, required this.doOfflineId, required this.shopId});
  @override
  State<AddItemsPage> createState() => _AddItemsPageState();
}

class _AddItemsPageState extends State<AddItemsPage> {
  late String _tradeofferapplier;

  final ItemRepository itemRepository = ItemRepository();
  final CategoryRepository categoryRepository = CategoryRepository();
  final SubCategoryRepository subCategoryRepository = SubCategoryRepository();
  final itemDetailsDao = ItemDetailsDao();
  final doMasterDao = DoMasterDao();
  List<Item> allItems = [];
  List<ItemDetails> allItemDetails = []; // Store Item details all items
  List<ItemDetails> filteredItemDetailsList = []; // Display filtered items
  List<Category> categories = [];
  List<SubCategory> subCategories = [];
  String? selectedCategory;
  String? selectedSubCategory;
  double totalAmount = 0.0;
  // Controllers for search
  final TextEditingController _categorySearchController =
      TextEditingController();
  final TextEditingController _subCategorySearchController =
      TextEditingController();
  List<Combo> combos = [];
  int? selectedComboId;
  final ComboRepository comboRepository = ComboRepository(ComboDao());

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
    _tradeofferapplier = widget.doOfflineId.tradeOfferApplied;
    fetchItems();
    fetchCategories();
    fetchItemFormDetails();
    fetchCombos();
  }

  @override
  void dispose() {
    _categorySearchController.dispose();
    _subCategorySearchController.dispose();
    super.dispose();
  }

  // Add this method to fetch combos
  Future<void> fetchCombos() async {
    try {
      final fetchedCombos = await comboRepository.getAllRoutes();
      setState(() {
        combos = fetchedCombos;
        if (selectedComboId == null && fetchedCombos.isNotEmpty) {
          selectedComboId = fetchedCombos.first.id;
        }
      });
      print('Fetched Combos: $combos');
    } catch (e) {
      print('Error fetching combos: $e');
    }
  }

  // Add this method to handle combo selection
  void _handleComboSelection(int comboId) {
    setState(() {
      selectedComboId = comboId;
    });

    setState(() {
      _tradeofferapplier = '0';
    });
    // Store the selected combo data
    storeSelectedComboData(comboId);
    print('Selected Combo ID: $comboId');
  }

  // Add this method to store selected combo data
  Future<void> storeSelectedComboData(int comboId) async {
    try {
      // Get the combo by ID
      final combo = await comboRepository.getRouteById(comboId);
      if (combo != null) {
        // Here you can store the combo data in your database or use it as needed
        // For example, you might want to update the DoMaster record with the selected combo
        final db = await DatabaseHelper.instance.database;
        await db.update(
          'do_master',
          {'selected_combo_id': comboId.toString()},
          where: 'do_offline_id = ?',
          whereArgs: [widget.doOfflineId.doOfflineId],
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Selected combo: ${combo.name}')),
        );
      }
    } catch (e) {
      print('Error storing selected combo data: $e');
    }
  }

  Future<void> _captureStartLocation() async {
    try {
      // Check for location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          // Handle permission denied
          return;
        }
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      // Update the DoMaster record with start location
      final db = await DatabaseHelper.instance.database;
      await db.update(
        'do_master',
        {
          'start_latitude': position.latitude.toString(),
          'start_longitude': position.longitude.toString(),
        },
        where: 'do_offline_id = ?',
        whereArgs: [widget.doOfflineId.doOfflineId],
      );
    } catch (e) {
      print('Error capturing location: $e');
    }
  }

  Future<void> _captureEndLocation() async {
    try {
      // Get current position
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      // Update the DoMaster with end location
      final db = await DatabaseHelper.instance.database;
      await db.update(
        'do_master',
        {
          'end_latitude': position.latitude.toString(),
          'end_longitude': position.longitude.toString(),
        },
        where: 'do_offline_id = ?',
        whereArgs: [widget.doOfflineId.doOfflineId],
      );
    } catch (e) {
      print('Error capturing end location: $e');
    }
  }

// Method to calculate the total from all items
  void recalculateTotal() {
    totalAmount = 0.0;

    // Calculate from filteredItemDetailsList
    for (var item in filteredItemDetailsList) {
      if (item.amt.isNotEmpty && double.tryParse(item.amt) != null) {
        totalAmount += double.parse(item.amt);
      }
    }

    // Calculate from allItemDetails
    for (var item in allItemDetails) {
      if (item.amt.isNotEmpty && double.tryParse(item.amt) != null) {
        totalAmount += double.parse(item.amt);
      }
    }

    setState(() {});
  }

  /// Process trade commission rules for a delivery order
  Future<void> processTradeCommission(String doMasterId) async {
    final db = await DatabaseHelper.instance.database;

    try {
      // Get current year and month
      final now = DateTime.now();
      final currentYear = now.year.toString();
      final currentMonth = now.month.toString();
      await db.rawUpdate(
        "UPDATE item_details "
        "SET "
        "    nsp_per = CASE "
        "                 WHEN (SELECT i.nsp_per FROM item i WHERE i.item_id = item_details.item_id) = 0 THEN "
        "                     (SELECT i.nsp_per FROM item i WHERE i.item_id = item_details.item_id) "
        "                 ELSE "
        "                     item_details.nsp_org "
        "               END, "
        "    t_price = CASE "
        "                 WHEN (SELECT i.nsp_per FROM item i WHERE i.item_id = item_details.item_id) = 0 THEN "
        "                     (SELECT i.t_price FROM item i WHERE i.item_id = item_details.item_id) "
        "                 ELSE "
        "                     item_details.t_price "
        "               END, "
        "    amt = CASE "
        "             WHEN (SELECT i.nsp_per FROM item i WHERE i.item_id = item_details.item_id) = 0 THEN "
        "                 CAST(qty AS REAL) * ( "
        "                     (SELECT CAST(i.t_price AS REAL) FROM item i WHERE i.item_id = item_details.item_id) "
        "                     - ( "
        "                         (SELECT CAST(i.t_price AS REAL) FROM item i WHERE i.item_id = item_details.item_id) "
        "                         * ( "
        "                             (SELECT CAST(i.nsp_per AS REAL) FROM item i WHERE i.item_id = item_details.item_id) / 100 "
        "                           ) "
        "                     ) "
        "                 ) "
        "             ELSE "
        "                 CAST(item_details.t_price AS REAL) "
        "                 * (1 - (CAST(item_details.nsp_org AS REAL) / 100)) "
        "                 * CAST(item_details.qty AS REAL)"
        "           END "
        "WHERE do_master_id = ?;",
        [doMasterId],
      );

      await db.rawDelete(
          "DELETE FROM item_details WHERE do_master_id = ? AND gift_id = '1'",
          [doMasterId]);
      await db.rawDelete(
          "DELETE FROM item_details WHERE do_master_id = ? AND gift_id = '2'",
          [doMasterId]);

      // Fetch all trade commission rules
      String commissionQuery =
          "SELECT item_list, min_qty, max_qty, trade_com_per FROM trade_offer_comission WHERE combo_id = '$selectedComboId'";

      final List<Map<String, dynamic>> commissionRules = await db.rawQuery(
          "SELECT item_list, min_qty, max_qty, trade_com_per FROM trade_offer_comission WHERE combo_id = ?",
          [selectedComboId]);

      // Pretty print the query data
      // print("\n");
      // for (var rule in commissionRules) {
      //   print("Item List: ${rule['item_list']}");
      //   print("Min Quantity: ${rule['min_qty']}");
      //   print("Max Quantity: ${rule['max_qty']}");
      //   print("Trade Commission Percentage: ${rule['trade_com_per']}");
      //   print("-----------------------------");
      //   print("\n\n\n");
      // }

      // Process each commission rule
      for (var rule in commissionRules) {
        // Convert item_list CSV into an array
        List<String> itemList = rule['item_list'].toString().split(',');

        // Ensure correct types
        int minQty = int.tryParse(rule['min_qty'].toString()) ?? 0;
        int maxQty = int.tryParse(rule['max_qty'].toString()) ?? 0;
        double tradeComPer =
            double.tryParse(rule['trade_com_per'].toString()) ?? 0.0;

        // Sanitize and format item list for SQL
        List<String> itemListEscaped = [];
        for (var item in itemList) {
          String trimmedItem = item.trim();
          if (trimmedItem.isNotEmpty) {
            itemListEscaped.add("'$trimmedItem'");
          }
        }

        if (itemListEscaped.isEmpty) {
          continue; // Skip processing if no valid items
        }

        String itemListStr = itemListEscaped.join(','); // Convert to SQL string

        // Get total quantity sold for these items in this do_master_id
        String totalSoldQuery =
            "SELECT SUM(qty) AS total_sold FROM item_details " +
                "WHERE do_master_id = '$doMasterId' " +
                "AND item_id IN ($itemListStr)";
        print('Executing total sold query: $totalSoldQuery');

        final List<Map<String, dynamic>> totalSoldResult = await db.rawQuery(
            "SELECT SUM(qty) AS total_sold FROM item_details " +
                "WHERE do_master_id = ? " +
                "AND item_id IN ($itemListStr)",
            [doMasterId]);

        // Get the total quantity sold
        int totalSold = 0;
        if (totalSoldResult.isNotEmpty &&
            totalSoldResult[0]['total_sold'] != null) {
          totalSold =
              int.tryParse(totalSoldResult[0]['total_sold'].toString()) ?? 0;
        }

        print('Total sold for items $itemListStr: $totalSold');

        // Apply trade_com_per if total_sold is within the defined range
        if (totalSold >= minQty && totalSold <= maxQty && totalSold != 0) {
          print(
              'Applying commission rate $tradeComPer% to items in range $minQty-$maxQty');

          // Update nsp_per for these items in item_details
          String updateQuery = "UPDATE item_details " +
              "SET nsp_per = '$tradeComPer' " +
              "WHERE do_master_id = '$doMasterId' " +
              "AND item_id IN ($itemListStr)";
          print('Executing update query: $updateQuery');

          await db.rawUpdate(
            "UPDATE item_details "
            "SET nsp_per = ? "
            "WHERE do_master_id = ? "
            "AND item_id IN ($itemListStr)",
            [tradeComPer.toString(), doMasterId],
          );

          // Update all rate and amt
          String updateAmtQuery = "UPDATE item_details " +
              "SET" +
              "amt = CAST(qty AS REAL) * (CAST(t_price AS REAL) - (CAST(t_price AS REAL) * (CAST(nsp_per AS REAL)/100))) " +
              "WHERE do_master_id = '$doMasterId'";
          print('Executing update amount query: $updateAmtQuery');

          await db.rawUpdate(
              "UPDATE item_details " +
                  "SET  " +
                  "amt = CAST(qty AS REAL) * (CAST(t_price AS REAL) - (CAST(t_price AS REAL) * (CAST(nsp_per AS REAL)/100))) " +
                  "WHERE do_master_id = ?",
              [doMasterId]);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Updated prices and amounts successfully')),
          );
          await fetchItemFormDetails();
          recalculateTotal();
        }
      }
    } catch (e) {
      print('Error processing trade commission: $e');
      await fetchItemFormDetails();
    }
    await fetchItemFormDetails();
    processGiftOffer(doMasterId);
  }

// ... existing code ...

  Future<void> processGiftOffer(String doMasterId) async {
    final db = await DatabaseHelper.instance.database;
    try {
      // Get current year and month
      final now = DateTime.now();
      final currentYear = now.year.toString();
      final currentMonth = now.month.toString();

      print(currentYear + "ggggggggggggggggg" + currentMonth);

      // Get the active item list from trade_offer table (equivalent to ss_gift_offer_invoice)
      final List<Map<String, dynamic>> itemListResult = await db.rawQuery(
          "SELECT item_list FROM trade_offer WHERE combo_id=? LIMIT 1",
          [selectedComboId]);

      if (itemListResult.isEmpty || itemListResult[0]['item_list'] == null) {
        print('No active trade offers found for the current period');
        setState(() {
          _tradeofferapplier = '1';
        });
        await processGiftOfferPercentage(doMasterId);
        recalculateTotal();
        return; // No items to check, skip processing
      }

      final String itemList = itemListResult[0]['item_list'];

      String totalQuery =
          "SELECT SUM(amt) AS total_order_amt FROM item_details WHERE do_master_id = '$doMasterId' AND item_id IN ($itemList)";
      print('Executing query: $totalQuery');

      // Get total amount of the whole order for this do_master_id with items in the offer list
      final List<Map<String, dynamic>> totalResult = await db.rawQuery(
          "SELECT SUM(amt) AS total_order_amt FROM item_details WHERE do_master_id = ? AND item_id IN ($itemList)",
          [doMasterId]);

      final double totalOrderAmt =
          totalResult.isNotEmpty && totalResult[0]['total_order_amt'] != null
              ? double.parse(totalResult[0]['total_order_amt'].toString())
              : 0.0;

      print('Total order amount: $totalOrderAmt');

      // Fetch gift rule that matches the total amount - taking the highest tier that matches
      final List<Map<String, dynamic>> offerResult = await db.rawQuery('''
  SELECT item_list, min_taka, max_taka, gift_item_id, gift_item_name, git_qty 
  FROM trade_offer 
  WHERE  ? BETWEEN CAST(min_taka AS REAL) AND CAST(max_taka AS REAL)
    AND status = 'Active' 
    AND combo_id = ?

  ORDER BY CAST(min_taka AS REAL) DESC 
  LIMIT 1
  ''', [totalOrderAmt, selectedComboId]);

      // Delete previous gift item if exists

      if (offerResult.isNotEmpty) {
        final offerData = offerResult[0];
        final String giftItemId = offerData['gift_item_id']?.toString() ?? '';
        final String giftQty = offerData['git_qty']?.toString() ?? '1';
        final String finishedgood = 'free';
        final String gift_item_name =
            offerData['gift_item_name']?.toString() ?? '1';

        if (giftItemId.isNotEmpty && int.parse(giftItemId) > 0) {
          // Insert the matched gift item
          await db.rawInsert(
              "INSERT INTO item_details ( do_master_id, item_id, finish_goods_code, item_name, unit_name, t_price, pack_size, nsp_per, category_id, subcategory_id, offer, qty, amt, gift_id ) VALUES (?, ?, ?, ?, '0.0', '0.0', '0.0', '0.0', '0.0', '0.0', '0.0', ?, '0.0', '1')",
              [doMasterId, giftItemId, finishedgood, gift_item_name, giftQty]);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gift item added successfully')),
          );
          await fetchItemFormDetails();
          recalculateTotal();
          DoMaster? updatedDoMaster = await doMasterDao
              .getDoMasterById(widget.doOfflineId.doOfflineId!);
          if (updatedDoMaster != null) {
            updatedDoMaster.tradeOfferApplied = '1';
            await doMasterDao.updateDoMaster(updatedDoMaster);
          }
        }
      } else {
        print('No matching gift offer found for amount: $totalOrderAmt');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'No matching gift offer found for amount: $totalOrderAmt')),
        );
      }
    } catch (e) {
      print('Error processing gift offer: $e');
    }
    setState(() {
      _tradeofferapplier = '1';
    });

    // Call processItemGiftOffer after processing regular gift offers
    await processGiftOfferPercentage(doMasterId);
  }

  Future<void> processGiftOfferPercentage(String doMasterId) async {
    final db = await DatabaseHelper.instance.database;
    try {
      // Get current year and month
      final now = DateTime.now();
      final currentYear = now.year.toString();
      final currentMonth = now.month.toString();

      print(currentYear + "ggggggggggggggggg" + currentMonth);

      // Get the active item list from trade_offer_percentage table (equivalent to ss_gift_offer_invoice)
      final List<Map<String, dynamic>> itemListResult = await db.rawQuery(
          "SELECT item_list FROM trade_offer_percentage WHERE combo_id=? LIMIT 1",
          [selectedComboId]);

      if (itemListResult.isEmpty || itemListResult[0]['item_list'] == null) {
        print('No active trade offers found for the current period');
        setState(() {
          _tradeofferapplier = '1';
        });
        await processGiftOfferPercentageExtra(doMasterId);
        recalculateTotal();
        return; // No items to check, skip processing
      }

      final String itemList = itemListResult[0]['item_list'];

      String totalQuery =
          "SELECT SUM(amt) AS total_order_amt FROM item_details WHERE do_master_id = '$doMasterId' AND item_id IN ($itemList)";
      print('Executing query: $totalQuery');

      // Get total amount of the whole order for this do_master_id with items in the offer list
      final List<Map<String, dynamic>> totalResult = await db.rawQuery(
          "SELECT SUM(amt) AS total_order_amt FROM item_details WHERE do_master_id = ? AND item_id IN ($itemList)",
          [doMasterId]);

      final double totalOrderAmt =
          totalResult.isNotEmpty && totalResult[0]['total_order_amt'] != null
              ? double.parse(totalResult[0]['total_order_amt'].toString())
              : 0.0;

      print('Total order amount: $totalOrderAmt');

      // Fetch gift rule that matches the total amount - taking the highest tier that matches
      final List<Map<String, dynamic>> offerResult = await db.rawQuery('''
  SELECT item_list, min_taka, max_taka, percentage 
  FROM trade_offer_percentage 
  WHERE  ? BETWEEN CAST(min_taka AS REAL) AND CAST(max_taka AS REAL)
    AND status = 'Active' 
    AND combo_id = ?

  ORDER BY CAST(min_taka AS REAL) DESC 
  LIMIT 1
  ''', [totalOrderAmt, selectedComboId]);

      // Delete previous gift item if exists

      if (offerResult.isNotEmpty) {
        final offerData = offerResult[0];
        //final String giftItemId = offerData['gift_item_id']?.toString() ?? '';
        final String tradeComPer = offerData['percentage']?.toString() ?? '0.0';

        if (tradeComPer.isNotEmpty && double.parse(tradeComPer) > 0) {
          // Insert the matched gift item
          await db.rawUpdate(
            "UPDATE item_details "
            "SET nsp_per = ? "
            "WHERE do_master_id = ? "
            "AND item_id IN ($itemList)",
            [tradeComPer.toString(), doMasterId],
          );

          // Update all rate and amt
          String updateAmtQuery = "UPDATE item_details " +
              "SET" +
              "amt = CAST(qty AS REAL) * (CAST(t_price AS REAL) - (CAST(t_price AS REAL) * (CAST(nsp_per AS REAL)/100))) " +
              "WHERE do_master_id = '$doMasterId'";
          print('Executing update amount query: $updateAmtQuery');

          await db.rawUpdate(
              "UPDATE item_details " +
                  "SET  " +
                  "amt = CAST(qty AS REAL) * (CAST(t_price AS REAL) - (CAST(t_price AS REAL) * (CAST(nsp_per AS REAL)/100))) " +
                  "WHERE do_master_id = ?",
              [doMasterId]);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gift item added successfully')),
          );
          await fetchItemFormDetails();
          recalculateTotal();
          DoMaster? updatedDoMaster = await doMasterDao
              .getDoMasterById(widget.doOfflineId.doOfflineId!);
          if (updatedDoMaster != null) {
            updatedDoMaster.tradeOfferApplied = '1';
            await doMasterDao.updateDoMaster(updatedDoMaster);
          }
        }
      } else {
        print('No matching gift offer found for amount: $totalOrderAmt');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'No matching gift offer found for amount: $totalOrderAmt')),
        );
      }
    } catch (e) {
      print('Error processing gift offer: $e');
    }
    setState(() {
      _tradeofferapplier = '1';
    });

    // Call processItemGiftOffer after processing regular gift offers
    await processGiftOfferPercentageExtra(doMasterId);
  }

  Future<void> processGiftOfferPercentageExtra(String doMasterId) async {
    final db = await DatabaseHelper.instance.database;
    try {
      // Get current year and month
      final now = DateTime.now();
      final currentYear = now.year.toString();
      final currentMonth = now.month.toString();

      print(currentYear + "ggggggggggggggggg" + currentMonth);

      // Fetch all active percentage rules for the selected combo
      final int comboId = selectedComboId ?? 0;
      final List<Map<String, dynamic>> rules = await db.rawQuery(
        "SELECT item_list, min_taka, max_taka, percentage "
        "FROM trade_offer_percentage_extra "
        "WHERE combo_id = ? AND status = 'Active'",
        [comboId],
      );

      if (rules.isEmpty) {
        print('No active trade offers found for the current period');
        setState(() {
          _tradeofferapplier = '1';
        });
        await processItemGiftOffer(doMasterId);
        recalculateTotal();
        return; // No items to check, skip processing
      }

      // Process each percentage rule
      for (var rule in rules) {
        final String itemListRaw = rule['item_list']?.toString() ?? '';
        if (itemListRaw.trim().isEmpty) {
          continue;
        }

        // Build IN clause safely (similar to min_qty/max_qty logic)
        final List<String> itemIds = itemListRaw.split(',');
        final List<String> itemListEscaped = [];
        for (var id in itemIds) {
          final trimmed = id.trim();
          if (trimmed.isNotEmpty) {
            itemListEscaped.add("'" + trimmed + "'");
          }
        }
        if (itemListEscaped.isEmpty) {
          continue;
        }
        final String itemListStr = itemListEscaped.join(',');

        // Compute total amount for this rule’s item_list
        final List<Map<String, dynamic>> totalResult = await db.rawQuery(
          "SELECT SUM(amt) AS total_order_amt "
                  "FROM item_details "
                  "WHERE do_master_id = ? AND item_id IN (" +
              itemListStr +
              ")",
          [doMasterId],
        );

        final double totalOrderAmt = totalResult.isNotEmpty &&
                totalResult[0]['total_order_amt'] != null
            ? double.tryParse(totalResult[0]['total_order_amt'].toString()) ??
                0.0
            : 0.0;

        final double minTaka =
            double.tryParse(rule['min_taka'].toString()) ?? 0.0;
        final double maxTaka =
            double.tryParse(rule['max_taka'].toString()) ?? 0.0;
        final double percentage =
            double.tryParse(rule['percentage'].toString()) ?? 0.0;

        print('Rule item_list: ' +
            itemListStr +
            ', total: ' +
            totalOrderAmt.toString() +
            ', range: [' +
            minTaka.toString() +
            ' - ' +
            maxTaka.toString() +
            '], percentage: ' +
            percentage.toString());

        // Apply percentage if within range
        if (totalOrderAmt >= minTaka &&
            totalOrderAmt <= maxTaka &&
            percentage > 0) {
          await db.rawUpdate(
            "UPDATE item_details "
                    "SET nsp_per = CAST(nsp_per AS REAL) + ? - (CAST(nsp_per AS REAL) * ? / 100) "
                    "WHERE do_master_id = ? "
                    "AND item_id IN (" +
                itemListStr +
                ")",
            [percentage.toString(), percentage.toString(), doMasterId],
          );
        }
      }

      // Update all rate and amt after applying percentage rules
      await db.rawUpdate(
          "UPDATE item_details "
          "SET  "
          "amt = CAST(qty AS REAL) * (CAST(t_price AS REAL) - (CAST(t_price AS REAL) * (CAST(nsp_per AS REAL)/100))) "
          "WHERE do_master_id = ?",
          [doMasterId]);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gift percentage offers applied successfully')),
      );
      await fetchItemFormDetails();
      recalculateTotal();
      DoMaster? updatedDoMaster =
          await doMasterDao.getDoMasterById(widget.doOfflineId.doOfflineId!);
      if (updatedDoMaster != null) {
        updatedDoMaster.tradeOfferApplied = '1';
        await doMasterDao.updateDoMaster(updatedDoMaster);
      }
    } catch (e) {
      print('Error processing gift offer: ' + e.toString());
    }
    setState(() {
      _tradeofferapplier = '1';
    });

    // Call processItemGiftOffer after processing regular gift offers
    await processItemGiftOffer(doMasterId);
  }

  Future<void> processItemGiftOffer(String doMasterId) async {
    print("Fahimmmmmmmmmmmmmmmmmmm");
    final db = await DatabaseHelper.instance.database;
    final itemDao = ItemDao();
    try {
      // Get current year and month
      final now = DateTime.now();
      final currentYear = now.year.toString();
      final currentMonth = now.month.toString();

      print(currentYear + "Processing item gift offer for " + currentMonth);
      // Construct the query with parameters
      String querycc =
          " SELECT item_list FROM trade_item_offer WHERE combo_id = $selectedComboId LIMIT 1";

// Print the query to the console
      print("Executed SQL Query: $querycc");
// Construct the query with parameters

// Print the query to the console

      // Get the active item list from trade_item_offer table
      final List<Map<String, dynamic>> itemListResult = await db.rawQuery(
          "SELECT item_list FROM trade_item_offer WHERE combo_id=? LIMIT 1",
          [selectedComboId]);

      if (itemListResult.isEmpty || itemListResult[0]['item_list'] == null) {
        print('No active trade item offers found for the current period');
        await fetchItemFormDetails();
        recalculateTotal();
        return; // No items to check, skip processing
      }

      final String itemList = itemListResult[0]['item_list'];
      final String querygg =
          "SELECT SUM(CAST(qty AS INTEGER)) AS total_order_qty FROM item_details WHERE do_master_id = ? AND item_id IN ($itemList)";
      print("Executing query: $querygg with parameters: [$doMasterId]");
      // Get total quantity of items in the order for this do_master_id with items in the offer list

      final List<Map<String, dynamic>> totalResult = await db.rawQuery(
          "SELECT SUM(CAST(qty AS INTEGER)) AS total_order_qty FROM item_details WHERE do_master_id = ? AND item_id IN ($itemList)",
          [doMasterId]);

      final int totalOrderQty =
          totalResult.isNotEmpty && totalResult[0]['total_order_qty'] != null
              ? int.parse(totalResult[0]['total_order_qty'].toString())
              : 0;

      print('Total order quantity: $totalOrderQty');

      // Fetch gift rule that matches the total quantity - taking the highest tier that matches
      String query = '''
  SELECT item_list, min_qty, max_qty, gift_item_id, gift_item_name, git_qty 
  FROM trade_item_offer 
  WHERE  $totalOrderQty BETWEEN CAST(min_qty AS INTEGER) AND CAST(max_qty AS INTEGER)
    AND status = 'Active' 
    AND combo_id = $selectedComboId

  ORDER BY CAST(min_qty AS INTEGER) DESC 
  LIMIT 1
''';

// Print the query to the console
      print("Executed SQL Query: $query");
      final List<Map<String, dynamic>> offerResult = await db.rawQuery('''
  SELECT item_list, min_qty, max_qty, gift_item_id, gift_item_name, git_qty 
  FROM trade_item_offer 
  WHERE  ? BETWEEN CAST(min_qty AS INTEGER) AND CAST(max_qty AS INTEGER)
    AND status = 'Active' 
    AND combo_id = ?

  ORDER BY CAST(min_qty AS INTEGER) DESC 
  LIMIT 1
  ''', [totalOrderQty, selectedComboId]);

      // Delete previous item gift if exists (using a different gift_id to distinguish from regular gift offers)
      await db.rawDelete(
          "DELETE FROM item_details WHERE do_master_id = ? AND gift_id = '2'",
          [doMasterId]);

      if (offerResult.isNotEmpty) {
        final offerData = offerResult[0];
        final String giftItemIds = offerData['gift_item_id']?.toString() ?? '';
        final String giftQty = offerData['git_qty']?.toString() ?? '1';
        final int totalGiftQty = int.parse(giftQty);

        print('Gift item IDs: $giftItemIds');
        print('Total gift quantity allowed: $totalGiftQty');

        // Check if there are multiple gift item options
        if (giftItemIds.contains(',')) {
          List<String> giftItemIdList = giftItemIds.split(',');
          List<Item?> giftItems = [];

          // Fetch all gift items
          for (String itemId in giftItemIdList) {
            String trimmedId = itemId.trim();
            if (trimmedId.isNotEmpty) {
              Item? item = await itemDao.getItemById(trimmedId);
              if (item != null) {
                giftItems.add(item);
              }
            }
          }

          if (giftItems.isNotEmpty) {
            // Show modal dialog for gift selection
            await _showGiftSelectionDialog(giftItems, totalGiftQty, doMasterId);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('No valid gift items found')),
            );
          }
        } else {
          // Single gift item case - use the existing logic
          final String finishedgood = 'free-item';
          final String gift_item_name =
              offerData['gift_item_name']?.toString() ?? '';

          if (giftItemIds.isNotEmpty && int.parse(giftItemIds) > 0) {
            // Insert the matched gift item
            await db.rawInsert(
                "INSERT INTO item_details ( do_master_id, item_id, finish_goods_code, item_name, unit_name, t_price, pack_size, nsp_per, category_id, subcategory_id, offer, qty, amt, gift_id ) VALUES (?, ?, ?, ?, '0.0', '0.0', '0.0', '0.0', '0.0', '0.0', '0.0', ?, '0.0', '2')",
                [
                  doMasterId,
                  giftItemIds,
                  finishedgood,
                  gift_item_name,
                  giftQty
                ]);

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Item-based gift added successfully')),
            );
            await fetchItemFormDetails();
            recalculateTotal();
          }
        }
      } else {
        print('No matching item gift offer found for quantity: $totalOrderQty');
      }
    } catch (e) {
      print('Error processing item gift offer: $e');
    }
  }

  Future<void> _showGiftSelectionDialog(
      List<Item?> giftItems, int totalGiftQty, String doMasterId) async {
    // Create a map to track selected quantities for each item
    Map<String, int> selectedQuantities = {};
    // Create a map of TextEditingControllers for each item
    Map<String, TextEditingController> controllers = {};

    for (var item in giftItems) {
      if (item != null) {
        selectedQuantities[item.itemId] = 0;
        // Initialize a controller for each item
        controllers[item.itemId] = TextEditingController(text: "0");
      }
    }

    // Show dialog and wait for result
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            // Calculate total selected quantity
            int currentTotalQty =
                selectedQuantities.values.fold(0, (sum, qty) => sum + qty);
            bool isValidSelection = currentTotalQty == totalGiftQty;

            return AlertDialog(
              // Give more space to title
              title: Container(
                padding: EdgeInsets.only(bottom: 16.0),
                child: Text(
                  'Select Gift Items',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              contentPadding: EdgeInsets.fromLTRB(24.0, 8.0, 24.0, 0.0),
              content: Container(
                width: double.maxFinite,
                height: 400, // Fixed height to prevent overflow
                alignment: Alignment.centerLeft,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Instructions with more padding
                    Container(
                      padding: EdgeInsets.symmetric(vertical: 12.0),
                      child: Text(
                        'Please select gift items. Total quantity must be exactly $totalGiftQty',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                    // Status indicator
                    Container(
                      padding: EdgeInsets.only(bottom: 16.0),
                      child: Text(
                        'Current selection: $currentTotalQty / $totalGiftQty',
                        style: TextStyle(
                          color: isValidSelection ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    // Items list
                    Expanded(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: giftItems.length,
                        itemBuilder: (context, index) {
                          Item? item = giftItems[index];
                          if (item == null) return SizedBox.shrink();

                          return Container(
                            margin: EdgeInsets.only(bottom: 8.0),
                            child: Row(
                              children: [
                                // Product name section - takes more space
                                Expanded(
                                  flex: 3,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.itemName,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w500,
                                          fontSize: 14,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        'ID: ${item.itemId}',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(
                                    width:
                                        16), // Space between name and controls
                                // Quantity controls section - positioned more to the right
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Minus button
                                    Container(
                                      width: 32,
                                      height: 32,
                                      child: IconButton(
                                        padding: EdgeInsets.zero,
                                        icon: Icon(Icons.remove, size: 18),
                                        onPressed:
                                            selectedQuantities[item.itemId]! > 0
                                                ? () {
                                                    setState(() {
                                                      selectedQuantities[
                                                              item.itemId] =
                                                          selectedQuantities[
                                                                  item.itemId]! -
                                                              1;
                                                      controllers[item.itemId]!
                                                              .text =
                                                          selectedQuantities[
                                                                  item.itemId]
                                                              .toString();
                                                    });
                                                  }
                                                : null,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    // Text input - wider for better visibility
                                    Container(
                                      width: 60, // Increased width from 50
                                      height: 40,
                                      child: TextField(
                                        textAlign: TextAlign.center,
                                        keyboardType: TextInputType.number,
                                        controller: controllers[item.itemId],
                                        style: TextStyle(fontSize: 14),
                                        decoration: InputDecoration(
                                          contentPadding: EdgeInsets.symmetric(
                                              vertical: 8.0, horizontal: 4.0),
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          isDense: true,
                                        ),
                                        onChanged: (value) {
                                          setState(() {
                                            selectedQuantities[item.itemId] =
                                                int.tryParse(value) ?? 0;
                                          });
                                        },
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    // Plus button
                                    Container(
                                      width: 32,
                                      height: 32,
                                      child: IconButton(
                                        padding: EdgeInsets.zero,
                                        icon: Icon(Icons.add, size: 18),
                                        onPressed:
                                            currentTotalQty < totalGiftQty
                                                ? () {
                                                    setState(() {
                                                      selectedQuantities[
                                                              item.itemId] =
                                                          selectedQuantities[
                                                                  item.itemId]! +
                                                              1;
                                                      controllers[item.itemId]!
                                                              .text =
                                                          selectedQuantities[
                                                                  item.itemId]
                                                              .toString();
                                                    });
                                                  }
                                                : null,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: Text('Cancel'),
                  onPressed: () {
                    setState(() {
                      _tradeofferapplier = '0';
                    });
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: Text('Confirm'),
                  onPressed: isValidSelection
                      ? () async {
                          Navigator.of(context).pop(selectedQuantities);
                        }
                      : null,
                ),
              ],
            );
          },
        );
      },
    ).then((selectedQuantities) async {
      if (selectedQuantities != null) {
        // Process the selected gift items
        await _addSelectedGiftItems(selectedQuantities, giftItems, doMasterId);
      }
    });
  }

  Future<void> _addSelectedGiftItems(Map<String, int> selectedQuantities,
      List<Item?> giftItems, String doMasterId) async {
    final db = await DatabaseHelper.instance.database;
    final String finishedgood = 'free-item';

    try {
      // Start a transaction to insert all selected gift items
      await db.transaction((txn) async {
        for (var item in giftItems) {
          if (item != null) {
            int qty = selectedQuantities[item.itemId] ?? 0;
            if (qty > 0) {
              // Insert the gift item with the selected quantity
              await txn.rawInsert(
                  "INSERT INTO item_details ( do_master_id, item_id, finish_goods_code, item_name, unit_name, t_price, pack_size, nsp_per, category_id, subcategory_id, offer, qty, amt, gift_id ) VALUES (?, ?, ?, ?, '0.0', '0.0', '0.0', '0.0', '0.0', '0.0', '0.0', ?, '0.0', '2')",
                  [
                    doMasterId,
                    item.itemId,
                    finishedgood,
                    item.itemName,
                    qty.toString()
                  ]);
            }
          }
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Selected gift items added successfully')),
      );
      await fetchItemFormDetails();
      recalculateTotal();
    } catch (e) {
      print('Error adding selected gift items: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding gift items: ${e.toString()}')),
      );
    }
  }

  Future<void> applyTradeOffer() async {
    try {
      // Fetch all trade offers from the database
      final db = await DatabaseHelper.instance.database;
      final tradeOfferMaps = await db.query('trade_offer');

      // Convert maps to TradeOffer objects
      List<TradeOffer> tradeOffers =
          tradeOfferMaps.map((map) => TradeOffer.fromMap(map)).toList();

      // Calculate total order amount from all items
      double totalOrderAmount = 0.0;
      for (var item in allItemDetails) {
        if (item.amt.isNotEmpty && double.tryParse(item.amt) != null) {
          totalOrderAmount += double.parse(item.amt);
        }
      }

      // Group offers by item_list for easier lookup
      Map<String, List<TradeOffer>> groupedOffers = {};
      for (var offer in tradeOffers) {
        String offerKey = offer.offerName; // Using offer name as key
        if (!groupedOffers.containsKey(offerKey)) {
          groupedOffers[offerKey] = [];
        }
        groupedOffers[offerKey]!.add(offer);

        // Ensure offers are sorted by min_taka for reliable processing
        groupedOffers[offerKey]!.sort((a, b) =>
            double.parse(a.minTaka).compareTo(double.parse(b.minTaka)));
      }

      // Create maps to track items by offer
      Map<String, Map<String, bool>> itemCodesInOffer = {};
      Map<String, List<ItemDetails>> itemsByOffer = {};

      // Preprocess item lists for each offer
      for (var offerName in groupedOffers.keys) {
        itemCodesInOffer[offerName] = {};

        // Combine all item codes from all offers with this name
        for (var offer in groupedOffers[offerName]!) {
          List<String> itemCodes = offer.itemList.split(',');
          for (var code in itemCodes) {
            String cleanCode = code.trim();
            if (cleanCode.isNotEmpty) {
              itemCodesInOffer[offerName]![cleanCode] = true;
            }
          }
        }
      }

      // Categorize items by offer
      for (var item in allItemDetails) {
        // Find which offer this item belongs to
        for (var offerName in itemCodesInOffer.keys) {
          if (itemCodesInOffer[offerName]!.containsKey(item.itemId)) {
            // Add item to the offer group
            if (!itemsByOffer.containsKey(offerName)) {
              itemsByOffer[offerName] = [];
            }
            itemsByOffer[offerName]!.add(item);
            break;
          }
        }
      }

      // Track if any gifts were applied
      bool anyGiftApplied = false;
      List<Map<String, String>> appliedGifts = [];

      // Now apply offers based on total order amount
      for (var offerName in groupedOffers.keys) {
        // Find the applicable offer based on amount range
        TradeOffer? applicableOffer;
        for (var offer in groupedOffers[offerName]!) {
          try {
            double minTaka = double.parse(offer.minTaka);
            double maxTaka = double.parse(offer.maxTaka);

            if (totalOrderAmount >= minTaka && totalOrderAmount <= maxTaka) {
              applicableOffer = offer;
              break;
            }
          } catch (e) {
            print('Error parsing min/max taka in offer: ${e.toString()}');
          }
        }

        // Apply the gift if an applicable offer was found
        if (applicableOffer != null) {
          try {
            // Add gift information to the list
            appliedGifts.add({
              'offerName': applicableOffer.offerName,
              'giftItemName': applicableOffer.giftItemName,
              'giftQty': applicableOffer.gitQty,
              'minTaka': applicableOffer.minTaka,
              'maxTaka': applicableOffer.maxTaka,
            });

            anyGiftApplied = true;
            ItemDetails giftItem = ItemDetails(
                itemId: applicableOffer.giftItemId,
                itemName: applicableOffer.giftItemName,
                qty: applicableOffer.gitQty,
                nspPer: '0.00',
                tPrice: '0.00',
                nspOrg: '0.00',
                originalNspPer: '0.00',
                amt: '0.00',
                doMasterId: widget.doOfflineId.doOfflineId.toString(),
                doDetailsId: widget.doOfflineId.doOfflineId,
                finishGoodsCode: applicableOffer.giftItemId,
                unitName: 'pc',
                packSize: '1',
                categoryId: applicableOffer.giftItemName,
                subcategoryId: applicableOffer.giftItemName,
                giftId: '1');

            final db = await DatabaseHelper.instance.database;
            await db.delete(
              'item_details',
              where: 'do_master_id = ? AND gift_id = ?',
              whereArgs: [widget.doOfflineId.doOfflineId.toString(), '1'],
            );
            await itemDetailsDao.insertOrUpdateItemDetails(giftItem);

            await fetchItemFormDetails();
            recalculateTotal();

            DoMaster? updatedDoMaster = await doMasterDao
                .getDoMasterById(widget.doOfflineId.doOfflineId!);
            if (updatedDoMaster != null) {
              updatedDoMaster.tradeOfferApplied = '1';
              await doMasterDao.updateDoMaster(updatedDoMaster);
            }

            print(
                'Applied gift offer "${applicableOffer.offerName}" - ${applicableOffer.giftItemName} (${applicableOffer.gitQty} pcs)');
          } catch (e) {
            print(
                'Error applying gift for offer ${offerName}: ${e.toString()}');
          }
        } else {
          print(
              'No applicable offer found for ${offerName} with amount $totalOrderAmount');
        }
      }

      // Show appropriate message to the user
      if (anyGiftApplied) {
        // Build a message with all applied gifts
        String giftMessage = 'Trade offers applied:\n';
        for (var gift in appliedGifts) {
          giftMessage +=
              '• ${gift['offerName']}: ${gift['giftItemName']} (${gift['giftQty']} pcs)\n';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(giftMessage),
            duration: Duration(seconds: 5),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('No applicable trade offers found for this order amount.'),
          ),
        );
      }
    } catch (e) {
      print('Error in applyTradeOffer: ${e.toString()}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error applying trade offers: ${e.toString()}')),
      );
    }
    setState(() {
      _tradeofferapplier = '1';
    });
  }

  Future<void> fetchItems() async {
    print('masterrrrrrrrrrrrrrrrrrr ${widget.doOfflineId.doOfflineId}');
    List<Item> fetchedItems = await itemRepository.getItems();
    setState(() {
      allItems = fetchedItems;
      // filteredItemDetailsList = fetchedItems.map((item) => ItemDetails.fromItem(item,widget.doOfflineId.toString())).toList();
      print('item count ${allItems.length}');
    });
  }

  Future<void> fetchItemFormDetails() async {
    List<ItemDetails> fetchedItems = await itemDetailsDao
        .getItemDetailsByMasterId(widget.doOfflineId.doOfflineId.toString());
    for (var item in filteredItemDetailsList) {
      // print(
      //     'Item: ${item.itemName}, Code: ${item.finishGoodsCode}, Unit: ${item
      //         .unitName}, Price: ${item.tPrice}, NSP: ${item
      //         .nspPer}, Offer: ${item.offer}, Qty: ${item.qty}, Amt: ${item
      //         .amt}');
    }
    setState(() {
      allItemDetails = fetchedItems;
      // filteredItemDetailsList = fetchedItems.map((item) => ItemDetails.fromItem(item,widget.doOfflineId.toString())).toList();
      print('item xxxxxxxxxxxxx count ${allItemDetails.length}');
      recalculateTotal();
    });
  }

  // Function to print filtered items
  void printFilteredItems() async {
    setState(() {
      _tradeofferapplier = '0';
    });
    for (var item in filteredItemDetailsList) {
      if (item.qty != '') {
        int insertedItem = await itemDetailsDao.insertOrUpdateItemDetails(item);
        // print(
        //     'Item: ${item.itemName}, Code: ${item.finishGoodsCode}, Unit: ${item
        //         .unitName}, Price: ${item.tPrice}, NSP: ${item
        //         .nspPer}, Offer: ${item.offer}, Qty: ${item.qty}, Amt: ${item
        //         .amt}');
      }
    }
    setState(() {
      filteredItemDetailsList = [];
      fetchItemFormDetails();
    });
  }

  Future<void> deleteFromItemDetails(ItemDetails item) async {
    setState(() {
      _tradeofferapplier = '0';
    });
    // Delete the item
    int insertedItem = await itemDetailsDao.deleteItemDetailsByMasterId(item);
    int insertedItem1 =
        await itemDetailsDao.deleteItemDetailsGiftByMasterId(item);
    int insertedItem2 =
        await itemDetailsDao.deleteItemDetailsGiftItemByMasterId(item);
    print('gggggggggggggggggggg');

    setState(() {
      filteredItemDetailsList = [];
    });

    // Wait for the fetch to complete before recalculating
    await fetchItemFormDetails();

    // Now recalculate after the data is loaded
    setState(() {
      recalculateTotal();
    });
  }

  Future<void> fetchCategories() async {
    List<Category> fetchedCategories = await categoryRepository.getCategories();
    setState(() {
      categories = fetchedCategories;
    });
  }

  Future<void> fetchSubCategories(String categoryId) async {
    List<SubCategory> fetchedSubCategories =
        await subCategoryRepository.getSubCategories();
    setState(() {
      subCategories = fetchedSubCategories
          .where((sub) => sub.categoryId == categoryId)
          .toList();
      selectedSubCategory = null;
      // Reset items to show all when subcategory is reset
      filteredItemDetailsList = allItems
          .map((item) => ItemDetails.fromItem(
              item, widget.doOfflineId.doOfflineId.toString()))
          .toList();
    });
  }

  Future<void> updateDoMasterStatus() async {
    int updatedItem = 0;
    await _captureEndLocation();
    DoMaster? updatedDoMaster =
        await doMasterDao.getDoMasterById(widget.doOfflineId.doOfflineId!);
    if (updatedDoMaster != null) {
      updatedDoMaster.status = 'CHECKED';
      updatedDoMaster.comboId = selectedComboId.toString();
      updatedItem = await doMasterDao.updateDoMaster(updatedDoMaster);
    }
    // Update the status of the DoMaster item
    // widget.doOfflineId.status = 'CHECKED';

    // Perform the update operation
    // int updatedItem = await doMasterDao.updateDoMaster(widget.doOfflineId);

    // Check if the update was successful (assuming a successful update returns 1)
    if (updatedItem > 0) {
      // If successful, navigate to the SelectShopPage
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/navigation',
        ModalRoute.withName(
            '/homepage'), // Keeps /homepage and removes all routes above it
      );
    } else {
      // If the update wasn't successful, you might want to show an error or do something else
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Update failed, please try again.')),
      );
    }
  }

  // Filter items based on selected subcategory
  void filterItemsBySubcategory(String subcategoryId) {
    print('fahimmmvv $subcategoryId');
    setState(() {
      filteredItemDetailsList = allItems
          .where((item) => item.subcategoryId == subcategoryId)
          .map((item) => ItemDetails.fromItem(
              item, widget.doOfflineId.doOfflineId.toString()))
          .toList();
    });
  }

  void _showCategoryDialog() {
    _categorySearchController.clear();
    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Search bar for categories
                  TextField(
                    controller: _categorySearchController,
                    decoration: InputDecoration(
                      hintText: 'Search categories',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 16),
                    ),
                    onChanged: (value) {
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        final category = categories[index];
                        // Filter categories based on search text
                        if (_categorySearchController.text.isNotEmpty &&
                            !category.categoryName.toLowerCase().contains(
                                _categorySearchController.text.toLowerCase())) {
                          return const SizedBox.shrink();
                        }
                        return ListTile(
                          title: Text(category.categoryName),
                          onTap: () {
                            this.setState(() {
                              selectedCategory = category.id;
                              fetchSubCategories(selectedCategory!);
                            });
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showSubCategoryDialog() {
    _subCategorySearchController.clear();
    if (selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category first')),
      );
      return;
    }

    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Search bar for subcategories
                  TextField(
                    controller: _subCategorySearchController,
                    decoration: InputDecoration(
                      hintText: 'Search subcategories',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 16),
                    ),
                    onChanged: (value) {
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: subCategories.isEmpty
                        ? const Center(
                            child: Text('No subcategories available'))
                        : ListView.builder(
                            itemCount: subCategories.length,
                            itemBuilder: (context, index) {
                              final subCategory = subCategories[index];
                              // Filter subcategories based on search text
                              if (_subCategorySearchController
                                      .text.isNotEmpty &&
                                  !subCategory.subcategoryName
                                      .toLowerCase()
                                      .contains(_subCategorySearchController
                                          .text
                                          .toLowerCase())) {
                                return const SizedBox.shrink();
                              }
                              return ListTile(
                                title: Text(subCategory.subcategoryName),
                                onTap: () {
                                  this.setState(() {
                                    selectedSubCategory = subCategory.id;
                                    // Filter items based on selected subcategory
                                    filterItemsBySubcategory(
                                        selectedSubCategory!);
                                  });
                                  Navigator.pop(context);
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
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
        backgroundColor: const Color(0xFF0069b5),
        title: const Text('Add Items'),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {},
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                totalAmount.toStringAsFixed(2),
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Column(
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
                        Text(
                          '${widget.shopId.shopName}(${widget.shopId.dealerCode})',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                // Filter Row
                widget.doOfflineId.status != 'CHECKED'
                    ? Padding(
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
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          selectedCategory != null
                                              ? categories
                                                  .firstWhere((cat) =>
                                                      cat.id ==
                                                      selectedCategory)
                                                  .categoryName
                                              : 'Category',
                                          style: const TextStyle(fontSize: 16),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const Icon(Icons.search,
                                          color: Colors.blue),
                                    ],
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
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          selectedSubCategory != null
                                              ? subCategories
                                                  .firstWhere((sub) =>
                                                      sub.id ==
                                                      selectedSubCategory)
                                                  .subcategoryName
                                              : 'Subcategory',
                                          style: const TextStyle(fontSize: 16),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const Icon(Icons.search,
                                          color: Colors.blue),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Container(
                                height: 48,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.blue),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<int>(
                                    value: selectedComboId,
                                    isExpanded: true,
                                    hint: const Text('Combo'),
                                    items: combos
                                        .map((combo) => DropdownMenuItem<int>(
                                              value: combo.id,
                                              child: Text(combo.name),
                                            ))
                                        .toList(),
                                    onChanged: (value) {
                                      if (value != null) {
                                        _handleComboSelection(value);
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : const SizedBox(),
                // Order Info Card
                // Card(
                //   margin: const EdgeInsets.all(10),
                //   shape: RoundedRectangleBorder(
                //     borderRadius: BorderRadius.circular(10),
                //     side: const BorderSide(color: Colors.blue, width: 1),
                //   ),
                //   child: Padding(
                //     padding: const EdgeInsets.all(16.0),
                //     child: Column(
                //       crossAxisAlignment: CrossAxisAlignment.start,
                //       children: [
                //         // ... existing code ...
                //       ],
                //     ),
                //   ),
                // ),

                const SizedBox(),
                // Table Header using Flex
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Container(
                    margin: const EdgeInsets.only(top: 10),
                    color: const Color(0xFF0066B3),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 4),
                      child: Row(
                        children: columns
                            .map((column) => Expanded(
                                  flex: column['flex'],
                                  child: Text(
                                    column['name'],
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 8),
                                    textAlign: TextAlign.center,
                                  ),
                                ))
                            .toList(),
                      ),
                    ),
                  ),
                ),
                // Table Content using ListView and Grid
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: ListView.builder(
                      itemCount: filteredItemDetailsList.length +
                          (filteredItemDetailsList.isNotEmpty ? 1 : 0) +
                          allItemDetails.length +
                          1,
                      itemBuilder: (context, index) {
                        // First list items (filteredItemDetailsList)
                        if (index < filteredItemDetailsList.length) {
                          return _buildItemRow(
                              filteredItemDetailsList[index], index == 0);
                        }
                        // Add button after filteredItemDetailsList
                        else if (filteredItemDetailsList.isNotEmpty &&
                            index == filteredItemDetailsList.length) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Container(
                              width: MediaQuery.of(context).size.width / 3,
                              alignment: Alignment.center,
                              child: ElevatedButton(
                                onPressed: printFilteredItems,
                                child: const Text('Add'),
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  backgroundColor: Colors.green,
                                ),
                              ),
                            ),
                          );
                        }
                        // Second list items (allItemDetails)
                        else if (index <
                            filteredItemDetailsList.length +
                                (filteredItemDetailsList.isNotEmpty ? 1 : 0) +
                                allItemDetails.length) {
                          int secondListIndex = index -
                              filteredItemDetailsList.length -
                              (filteredItemDetailsList.isNotEmpty ? 1 : 0);
                          return _buildItemRowDetails(
                              allItemDetails[secondListIndex],
                              secondListIndex == 0 &&
                                  filteredItemDetailsList.isEmpty);
                        }
                        // Preview and Confirm buttons at the end of the list
                        // Preview and Confirm buttons at the end of the list
                        else {
                          return allItemDetails.isNotEmpty &&
                                  widget.doOfflineId.status != 'CHECKED'
                              ? Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    children: [
                                      // Show Trade Process only if combos are empty or a combo is selected
                                      ((combos.isEmpty) ||
                                              (selectedComboId != null))
                                          ? Container(
                                              width: double.infinity,
                                              height: 50,
                                              margin: const EdgeInsets.only(
                                                  bottom: 8.0),
                                              child: ElevatedButton(
                                                onPressed: () async {
                                                  await processTradeCommission(
                                                      widget.doOfflineId
                                                          .doOfflineId
                                                          .toString());
                                                },
                                                child: Text(
                                                  'Trade Process',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.blue,
                                                  foregroundColor: Colors.white,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.zero,
                                                  ),
                                                ),
                                              ),
                                            )
                                          : const SizedBox(),

                                      // Show Preview and Confirm buttons only when _tradeofferapplier is '1'
                                      _tradeofferapplier == '1'
                                          ? Row(
                                              children: [
                                                // Expanded(
                                                //   child: Container(
                                                //     height: 50,
                                                //     child: ElevatedButton(
                                                //       onPressed: () {},
                                                //       child: Text(
                                                //         'Preview',
                                                //         style: TextStyle(
                                                //           fontSize: 16,
                                                //           fontWeight:
                                                //               FontWeight.bold,
                                                //         ),
                                                //       ),
                                                //       style: ElevatedButton
                                                //           .styleFrom(
                                                //         backgroundColor:
                                                //             Colors.red,
                                                //         foregroundColor:
                                                //             Colors.white,
                                                //         shape:
                                                //             RoundedRectangleBorder(
                                                //           borderRadius:
                                                //               BorderRadius.zero,
                                                //         ),
                                                //       ),
                                                //     ),
                                                //   ),
                                                // ),
                                                Expanded(
                                                  child: Container(
                                                    height: 50,
                                                    child: ElevatedButton(
                                                      onPressed: () {
                                                        updateDoMasterStatus();
                                                      },
                                                      child: Text(
                                                        'Confirm',
                                                        style: TextStyle(
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                      style: ElevatedButton
                                                          .styleFrom(
                                                        backgroundColor:
                                                            Colors.green,
                                                        foregroundColor:
                                                            Colors.white,
                                                        shape:
                                                            RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius.zero,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            )
                                          : Container(),
                                      SizedBox(height: 8),
                                      Container(
                                        width: double.infinity,
                                        height: 50,
                                        child: ElevatedButton(
                                          onPressed: () async {
                                            final db = await DatabaseHelper
                                                .instance.database;
                                            await db.delete('item_details',
                                                where: 'do_master_id = ?',
                                                whereArgs: [
                                                  widget.doOfflineId.doOfflineId
                                                      .toString()
                                                ]);
                                            await doMasterDao.deleteDoMaster(
                                                widget
                                                    .doOfflineId.doOfflineId!);
                                            Navigator.pushAndRemoveUntil(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (context) =>
                                                      NavigationPage()),
                                              (route) => false,
                                            );
                                          },
                                          child: Text(
                                            'Delete Order',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red,
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.zero,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : const SizedBox(); // Returns an empty widget if allItemDetails is empty
                        }
                      },
                    ),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemRow(ItemDetails item, bool isFirstItem) {
    // Calculate actual price based on current nspPer value
    double calculateActualPrice() {
      return (double.parse(item.tPrice) *
          ((100 - double.parse(item.nspPer)) / 100));
    }

    // Calculate amount based on qty and actual price
    void updateAmount() {
      if (item.qty.isNotEmpty && double.tryParse(item.qty) != null) {
        double actualPrice = calculateActualPrice();
        item.amt = (double.parse(item.qty) * actualPrice).toString();
        // Recalculate the total whenever an item's amount changes
        recalculateTotal();
      } else {
        item.amt = '0';
        recalculateTotal();
      }
    }

    // Initial calculation
    double actual_price = calculateActualPrice();

    void _openEditModal() {
      final offerController =
          TextEditingController(text: item.nspPer.isEmpty ? '0' : item.nspPer);
      final qtyController =
          TextEditingController(text: item.qty.isEmpty ? '' : item.qty);
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (ctx) {
          return Padding(
            padding:
                EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: StatefulBuilder(
              builder: (context, setStateModal) {
                return SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Edit Item',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 12),
                        TextField(
                          controller: offerController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Offer %',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: qtyController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Quantity',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextButton(
                                onPressed: () {
                                  Navigator.pop(ctx);
                                },
                                child: const Text('Cancel'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  final newOffer =
                                      double.tryParse(offerController.text) ??
                                          0.0;
                                  final original =
                                      double.tryParse(item.originalNspPer) ??
                                          newOffer;
                                  final appliedOffer =
                                      newOffer > original ? original : newOffer;
                                  final newQty = qtyController.text.trim();
                                  setState(() {
                                    item.nspPer = appliedOffer.toString();
                                    item.nspOrg = appliedOffer.toString();
                                    item.qty = newQty;
                                    updateAmount();
                                  });
                                  Navigator.pop(ctx);
                                },
                                child: const Text('Add to Cart'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      );
    }

    Border border = isFirstItem
        ? Border(
            top: BorderSide(color: Colors.blue, width: 1),
            bottom: BorderSide(color: Colors.blue, width: 1),
            left: BorderSide(color: Colors.blue, width: 1),
            right: BorderSide(color: Colors.blue, width: 1),
          )
        : Border(
            bottom: BorderSide(color: Colors.blue, width: 1),
            left: BorderSide(color: Colors.blue, width: 1),
            right: BorderSide(color: Colors.blue, width: 1),
          );

    return Container(
      decoration: BoxDecoration(
        border: border,
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
                    calculateActualPrice().toStringAsFixed(2),
                    style: const TextStyle(fontSize: 8),
                    textAlign: TextAlign.center,
                  ),
                ),

                // Offer %
                Expanded(
                  flex: 1,
                  child: InkWell(
                    onTap: _openEditModal,
                    child: Container(
                      height: 35,
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.blue),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        double.tryParse(item.nspPer)?.toStringAsFixed(2) ??
                            '0.00',
                        style: const TextStyle(fontSize: 8),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),

                // Qty
                Expanded(
                  flex: 1,
                  child: InkWell(
                    onTap: _openEditModal,
                    child: Container(
                      height: 35,
                      margin: const EdgeInsets.symmetric(horizontal: 5),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.blue),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        item.qty,
                        style: const TextStyle(fontSize: 8),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),

                // Amt
                Expanded(
                  flex: 1,
                  child: Text(
                    item.amt == ''
                        ? '0.00'
                        : double.parse(item.amt).toStringAsFixed(2),
                    style: const TextStyle(fontSize: 8),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemRowDetails(ItemDetails item, bool isFirstItem) {
    double calculateActualPrice() {
      return (double.parse(item.tPrice) *
          ((100 - double.parse(item.nspPer)) / 100));
    }

    // Use only bottom border if not the last item
    // For the last item, use all borders
    Border border = isFirstItem
        ? Border(
            top: BorderSide(
                color: Colors.blue, width: 1), // No top border to avoid overlap
            bottom: BorderSide(color: Colors.blue, width: 1),
            left: BorderSide(color: Colors.blue, width: 1),
            right: BorderSide(color: Colors.blue, width: 1),
          )
        : Border(
            bottom: BorderSide(color: Colors.blue, width: 1),
            left: BorderSide(color: Colors.blue, width: 1),
            right: BorderSide(color: Colors.blue, width: 1),
          );

    return Container(
      decoration: BoxDecoration(
        border: border,
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item.finishGoodsCode,
                      style: const TextStyle(color: Colors.grey),
                    ),
                    (item.giftId != '1' && item.giftId != '2') &&
                            widget.doOfflineId.status != 'CHECKED'
                        ? IconButton(
                            icon: Icon(Icons.close, size: 16),
                            onPressed: () {
                              // Call the function when clicked
                              deleteFromItemDetails(item);
                            },
                          )
                        : const SizedBox(),
                  ],
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
                    double.parse(item.tPrice).toStringAsFixed(2),
                    style: const TextStyle(fontSize: 8),
                    textAlign: TextAlign.center,
                  ),
                ),

                // NSP
                Expanded(
                  flex: 1,
                  child: Text(
                    calculateActualPrice().toStringAsFixed(2),
                    style: const TextStyle(fontSize: 8),
                    textAlign: TextAlign.center,
                  ),
                ),

                // Offer %
                Expanded(
                  flex: 1,
                  child: Text(
                    item.nspPer,
                    style: const TextStyle(fontSize: 8),
                    textAlign: TextAlign.center,
                  ),
                ),

                // Qty
                Expanded(
                  flex: 1,
                  child: Text(
                    double.parse(item.qty).toStringAsFixed(2),
                    style: const TextStyle(fontSize: 8),
                    textAlign: TextAlign.center,
                  ),
                ),

                // Amt
                Expanded(
                  flex: 1,
                  child: Text(
                    double.parse(item.amt).toStringAsFixed(2),
                    style: const TextStyle(fontSize: 8),
                    textAlign: TextAlign.center,
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
