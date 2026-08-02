import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:salesautomation_V4/add_item_screen.dart';
import 'Widget/filter_button.dart';
import 'databases/do_master_dao.dart';
import 'databases/shop_dao.dart';
import 'model/Shop.dart';
import 'model/do_master.dart';

class DoList extends StatefulWidget {
  @override
  _DoListState createState() => _DoListState();
}

class _DoListState extends State<DoList> {
  late Future<List<DoMaster>> _doMasters;
  String selectedFilter = 'ALL'; // Default filter is 'ALL'

  void _updateFilter(String filter) {
    setState(() {
      selectedFilter = filter;
      // Update the Future directly here
      _doMasters = _fetchDoMasters();
    });
  }

  @override
  void initState() {
    super.initState();
    _doMasters = _fetchDoMasters();
  }

  // Fetch all DoMaster records from the database
  Future<List<DoMaster>> _fetchDoMasters() async {
    print(selectedFilter);

    final dao = DoMasterDao();
    if (selectedFilter == 'ALL') {
      return await dao.getAllDoMasters();
    } else {
      final list = await dao.getDoMastersByStatus(selectedFilter);
      list.sort((a, b) => b.doDate.compareTo(a.doDate));
      return list;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('Do Master List'),
        backgroundColor: const Color(0xFF0069b5),
      ),
      body: Column(
        children: [
          // Filter buttons row
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: ['ALL', 'CHECKED', 'PENDING'].map((filter) {
                return FilterButton(
                  text: filter,
                  isSelected: selectedFilter == filter,
                  onTap: () => _updateFilter(filter),
                );
              }).toList(),
            ),
          ),

          // Display the list of DoMasters
          Expanded(
            child: FutureBuilder<List<DoMaster>>(
              future: _doMasters,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('No DoMaster records found.'));
                } else {
                  final doMasters = snapshot.data!;
                  return ListView.builder(
                    itemCount: doMasters.length,
                    itemBuilder: (context, index) {
                      final doMaster = doMasters[index];

                      // Convert string doDate to DateTime
                      DateTime parsedDate = DateFormat('yyyy-MM-dd HH:mm:ss').parse(doMaster.doDate);

                      // Fetch shop details using the shopId (dealerCode)
                      Future<Shop?> shopFuture = ShopDao().getShopByDealerCode(doMaster.shopId);

                      return FutureBuilder<Shop?>(
                        future: shopFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return CircularProgressIndicator();
                          } else if (snapshot.hasError) {
                            return Center(child: Text('Error: ${snapshot.error}'));
                          } else if (!snapshot.hasData) {
                            return Center(child: Text('Shop not found.'));
                          } else {
                            final shop = snapshot.data!; // The shop data

                            return InkWell(
                              onTap: () {
                                // Navigate to another screen when the card is tapped
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AddItemsPage(doOfflineId: doMaster,shopId:shop ,), // Replace with your screen
                                  ),
                                );
                              },
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Make the left side column expand to take available space
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'DO No: ${doMaster.doOfflineId}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.only(top: 8.0),
                                              child: Text(
                                                DateFormat('dd MMM yyyy, HH:mm').format(parsedDate),
                                                style: TextStyle(
                                                  color: Colors.grey[600],
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.symmetric(vertical: 8),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                                decoration: BoxDecoration(
                                                  color: doMaster.status == 'CHECKED' ? Colors.green : Colors.red,
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  doMaster.status == 'CHECKED' ? 'Completed' : 'Pending',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Right side column with fixed content
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          // Wrap Text in a Container with width constraint
                                          Container(
                                            width: MediaQuery.of(context).size.width * 0.5, // Takes approximately 1/3 of screen width
                                            child: Text(
                                              '${shop.shopName}',
                                              style: const TextStyle(
                                                color: Colors.red,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Icon(
                                            Icons.done_all,
                                            color: doMaster.sentStatus == '1' ? Colors.green : Colors.grey,
                                            size: 40,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }
                        },
                      );
                    },
                  );


                }
              },
            ),
          ),
        ],
      ),


    );
  }
}
