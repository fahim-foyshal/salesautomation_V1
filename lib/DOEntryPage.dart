import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:salesautomation_V4/databases/do_master_dao.dart';
import 'package:salesautomation_V4/model/do_master.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'model/Shop.dart';
import 'model/route.dart';
import 'repositories/route_repository.dart';
import 'repositories/shop_repository.dart';
import 'databases/route_dao.dart';

class DOEntryPage extends StatefulWidget {
  final Shop? selectedShop;

  const DOEntryPage({Key? key, this.selectedShop}) : super(key: key);

  @override
  _DOEntryPageState createState() => _DOEntryPageState();
}

class _DOEntryPageState extends State<DOEntryPage> {
  final ShopRepository shopRepository = ShopRepository();

  Shop? selectedShop;
  List<Shop> _shops = [];

  final TextEditingController distanceController = TextEditingController();
  final TextEditingController dateController = TextEditingController();
  final TextEditingController noteController = TextEditingController();

  Position? _currentPosition;
  bool _isCalculatingDistance = false;

  DoMasterDao doMasterDao = DoMasterDao();

  @override
  void initState() {
    super.initState();
    // Set default date to today
    final now = DateTime.now();
    final formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
    dateController.text = formatter.format(now);

    // Get current location
    _getCurrentLocation();

    // Load shops based on route_id from SharedPreferences
    _loadShopsFromPrefs();

    // If a shop was passed in, set it as selected
    if (widget.selectedShop != null) {
      selectedShop = widget.selectedShop;
      _calculateDistance();
    }
  }

  // Load shops directly from database filtered by route_id from SharedPreferences
  Future<void> _loadShopsFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final routeId = prefs.getString('route_id');
    if (routeId != null) {
      final shops = await shopRepository.getShopsByRouteId(routeId);
      setState(() {
        _shops = shops;
      });
    }
  }

  // Get current location
  Future<void> _getCurrentLocation() async {
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

      setState(() {
        _currentPosition = position;
      });
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  // Calculate distance between current location and selected shop
  Future<void> _calculateDistance() async {
    if (selectedShop == null || _currentPosition == null) {
      return;
    }

    setState(() {
      _isCalculatingDistance = true;
    });

    try {
      // Parse shop latitude and longitude
      double shopLat = double.parse(selectedShop!.latitude);
      double shopLng = double.parse(selectedShop!.longitude);

      // Calculate distance
      double distanceInMeters = await Geolocator.distanceBetween(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          shopLat,
          shopLng);

      // Convert to kilometers and round to 2 decimal places
      double distanceInKm = distanceInMeters / 1000;

      setState(() {
        distanceController.text = distanceInKm.toStringAsFixed(2);
        _isCalculatingDistance = false;
      });
    } catch (e) {
      print('Error calculating distance: $e');
      setState(() {
        _isCalculatingDistance = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF0069b5),
        title: Text(
          'DO Entry',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
        // leading: Icon(
        //   Icons.menu,
        //   color: Colors.white,
        // ),
        elevation: 0,
      ),
      body: Container(
        color: Color(0xFFF5F5F5),
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Shop Selection
            Text(
              'Shop List',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0069b5),
              ),
            ),
            SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Color(0xFF0069b5), width: 2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: DropdownButtonFormField<Shop>(
                decoration: InputDecoration(
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: InputBorder.none,
                  hintText: 'Select Shop',
                  hintStyle: TextStyle(color: Colors.grey[600]),
                ),
                value: selectedShop,
                icon: Icon(Icons.arrow_drop_down, color: Color(0xFF0069b5)),
                items: _shops.map((shop) {
                  return DropdownMenuItem<Shop>(
                    value: shop,
                    child: Text('${shop.shopName} (${shop.dealerCode})'),
                  );
                }).toList(),
                onChanged: (Shop? newValue) {
                  setState(() {
                    selectedShop = newValue;
                  });
                  _calculateDistance();
                },
              ),
            ),

            // Distance Meter
            SizedBox(height: 24),
            Text(
              'Distance Meter',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0069b5),
              ),
            ),
            SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Color(0xFF0069b5), width: 2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Stack(
                alignment: Alignment.centerRight,
                children: [
                  TextField(
                    controller: distanceController,
                    decoration: InputDecoration(
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: InputBorder.none,
                      hintText: 'Distance in km',
                      hintStyle: TextStyle(color: Colors.grey[600]),
                      suffixText: 'km',
                    ),
                    keyboardType: TextInputType.number,
                    readOnly:
                        true, // Make it read-only as it's calculated automatically
                  ),
                  if (_isCalculatingDistance)
                    Padding(
                      padding: const EdgeInsets.only(right: 16.0),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                ],
              ),
            ),

            SizedBox(height: 24),

            // DO Date and Note Row
            Row(
              children: [
                // Note
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Note',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0069b5),
                        ),
                      ),
                      SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border:
                              Border.all(color: Color(0xFF0069b5), width: 2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: TextField(
                          controller: noteController,
                          decoration: InputDecoration(
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            border: InputBorder.none,
                            hintText: 'Note',
                            hintStyle: TextStyle(color: Colors.grey[600]),
                          ),
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: 30),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      DoMaster newDoMaster = DoMaster(
                          doNo: '',
                          shopId: selectedShop!.dealerCode,
                          doDate: DateFormat('yyyy-MM-dd HH:mm:ss')
                              .format(DateTime.now()),
                          status: 'PENDING',
                          sentStatus: '0',
                          tradeOfferApplied: '0',
                          endLatitude: '',
                          endLongitude: '',
                          note: noteController.text.isNotEmpty
                              ? noteController.text
                              : null);

// Assuming you have an instance of DoMasterDao

// Insert the DoMaster object into the database
                      int result =
                          await doMasterDao.insertDoMaster(newDoMaster);
                      newDoMaster.doOfflineId = result;

// Check if the insertion was successful
                      if (result > 0) {
                        Navigator.pushNamed(
                          context,
                          '/addorder',
                          arguments: {
                            'doOfflineId':
                                newDoMaster, // Pass the DoMaster object
                            'shopId': selectedShop, // Pass the Shop object
                          },
                        );
                      } else {
                        print('Failed to insert record');
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF198754),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    child: Text(
                      'Get Order',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // Handle Close
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF0069b5),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    child: Text(
                      'Close',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      if (selectedShop != null) {
                        DoMaster noOrderDo = DoMaster(
                            doNo: '',
                            shopId: selectedShop!.dealerCode,
                            doDate: DateFormat('yyyy-MM-dd HH:mm:ss')
                                .format(DateTime.now()),
                            status: 'CHECKED',
                            sentStatus: '0',
                            tradeOfferApplied: '0',
                            endLatitude: '',
                            endLongitude: '',
                            type: 'NO_ORDER',
                            note: noteController.text.isNotEmpty
                                ? noteController.text
                                : null);
                        int result =
                            await doMasterDao.insertDoMaster(noOrderDo);
                        if (result > 0) {
                          Navigator.pop(context);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('Failed to record No Order')),
                          );
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Please select a shop first')),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFE53935),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    child: Text(
                      'No Order',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            Spacer(),

            // Home Navigation Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/navigation');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF0069b5),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.home, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Home',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    distanceController.dispose();
    dateController.dispose();
    noteController.dispose();
    super.dispose();
  }
}
