import 'package:flutter/material.dart';
import 'package:salesautomation_V4/do_list.dart';
import 'package:salesautomation_V4/unroute_wise_screen.dart';
import '../repositories/route_repository.dart';
import '../repositories/shop_repository.dart';
import '../model/route.dart';
import '../model/Shop.dart';
import 'databases/route_dao.dart';
import 'api_service.dart';
import 'databases/do_master_dao.dart';
import 'model/do_master.dart';
import 'package:intl/intl.dart';

class SelectShopPage extends StatefulWidget {
  const SelectShopPage({Key? key}) : super(key: key);

  @override
  _SelectShopPageState createState() => _SelectShopPageState();
}

class _SelectShopPageState extends State<SelectShopPage> {
  final RouteRepository routeRepository = RouteRepository(RouteDao());
  final ShopRepository shopRepository = ShopRepository();

  String? _selectedRoute;
  Shop? _selectedShop;
  List<Shop> _availableShops = [];
  List<SsRoute> _routes = [];
  bool _isSyncing = false;

  final TextEditingController _noteController = TextEditingController();
  final DoMasterDao doMasterDao = DoMasterDao();

  @override
  void initState() {
    super.initState();
    _loadRoutes();
  }

  Future<void> _loadRoutes() async {
    final routes = await routeRepository.getAllRoutes();
    setState(() {
      _routes = routes;
    });
  }

  Future<void> _loadShops(String routeId) async {
    final shops = await shopRepository.getAllShops();
    final filteredShops =
        shops.where((shop) => shop.routeId == routeId).toList();
    setState(() {
      _availableShops = filteredShops;
      _selectedShop = null;
    });
  }

  Future<void> _syncData() async {
    try {
      // Show overlay loading
      _showLoadingOverlay(context);

      ApiService apiService = ApiService();
      final success = await apiService.syncDataToApi((loading) {
        setState(() {
          _isSyncing = loading;
        });
      });

      // Remove overlay loading
      Navigator.of(context, rootNavigator: true).pop();

      // Show snackbar with result
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? 'Data synchronized successfully'
              : 'Data synchronization failed'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    } catch (e) {
      // Remove overlay loading in case of any unexpected error
      Navigator.of(context, rootNavigator: true).pop();

      // Show error snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error during synchronization: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Custom method to show loading overlay
  void _showLoadingOverlay(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(
          child: SizedBox(
            width: 100,
            height: 100,
            child: Card(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 10),
                  Text('Syncing...'),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Shop'),
        backgroundColor: const Color(0xFF0069b5),
        toolbarHeight: 50.0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Route Dropdown
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Route',
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide:
                        BorderSide(color: Color(0xFF0069b5), width: 2.0),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide:
                        BorderSide(color: Color(0xFF0069b5), width: 2.0),
                  ),
                ),
                value: _selectedRoute,
                items: _routes.map((route) {
                  return DropdownMenuItem<String>(
                    value: route.routeId.toString(),
                    child: Text(route.routeName),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedRoute = value;
                    _loadShops(value!);
                  });
                },
              ),
              const SizedBox(height: 16.0),

              // Shop Dropdown
              DropdownButtonFormField<Shop>(
                decoration: const InputDecoration(
                  labelText: 'Shop',
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide:
                        BorderSide(color: Color(0xFF0069b5), width: 2.0),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide:
                        BorderSide(color: Color(0xFF0069b5), width: 2.0),
                  ),
                ),
                value: _selectedShop,
                items: _availableShops.map((shop) {
                  return DropdownMenuItem<Shop>(
                    value: shop,
                    child: Text('${shop.shopName} (${shop.dealerCode})'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedShop = value;
                  });
                },
              ),
              const SizedBox(height: 16.0),

              // Note
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: 'Note',
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide:
                        BorderSide(color: Color(0xFF0069b5), width: 2.0),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide:
                        BorderSide(color: Color(0xFF0069b5), width: 2.0),
                  ),
                ),
                maxLines: 1,
              ),
              const SizedBox(height: 16.0),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF198754),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: () async {
                        if (_selectedShop != null) {
                          DoMaster newDoMaster = DoMaster(
                            doNo: '',
                            shopId: _selectedShop!.dealerCode,
                            doDate: DateFormat('yyyy-MM-dd HH:mm:ss')
                                .format(DateTime.now()),
                            status: 'PENDING',
                            sentStatus: '0',
                            tradeOfferApplied: '0',
                            endLatitude: '',
                            endLongitude: '',
                            note: _noteController.text.isNotEmpty
                                ? _noteController.text
                                : null,
                          );
                          int result =
                              await doMasterDao.insertDoMaster(newDoMaster);
                          newDoMaster.doOfflineId = result;
                          if (result > 0) {
                            Navigator.pushNamed(
                              context,
                              '/addorder',
                              arguments: {
                                'doOfflineId': newDoMaster,
                                'shopId': _selectedShop,
                              },
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Failed to create order')),
                            );
                          }
                        }
                      },
                      child: const Text('Get Order'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D6EFD),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text('Close'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFDC3545),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: () async {
                        if (_selectedShop != null) {
                          DoMaster noOrderDo = DoMaster(
                            doNo: '',
                            shopId: _selectedShop!.dealerCode,
                            doDate: DateFormat('yyyy-MM-dd HH:mm:ss')
                                .format(DateTime.now()),
                            status: 'CHECKED',
                            sentStatus: '0',
                            tradeOfferApplied: '0',
                            endLatitude: '',
                            endLongitude: '',
                            type: 'NO_ORDER',
                            note: _noteController.text.isNotEmpty
                                ? _noteController.text
                                : null,
                          );
                          int result =
                              await doMasterDao.insertDoMaster(noOrderDo);
                          if (result > 0) {
                            Navigator.pop(context);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Failed to record No Order')),
                            );
                          }
                        }
                      },
                      child: const Text('No Order'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Color(0xFF0069b5),
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2),
            label: 'Order',
          ),
        ],
        onTap: (int index) {
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, '/navigation');
              break;
            case 1:
              break;
          }
        },
      ),
    );
  }
}
