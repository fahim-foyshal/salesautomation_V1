import 'package:flutter/material.dart';
import 'package:salesautomation_V4/Homepage.dart';
import 'package:salesautomation_V4/NavigatonPage.dart';
import 'package:salesautomation_V4/api_service.dart';
import 'package:salesautomation_V4/login_page.dart';
import 'package:salesautomation_V4/route_and_shop_selection_screen.dart';
import 'package:salesautomation_V4/unroute_wise_screen.dart';
import 'package:salesautomation_V4/DOEntryPage.dart';
// Remove the location permission helper import

import 'add_item_screen.dart';
import 'model/Shop.dart';
import 'model/do_master.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // // Initialize API service
  final apiService = ApiService();
  await apiService.initialize();

  // // await Firebase.initializeApp(
  // //   options: DefaultFirebaseOptions.currentPlatform,
  // // );

  runApp(MyApp(apiService: apiService));
}

class MyApp extends StatelessWidget {
  final ApiService apiService;

  const MyApp({Key? key, required this.apiService}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/homepage',
      routes: {
        '/homepage': (context) => FutureBuilder<bool>(
              future: _checkDailyRefresh(context),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Refreshing data...',
                              style: TextStyle(fontSize: 16)),
                        ],
                      ),
                    ),
                  );
                }
                // Remove the location permission request code
                return Homepage();
              },
            ),
        '/selectshop': (context) => SelectShopPage(),
        '/navigation': (context) => NavigationPage(),
        '/login': (context) => LoginPage(),
        '/orderpage': (context) => UnRouteWiseOrderPage(
            selectedShop: ModalRoute.of(context)!.settings.arguments as Shop),
        '/doentry': (context) => DOEntryPage(
            selectedShop: ModalRoute.of(context)?.settings.arguments as Shop?),
        '/addorder': (context) {
          final args = ModalRoute.of(context)!.settings.arguments
              as Map<String, dynamic>;
          return AddItemsPage(
            doOfflineId: args['doOfflineId'] as DoMaster,
            shopId: args['shopId'] as Shop,
          );
        },
      },
    );
  }

  Future<bool> _checkDailyRefresh(BuildContext context) async {
    if (await apiService.shouldRefreshToday()) {
      // Show loading indicator while refreshing data
      bool success = await apiService.refreshAllData((loading) {
        // This callback is handled by the FutureBuilder
      });

      if (success) {
        await apiService.updateLastRefreshDate();
      } else {
        // Optional: Show error message if refresh failed
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to refresh data. Please try again later.'),
              duration: Duration(seconds: 3),
            ),
          );
        });
      }
    }
    return true; // Return true to continue to Homepage
  }
}
