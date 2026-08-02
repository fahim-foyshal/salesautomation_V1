import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:salesautomation_V4/api_service.dart';
import 'package:salesautomation_V4/databases/combo_dao.dart';
import 'package:salesautomation_V4/databases/route_dao.dart';
import 'package:salesautomation_V4/model/Shop.dart';
import 'package:salesautomation_V4/model/combo.dart';
import 'package:salesautomation_V4/model/trade_item_offer.dart';
import 'package:salesautomation_V4/model/trade_offer_percentage.dart';
import 'package:salesautomation_V4/model/trade_offer_percentage_extra.dart';
import 'package:salesautomation_V4/repositories/combo_repository.dart';
import 'package:salesautomation_V4/repositories/route_repository.dart';
import 'package:salesautomation_V4/repositories/shop_repository.dart';
import 'package:salesautomation_V4/repositories/trade_item_offer_repository.dart';
import 'package:salesautomation_V4/repositories/trade_offer_percentage_repository.dart';
import 'package:salesautomation_V4/repositories/trade_offer_percentage_repository_extra.dart';
import 'package:salesautomation_V4/repositories/user_repository.dart';
import 'package:salesautomation_V4/repositories/category_repository.dart';
import 'package:salesautomation_V4/repositories/sub_category_repository.dart';
import 'package:salesautomation_V4/repositories/item_repository.dart';
import 'package:salesautomation_V4/repositories/trade_offer_repository.dart';
import 'package:salesautomation_V4/repositories/trade_offer_comission_repository.dart'; // Add this import
import 'package:salesautomation_V4/route_and_shop_selection_screen.dart';
import 'package:salesautomation_V4/utilities/base_url.dart';
import 'model/route.dart';
import 'model/user.dart';
import 'model/category.dart';
import 'model/sub_category.dart';
import 'model/item.dart';
import 'model/trade_offer.dart';
import 'model/trade_offer_comission.dart'; // Add this import
import 'databases/database_helper.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final UserRepository userRepository =
      UserRepository(); // User repository instance
  final RouteRepository routeRepository =
      RouteRepository(RouteDao()); // User repository instance
  // User repository instance
  final ShopRepository shopRepository = ShopRepository();
  bool isLoading = true; // Add a loading state for initial check
  bool isSavingData = false; // Add state for saving data during login
  final TradeOfferRepository tradeOfferRepository =
      TradeOfferRepository(); // Add this line
  final TradeOfferPercentageRepository tradeOfferPercentageRepository =
      TradeOfferPercentageRepository(); // Add this line
  final TradeOfferPercentageExtraRepository
      tradeOfferPercentageExtraRepository =
      TradeOfferPercentageExtraRepository(); // Add this line

  final TradeItemOfferRepository tradeItemOfferRepository =
      TradeItemOfferRepository(); // Add this line
  final ComboRepository comboRepository = ComboRepository(ComboDao());
  final TradeOfferComissionRepository tradeOfferComissionRepository =
      TradeOfferComissionRepository(); // Add this line

  @override
  void initState() {
    super.initState();
    _checkIfUserExists();
  }

  // Check if the user is already logged in (i.e., if a user exists in the database)
  Future<void> _checkIfUserExists() async {
    List<User> users = await userRepository.getUsers();
    if (users.isNotEmpty) {
      Navigator.pushNamed(
        context,
        '/navigation',
        // Pass the Shop object here
      );
      // If user exists, navigate to the SelectShopPage directly
      // Navigator.pushReplacement(
      //   context,
      //   MaterialPageRoute(builder: (context) => const SelectShopPage()),
      // );
    } else {
      setState(() {
        isLoading = false; // Stop loading and show the login form
      });
    }
  }

  Future<void> login() async {
    String username = usernameController.text;
    String password = passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Please enter both username and password")),
      );
      return;
    }

    Dio dio = Dio();
    dio.options.validateStatus = (status) => status! < 500;
    final String apiUrl = '${BaseUrl.apiUrl}api_users.php';

    try {
      setState(() {
        isSavingData = true; // Start showing loader
      });

      final response = await dio.post(
        apiUrl,
        data: [
          {
            'user': username,
            'password': password,
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Required data is missing or empty")),
          );
          return; // Exit if any of the required data is empty
        }

        // Wrap all database operations inside a transaction for atomicity
        final db = await DatabaseHelper.instance.database;
        await db.transaction((txn) async {
          try {
            // Save User using transactional method
            var userData = data['user'];
            if (userData == null || userData.isEmpty) {
              throw Exception("User data is missing.");
            }
            User user = User.fromMap(userData);
            await userRepository.addUser(txn, user);

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
            final categoryRepository = CategoryRepository();
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
            final subCategoryRepository = SubCategoryRepository();
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
            final itemRepository = ItemRepository();
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
            // Save Trade Percent Offers
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
            final apiService = ApiService();
            await apiService.saveRouteId(data['route_id'].toString());
            String? routeId = await apiService.getRouteId();
            print(routeId);
            // If no issues, commit the transaction (implicitly done if no exceptions are thrown)
            print('All data saved successfully.');
            Navigator.pushNamed(
              context,
              '/navigation',
              // Pass the Shop object here
            );
          } catch (e) {
            // If any error occurs, rollback the transaction
            print('Error: $e');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Error: $e")),
            );
            // If an error happens, the transaction will not commit, and the data will not be saved
            rethrow;
          }
        }); // End of transaction
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Invalid credentials")),
        );
      }
    } catch (e) {
      print('Error saving data: $e');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error saving data: $e")),
      );
      rethrow;
    } finally {
      // Only hide the loader in finally block
      setState(() {
        isSavingData = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Main content
          isLoading // Show loading indicator if still checking user existence
              ? Center(child: CircularProgressIndicator())
              : Container(
                  margin: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _header(context),
                      _inputField(context),
                      _forgotPassword(context),
                      _signup(context),
                    ],
                  ),
                ),
          // Overlay loading indicator while saving data
          if (isSavingData)
            Container(
              color: Colors.black.withOpacity(0.4),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xFF0069b5)),
                    ),
                    SizedBox(height: 16),
                    Text(
                      "Saving data...",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  _header(context) {
    return const Column(
      children: [
        Text(
          "Welcome Back",
          style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
        ),
        Text("Enter your credential to login"),
      ],
    );
  }

  _inputField(context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: usernameController,
          decoration: InputDecoration(
            hintText: "Username",
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none),
            fillColor: const Color(0xFF0069b5).withOpacity(0.1),
            filled: true,
            prefixIcon: const Icon(Icons.person),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: passwordController,
          decoration: InputDecoration(
            hintText: "Password",
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none),
            fillColor: const Color(0xFF0069b5).withOpacity(0.1),
            filled: true,
            prefixIcon: const Icon(Icons.password),
          ),
          obscureText: true,
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: isSavingData ? null : login, // Disable button while saving
          style: ElevatedButton.styleFrom(
            shape: const StadiumBorder(),
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: const Color(0xFF0069b5),
            disabledBackgroundColor: const Color(0xFF0069b5).withOpacity(0.5),
          ),
          child: const Text(
            "Login",
            style: TextStyle(fontSize: 20, color: Colors.white),
          ),
        )
      ],
    );
  }

  _forgotPassword(context) {
    return TextButton(
      onPressed: () {},
      child: const Text(
        "Forgot password?",
        style: TextStyle(color: Color(0xFF0069b5)),
      ),
    );
  }

  _signup(context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("Don't have an account? "),
        TextButton(
          onPressed: () {},
          child: const Text(
            "Sign Up",
            style: TextStyle(color: Color(0xFF0069b5)),
          ),
        )
      ],
    );
  }
}
