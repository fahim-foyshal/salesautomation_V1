import 'package:flutter/material.dart';
import 'package:salesautomation_V4/add_item_screen.dart';

import 'databases/do_master_dao.dart';
import 'model/Shop.dart';
import 'model/do_master.dart';
import 'package:intl/intl.dart';

class UnRouteWiseOrderPage extends StatefulWidget {
  final Shop selectedShop;

  const UnRouteWiseOrderPage({Key? key, required this.selectedShop})
      : super(key: key);

  @override
  _UnRouteWiseOrderPageState createState() => _UnRouteWiseOrderPageState();
}

class _UnRouteWiseOrderPageState extends State<UnRouteWiseOrderPage> {
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  DoMasterDao doMasterDao = DoMasterDao();

  @override
  void initState() {
    super.initState();
    // Automatically set today's date on page load
    _dateController.text = _formatDate(DateTime.now());
  }

  /// Helper method to format date (MM/dd/yyyy)
  String _formatDate(DateTime date) {
    return "${date.month.toString().padLeft(2, '0')}/"
        "${date.day.toString().padLeft(2, '0')}/"
        "${date.year}";
  }

  /// Show a date picker and store the result in _dateController
  Future<void> _pickDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      setState(() {
        _dateController.text = _formatDate(pickedDate);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // If you want a drawer for the hamburger icon, define a Drawer widget
      drawer: Drawer(
        child: ListView(
          children: const [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text('Menu', style: TextStyle(color: Colors.white)),
            ),
            // Add drawer items here...
          ],
        ),
      ),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0069b5),
        title: const Text(
          'Un Route Wise Order',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
        leading: Builder(
          builder: (context) {
            return IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
        elevation: 0,
      ),
      body: Container(
        color: const Color(0xFFF5F5F5),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Shop display (read-only)
            Text(
              '${widget.selectedShop.shopName}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0069b5),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Color(0xFF0069b5), width: 2.0),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const SizedBox(),
            ),
            const SizedBox(height: 16.0),



            Text(
              'Note',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0069b5),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Color(0xFF0069b5), width: 2.0),
                borderRadius: BorderRadius.circular(4),
              ),
              child: TextField(
                controller: _noteController,
                maxLines: 1,
                decoration: const InputDecoration(
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 16.0),

            // Three buttons in a row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Get Order Button (Green)
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(right: 8.0),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF198754),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      onPressed: () async {
                        // Handle "Get Order"

                        DoMaster newDoMaster = DoMaster(
                            doNo: '',
                            shopId: widget.selectedShop.dealerCode,
                            doDate: DateFormat('yyyy-MM-dd HH:mm:ss')
                                .format(DateTime.now()),
                            status: 'PENDING',
                            sentStatus: '0',
                            tradeOfferApplied: '0',
                            endLatitude: '',
                            endLongitude: '',
                            note: _noteController.text.isNotEmpty
                                ? _noteController.text
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
                              'shopId':
                                  widget.selectedShop, // Pass the Shop object
                            },
                          );
                        } else {
                          print('Failed to insert record');
                        }

                        debugPrint("Get Order: Shop = ${widget.selectedShop}, "
                            "Date = ${_dateController.text}, "
                            "Note = ${_noteController.text}");
                      },
                      child: const Text('Get Order'),
                    ),
                  ),
                ),

                // Close Button (Blue)
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(right: 8.0),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D6EFD),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      onPressed: () {
                        // Handle "Close"
                        debugPrint("Close tapped");
                        Navigator.pop(context);
                      },
                      child: const Text('Close'),
                    ),
                  ),
                ),

                // No Order Button (Red)
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDC3545),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    onPressed: () async {
                      DoMaster noOrderDo = DoMaster(
                          doNo: '',
                          shopId: widget.selectedShop.dealerCode,
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
                              : null);
                      int result = await doMasterDao.insertDoMaster(noOrderDo);
                      if (result > 0) {
                        Navigator.pop(context);
                      } else {
                        debugPrint('Failed to insert No Order record');
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
    );
  }
}
