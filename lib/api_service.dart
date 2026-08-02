import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:salesautomation_V4/databases/combo_dao.dart';
import 'package:salesautomation_V4/databases/route_dao.dart';
import 'package:salesautomation_V4/model/Shop.dart';
import 'package:salesautomation_V4/model/category.dart';
import 'package:salesautomation_V4/model/combo.dart';
import 'package:salesautomation_V4/model/item.dart';
import 'package:salesautomation_V4/model/route.dart';
import 'package:salesautomation_V4/model/sub_category.dart';
import 'package:salesautomation_V4/model/trade_item_offer.dart';
import 'package:salesautomation_V4/model/trade_offer.dart';
import 'package:salesautomation_V4/model/trade_offer_comission.dart';
import 'package:salesautomation_V4/model/trade_offer_percentage.dart';
import 'package:salesautomation_V4/model/trade_offer_percentage_extra.dart';
import 'package:salesautomation_V4/repositories/category_repository.dart';
import 'package:salesautomation_V4/repositories/combo_repository.dart';
import 'package:salesautomation_V4/repositories/item_repository.dart';
import 'package:salesautomation_V4/repositories/route_repository.dart';
import 'package:salesautomation_V4/repositories/shop_repository.dart';
import 'package:salesautomation_V4/repositories/sub_category_repository.dart';
import 'package:salesautomation_V4/repositories/trade_item_offer_repository.dart';
import 'package:salesautomation_V4/repositories/trade_offer_comission_repository.dart';
import 'package:salesautomation_V4/repositories/trade_offer_percentage_repository.dart';
import 'package:salesautomation_V4/repositories/trade_offer_percentage_repository_extra.dart';
import 'package:salesautomation_V4/repositories/trade_offer_repository.dart';
import 'package:salesautomation_V4/utilities/base_url.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'databases/database_helper.dart';
import 'databases/user_dao.dart';
import 'model/do_master.dart';
import 'model/item_details.dart';
import 'model/user.dart';

class ApiService {
  // Class properties
  final String apiUrl = '${BaseUrl.apiUrl}api_do_data_sync.php';
  final Dio _dio = Dio();
  final UserDao _userDao = UserDao();
  Timer? _syncTimer;
  SharedPreferences? _prefs;
  static const String LAST_REFRESH_KEY = 'last_refresh_date';
  bool _isInitialized = false;

  // Singleton pattern implementation (keep only one instance declaration)
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  // Private constructor
  ApiService._internal();

  // Initialize method that can be awaited
  Future<void> initialize() async {
    if (_isInitialized) return;

    _prefs = await SharedPreferences.getInstance();
    startPeriodicSync();

    _isInitialized = true;
  }

  // Check if data needs to be refreshed today
  Future<bool> shouldRefreshToday() async {
    if (_prefs == null) {
      _prefs = await SharedPreferences.getInstance();
    }

    final String? lastRefreshDate = _prefs!.getString(LAST_REFRESH_KEY);
    final DateTime now = DateTime.now();
    final String today = "${now.year}-${now.month}-${now.day}";

    if (lastRefreshDate == null || lastRefreshDate != today) {
      return true;
    }
    return false;
  }

  // Update last refresh date
  Future<void> updateLastRefreshDate() async {
    if (_prefs == null) {
      _prefs = await SharedPreferences.getInstance();
    }

    final DateTime now = DateTime.now();
    final String today = "${now.year}-${now.month}-${now.day}";
    await _prefs!.setString(LAST_REFRESH_KEY, today);
  }

  // Function to get the user from the database
  Future<User?> getUserFromDb() async {
    final users = await _userDao.getAllUsers();
    if (users.isNotEmpty) {
      return users.first; // Assuming there's only one user
    }
    return null;
  }

  void startPeriodicSync() {
    // Cancel existing timer if any
    _syncTimer?.cancel();

    // Start new timer that runs every 5 minutes
    _syncTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      syncDataToApi((loading) {
        // Empty callback since we don't need UI updates
      });
    });
  }

  void stopPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  // Modified syncDataToApi to handle silent background sync
  Future<bool> syncDataToApi(Function(bool) setLoading,
      {bool silent = true}) async {
    if (!silent) setLoading(true);

    try {
      final user = await getUserFromDb();
      final db = await DatabaseHelper.instance.database;
      final doMasters = await db.query('do_master',
          where: "sent_status = ? AND status =?", whereArgs: ['0', 'CHECKED']);

      if (doMasters.isEmpty) {
        print('No pending records to sync');
        return true; // No records is considered a successful sync
      }
      // Get userId from the user object
      final userId = user?.username;

      bool allSynced = true;
      for (var doMaster in doMasters) {
        try {
          final doMasterId = doMaster['do_offline_id'];
          final itemDetails = await db.query('item_details',
              where: 'do_master_id = ?', whereArgs: [doMasterId]);

          final data = {
            'userId': userId,
            'doMaster': DoMaster.fromMap(doMaster).toMap(),
            'items': itemDetails
                .map((item) => ItemDetails.fromMap(item).toMap())
                .toList(),
          };

          print('Data to send: ${json.encode(data)}');

          final response = await _dio.post(
            apiUrl,
            data: json.encode(data),
            options: Options(
              headers: {"Content-Type": "application/json"},
              receiveTimeout: const Duration(milliseconds: 5000),
              sendTimeout: const Duration(milliseconds: 5000),
            ),
          );

          if (response.statusCode == 200) {
            await db.update(
              'do_master',
              {'sent_status': '1'},
              where: 'do_offline_id = ?',
              whereArgs: [doMasterId],
            );
            print('Sync successful for DoMaster ID: $doMasterId');
          } else {
            allSynced = false;
            print(
                'Sync failed for DoMaster ID: $doMasterId. Error: ${response.statusCode}');
          }
        } catch (e) {
          allSynced = false;
          print('Error syncing individual record: $e');
        }
      }

      return allSynced;
    } catch (e) {
      print('Error syncing data: $e');
      return false;
    } finally {
      if (!silent) setLoading(false);
    }
  }

  Future<bool> refreshAllData(Function(bool) setLoading) async {
    setLoading(true);
    try {
      // Get user credentials from database
      final user = await getUserFromDb();
      if (user == null) {
        print('No user found in database');
        return false;
      }

      Dio dio = Dio();
      dio.options.validateStatus = (status) => status! < 500;
      final String apiUrl = '${BaseUrl.apiUrl}api_users.php';

      final response = await dio.post(
        apiUrl,
        data: [
          {
            'user': user.username,
            'password': user.password,
          }
        ],
      );

      final data = jsonDecode(response.data);

      if (data != null && data['user'] != null) {
        // Check if any required data is empty
        if (data['routes'].isEmpty ||
            data['shopes'].isEmpty ||
            data['category'].isEmpty ||
            data['sub_category'].isEmpty ||
            data['item'].isEmpty) {
          print('Required data is missing or empty');
          return false;
        }

        // Get database instance
        final db = await DatabaseHelper.instance.database;

        // Perform all operations in a transaction
        await db.transaction((txn) async {
          try {
            // Initialize repositories
            final routeRepository = RouteRepository(RouteDao());
            final shopRepository = ShopRepository();
            final categoryRepository = CategoryRepository();
            final subCategoryRepository = SubCategoryRepository();
            final itemRepository = ItemRepository();
            final TradeOfferRepository tradeOfferRepository =
                TradeOfferRepository();
            final TradeOfferComissionRepository tradeOfferComissionRepository =
                TradeOfferComissionRepository();
            final TradeItemOfferRepository tradeItemOfferRepository =
                TradeItemOfferRepository(); // Add this line
            final TradeOfferPercentageRepository
                tradeOfferPercentageRepository =
                TradeOfferPercentageRepository();
            final TradeOfferPercentageExtraRepository
                tradeOfferPercentageExtraRepository =
                TradeOfferPercentageExtraRepository(); // Add this line

            final ComboRepository comboRepository = ComboRepository(ComboDao());

            // Delete all existing data
            await txn.delete('routes');
            await txn.delete('shops');
            await txn.delete('combos');
            await txn.delete('category');
            await txn.delete('sub_category');
            await txn.delete('trade_item_offer');
            await txn.delete('item');
            await txn.delete('trade_offer');
            await txn.delete('trade_offer_comission');
            await txn.delete('trade_offer_percentage');

            // Save Routes
            List routes = data['routes'];
            if (routes == null || routes.isEmpty) {
              throw Exception("Routes data is missing.");
            }
            for (var route in routes) {
              await routeRepository.addRoute(
                txn,
                SsRoute(
                  routeId: int.parse(route['route_id']),
                  routeName: route['route_name'],
                ),
              );
            }

            try {
              List combos = data['combo_offer'];
              if (combos == null || combos.isEmpty) {
                throw Exception("Combos data is missing.");
              }
              for (var combo in combos) {
                await comboRepository.addCombo(
                  txn,
                  Combo(
                    id: int.parse(combo['id']),
                    name: combo['combo_name'],
                    status: int.parse(combo['status']),
                  ),
                );
              }
            } catch (e) {
              rethrow;
            }
            // Save Shops
            List shopes = data['shopes'];
            if (shopes == null || shopes.isEmpty) {
              throw Exception("Shops data is missing.");
            }
            for (var shop in shopes) {
              await shopRepository.insertShop(
                txn,
                Shop(
                  dealerCode: shop['dealer_code'].toString(),
                  shopName: shop['shop_name'],
                  routeId: shop['route_id'],
                  latitude: shop['latitude'],
                  longitude: shop['longitude'],
                ),
              );
            }

            // Save Categories
            List categories = data['category'];
            if (categories == null || categories.isEmpty) {
              throw Exception("Category data is missing.");
            }

            for (var cat in categories) {
              await categoryRepository.addCategory(
                txn,
                Category(
                  id: cat['id'].toString(),
                  categoryName: cat['category_name'],
                ),
              );
            }

            // Save SubCategories
            List subCategories = data['sub_category'];
            if (subCategories == null || subCategories.isEmpty) {
              throw Exception("Subcategory data is missing.");
            }

            for (var subCat in subCategories) {
              await subCategoryRepository.addSubCategory(
                txn,
                SubCategory(
                  id: subCat['id'].toString(),
                  subcategoryName: subCat['subcategory_name'],
                  categoryId: subCat['category_id'].toString(),
                ),
              );
            }

            // Save Items
            List items = data['item'];
            if (items == null || items.isEmpty) {
              throw Exception("Item data is missing.");
            }

            for (var itm in items) {
              await itemRepository.addItem(
                txn,
                Item(
                  itemId: itm['item_id'].toString(),
                  finishGoodsCode: itm['finish_goods_code'],
                  itemName: itm['item_name'],
                  unitName: itm['unit_name'],
                  tPrice: itm['t_price'],
                  packSize: itm['pack_size'],
                  nspPer: itm['nsp_per'],
                  categoryId: itm['category_id'],
                  subcategoryId: itm['subcategory_id'],
                ),
              );
            }

            // Save Trade Offers
            if (data['trade_offer'] != null &&
                data['trade_offer'] is List &&
                data['trade_offer'].isNotEmpty) {
              List tradeOffers = data['trade_offer'];
              for (var offer in tradeOffers) {
                await tradeOfferRepository.addTradeOffer(
                  txn,
                  TradeOffer(
                    id: int.parse(offer['id']),
                    year: offer['year'],
                    mon: offer['mon'],
                    offerName: offer['offer_name'],
                    itemList: offer['item_list'],
                    comboId: int.parse(offer['combo_id']),
                    minTaka: offer['min_taka'],
                    maxTaka: offer['max_taka'],
                    giftItemId: offer['gift_item_id'],
                    gitQty: offer['git_qty'],
                    giftItemName: offer['gift_item_name'],
                    status: offer['status'] ?? 'Active',
                    entryBy: offer['entry_by'] ?? '',
                    entryAt: offer['entry_at'] ?? '',
                  ),
                );
              }
            }
            // Save Trade Offers
            if (data['trade_item_offer'] != null &&
                data['trade_item_offer'] is List &&
                data['trade_item_offer'].isNotEmpty) {
              List tradeOffers = data['trade_item_offer'];
              for (var offer in tradeOffers) {
                await tradeItemOfferRepository.addTradeItemOffer(
                  txn,
                  TradeItemOffer(
                    id: int.parse(offer['id']),
                    year: offer['year'],
                    mon: offer['mon'],
                    offerName: offer['offer_name'],
                    itemList: offer['item_list'],
                    minQty: offer['min_qty'],
                    maxQty: offer['max_qty'],
                    comboId: int.parse(offer['combo_id']),
                    giftItemId: offer['gift_item_id'],
                    gitQty: offer['git_qty'],
                    giftItemName: offer['gift_item_name'],
                    status: offer['status'] ?? 'Active',
                    entryBy: offer['entry_by'] ?? '',
                    entryAt: offer['entry_at'] ?? '',
                  ),
                );
              }
            }

            // Save Trade Offer Commissions
            if (data['trade_comission'] != null &&
                data['trade_comission'] is List &&
                data['trade_comission'].isNotEmpty) {
              List tradeComissions = data['trade_comission'];
              for (var comission in tradeComissions) {
                await tradeOfferComissionRepository
                    .addTradeOfferComissionWithTransaction(
                  txn,
                  TradeOfferComission(
                    id: int.parse(comission['id']),
                    year: comission['year'],
                    mon: comission['mon'],
                    offerName: comission['offer_name'],
                    itemGroup: comission['item_group'],
                    itemList: comission['item_list'],
                    comboId: int.parse(comission['combo_id']),
                    minQty: comission['min_qty'],
                    maxQty: comission['max_qty'],
                    freeQty: comission['free_qty'],
                    tradeComPer: comission['trade_com_per'],
                  ),
                );
              }
            }

            // Save Trade Percent Offers
            if (data['trade_offer_percentage'] != null &&
                data['trade_offer_percentage'] is List &&
                data['trade_offer_percentage'].isNotEmpty) {
              List tradeOffers = data['trade_offer_percentage'];
              for (var offer in tradeOffers) {
                await tradeOfferPercentageRepository.addTradeOffer(
                  txn,
                  TradeOfferPercentage(
                    id: int.parse(offer['id']),
                    year: offer['year'],
                    mon: offer['mon'],
                    offerName: offer['offer_name'],
                    itemList: offer['item_list'],
                    comboId: int.parse(offer['combo_id']),
                    minTaka: offer['min_taka'],
                    maxTaka: offer['max_taka'],
                    percentage: offer['percentage'],
                    status: offer['status'] ?? 'Active',
                    entryBy: offer['entry_by'] ?? '',
                    entryAt: offer['entry_at'] ?? '',
                  ),
                );
              }
            }
            if (data['trade_offer_percentage_extra'] != null &&
                data['trade_offer_percentage_extra'] is List &&
                data['trade_offer_percentage_extra'].isNotEmpty) {
              List tradeOffers = data['trade_offer_percentage_extra'];
              for (var offer in tradeOffers) {
                await tradeOfferPercentageExtraRepository.addTradeOffer(
                  txn,
                  TradeOfferPercentageExtra(
                    id: int.parse(offer['id']),
                    year: offer['year'],
                    mon: offer['mon'],
                    offerName: offer['offer_name'],
                    itemList: offer['item_list'],
                    comboId: int.parse(offer['combo_id']),
                    minTaka: offer['min_taka'],
                    maxTaka: offer['max_taka'],
                    percentage: offer['percentage'],
                    status: offer['status'] ?? 'Active',
                    entryBy: offer['entry_by'] ?? '',
                    entryAt: offer['entry_at'] ?? '',
                  ),
                );
              }
            }

            await saveRouteId(data['route_id'].toString());
            String? routeId = await getRouteId();
            print('All data refreshed successfully');
            return true;
          } catch (e) {
            await txn.delete('routes');
            await txn.delete('trade_offer_percentage');
            await txn.delete('ss_user');
            await txn.delete('trade_item_offer');
            await txn.delete('shops');
            await txn.delete('combos');
            await txn.delete('category');
            await txn.delete('sub_category');
            await txn.delete('item');
            await txn.delete('trade_offer');
            await txn.delete('trade_offer_comission');
            print('Error refreshing data: $e');
            // Rethrow to trigger rollback
          }
        });

        return true;
      } else {
        print('Invalid response from server');
        return false;
      }
    } catch (e) {
      print('Error in refreshAllData: $e');
      return false;
    } finally {
      setLoading(false);
    }
  }

  Future<void> saveRouteId(String routeId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('route_id', routeId);
  }

// Get route_id
  Future<String?> getRouteId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('route_id');
  }
}
