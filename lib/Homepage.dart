import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:permission_handler/permission_handler.dart' as perm;
import 'package:geolocator/geolocator.dart';
import 'package:salesautomation_V4/DatabaseHelper.dart';
// Updated to use UserDatabaseHelper
import 'package:salesautomation_V4/login_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Homepage extends StatefulWidget {
  const Homepage({Key? key}) : super(key: key);

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late InAppWebViewController _webViewController;
  bool _noInternetError = false;
  bool _isLoading = true;
  Timer? _locationPermissionTimer;
  Position? _currentPosition;
  static const MethodChannel locationChannel =
      MethodChannel('locationPlatform');
  static const EventChannel eventChannel =
      EventChannel('com.example.salesautomation_v4');
  StreamSubscription? _subscription;
  String? _username;
  bool _usercreated = false;
  String? _password;
  bool _flutterLoginShown = false;

  // Track navigation history to avoid cache issues
  List<String> _navigationHistory = [];
  String? _currentUrl;

  // Function to initialize and listen to event channel
  void startListening() {
    _subscription = eventChannel.receiveBroadcastStream().listen(
      (dynamic event) {
        print('Received event: $event');
        final coordinates = event.split(',');
        if (coordinates.length == 2) {
          final latitude = double.tryParse(coordinates[0].trim());
          final longitude = double.tryParse(coordinates[1].trim());
          if (latitude != null && longitude != null) {
            if (_username != null) {}
          }
        }
      },
      onError: (dynamic error) {
        print('Error occurred: $error');
      },
    );
  }

  // Function to call method on the method channel
  Future<void> getLocation() async {
    try {
      await locationChannel.invokeMethod('getLocation');
    } on PlatformException catch (e) {
      print('Failed to get location: ${e.message}');
    }
  }

  // Function to stop location service using method channel
  Future<void> stopLocation() async {
    try {
      await locationChannel.invokeMethod('stopLocation');
    } on PlatformException catch (e) {
      print('Failed to stop location: ${e.message}');
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await _requestPermissions();
    await UserDatabaseHelper().database; // 🔧 Ensures table is created
    startListening();
    await getLocation();
    _startLocationPermissionCheck();
  }

  Future<void> _initialize() async {
    // await DatabaseHelper().setUsername('default'); // Setting initial value
  }

  Future<void> _updateUsername(String newUsername) async {
    print('Saving username: $newUsername');
    await UserDatabaseHelper().insertUsername(newUsername);
    setState(() {
      _usercreated = true;
    });
  }

  @override
  void dispose() {
    _locationPermissionTimer?.cancel();
    _subscription?.cancel();
    super.dispose();
  }

  void send_Data_to_mysql_Database(double latitude, double longitude) async {
    print('username');

    final apiUrl =
        'https://apps.aksiderp.com/app/mobile/auth/ssApp/secApps.php';
    final dio = Dio();

    final jsonData = [
      {
        "latitude": latitude.toString(),
        "longitude": longitude.toString(),
        "user_id": _username
      }
    ];

    try {
      final response = await dio.post(
        apiUrl,
        data: jsonData,
        options: Options(
          headers: {'Content-Type': 'application/json'},
        ),
      );

      if (response.statusCode == 200) {
        print('success');
      } else {
        print('Failed to fetch data. Status code: ${response.statusCode}');
      }
    } catch (error) {
      print('Error: $error');
    }
  }

  void _getLocationUpdates() {
    Geolocator.getPositionStream().listen((Position position) {
      setState(() {
        _currentPosition = position;
      });
      _sendLocationToServer(position);
    });
  }

  void _sendLocationToServer(Position position) {
    // databaseReference.child('users/user1/location').set({
    //   'latitude': position.latitude,
    //   'longitude': position.longitude,
    // });
  }

  void _redirectToFlutterLoginIfNeeded(WebUri? url) {
    final u = url?.toString().toLowerCase() ?? '';
    final shouldRedirect = u.contains('offline_do.php');
    if (shouldRedirect) {
      _flutterLoginShown = true;
      Navigator.pushNamed(context, '/login');
    }
  }

  Future<void> _handleBackNavigation() async {
    try {
      // Get the current URL first
      final currentUrl = await _webViewController.getUrl();
      print('Current URL before back: $currentUrl');

      // Check if we can go back
      if (await _webViewController.canGoBack()) {
        // Clear the navigation history to force a fresh load
        await _webViewController.clearHistory();

        // If we have a previous URL in our history, load it directly
        if (_navigationHistory.length > 1) {
          // Remove current URL
          _navigationHistory.removeLast();
          // Get previous URL
          final previousUrl = _navigationHistory.last;
          print('Loading previous URL: $previousUrl');

          // Load the previous URL directly instead of using goBack
          await _webViewController.loadUrl(
              urlRequest: URLRequest(url: WebUri(previousUrl)));
        } else {
          // Fallback to home page if no history
          print('No history available, loading home page');
          await _webViewController.loadUrl(
              urlRequest: URLRequest(
                  url: WebUri(
                      'https://mepgrouperp.com/sss/sec_mobile_app/main/home.php')));
        }
      }
    } catch (e) {
      print('Error in back navigation: $e');
      // On error, reload current page
      _webViewController.reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_flutterLoginShown) {
          _flutterLoginShown = false;
          return true;
        }

        if (await _webViewController.canGoBack()) {
          await _handleBackNavigation();
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(''),
          backgroundColor: const Color(0xFF6E14EE),
          toolbarHeight: 2.0,
        ),
        key: _scaffoldKey,
        body: Stack(
          children: [
            if (!_noInternetError)
              InAppWebView(
                initialUrlRequest: URLRequest(
                    url: WebUri(
                        'https://mepgrouperp.com/sss/sec_mobile_app/main/home.php')),
                initialSettings: InAppWebViewSettings(
                  javaScriptEnabled: true,
                  mediaPlaybackRequiresUserGesture: false,
                  cacheEnabled: true,
                  cacheMode: CacheMode.LOAD_CACHE_ELSE_NETWORK,
                  domStorageEnabled: true,
                  databaseEnabled: true,
                  useWideViewPort: true,
                  loadWithOverviewMode: true,
                  javaScriptCanOpenWindowsAutomatically: true,
                  allowFileAccessFromFileURLs: true,
                  allowUniversalAccessFromFileURLs: true,
                  thirdPartyCookiesEnabled: true,
                  mixedContentMode: MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
                ),
                onGeolocationPermissionsShowPrompt:
                    (InAppWebViewController controller, String origin) async {
                  return GeolocationPermissionShowPromptResponse(
                    origin: origin,
                    allow: true,
                    retain: true,
                  );
                },
                androidOnPermissionRequest: (InAppWebViewController controller,
                    String origin, List<String> resources) async {
                  return PermissionRequestResponse(
                      resources: resources,
                      action: PermissionRequestResponseAction.GRANT);
                },
                shouldOverrideUrlLoading: (controller, navigationAction) async {
                  final url = navigationAction.request.url?.toString();
                  print('Navigation to: $url');
                  print(
                      'Is for main frame: ${navigationAction.isForMainFrame}');
                  print('Navigation type: ${navigationAction.navigationType}');

                  _redirectToFlutterLoginIfNeeded(navigationAction.request.url);
                  return NavigationActionPolicy.ALLOW;
                },
                onWebViewCreated: (controller) {
                  _webViewController = controller;
                  print('WebView created');
                },
                onLoadStart: (controller, url) {
                  print('Load started: $url');
                  setState(() {
                    _isLoading = true;
                  });
                },
                onLoadStop: (controller, url) async {
                  print('Load stopped: $url');

                  setState(() {
                    _isLoading = false;
                  });

                  // Track navigation history - only add if it's different from the last URL
                  final urlString = url?.toString() ?? '';
                  if (urlString.isNotEmpty &&
                      (_navigationHistory.isEmpty ||
                          _navigationHistory.last != urlString)) {
                    _navigationHistory.add(urlString);
                    _currentUrl = urlString;
                    print('Navigation history: $_navigationHistory');
                  }

                  _redirectToFlutterLoginIfNeeded(url);

                  _webViewController
                      .evaluateJavascript(
                          source: "sessionStorage.getItem('username');")
                      .then((value) {
                    setState(() {
                      _username = value?.replaceAll('"', '');
                    });
                    if (_username != null && _usercreated == false) {
                      _updateUsername(_username!);
                    }
                  });

                  _webViewController
                      .evaluateJavascript(
                          source: "sessionStorage.getItem('password');")
                      .then((value) {
                    setState(() {
                      _password = value?.replaceAll('"', '');
                    });
                  });
                },
                onLoadError: (controller, url, code, message) {
                  print(
                      'Load error - URL: $url, Code: $code, Message: $message');

                  // Handle no internet connection
                  if (code == -2) {
                    setState(() {
                      _noInternetError = true;
                      _isLoading = false;
                    });
                    return;
                  }

                  // Handle ERR_CACHE_MISS error
                  if (message.contains('ERR_CACHE_MISS') ||
                      message.contains('net::ERR_CACHE_MISS') ||
                      code == -400) {
                    print('Cache miss error detected');

                    setState(() {
                      _isLoading = false;
                    });

                    // Load the home page or the last known good URL
                    Future.delayed(Duration(milliseconds: 100), () {
                      if (_navigationHistory.length > 1) {
                        // Go to the previous page in our tracked history
                        final previousUrl =
                            _navigationHistory[_navigationHistory.length - 2];
                        print('Reloading previous URL: $previousUrl');
                        controller.loadUrl(
                            urlRequest: URLRequest(url: WebUri(previousUrl)));
                      } else {
                        // Fallback to home page
                        print('Loading home page after cache miss');
                        controller.loadUrl(
                            urlRequest: URLRequest(
                                url: WebUri(
                                    'https://mepgrouperp.com/sss/sec_mobile_app/main/home.php')));
                      }
                    });
                  }
                },
                onLoadHttpError: (controller, url, statusCode, description) {
                  print(
                      'HTTP Error - URL: $url, Status: $statusCode, Description: $description');
                  setState(() {
                    _isLoading = false;
                  });
                },
                onReceivedError: (controller, request, error) {
                  print(
                      'Received error - URL: ${request.url}, Type: ${error.type}, Description: ${error.description}');
                },
                onProgressChanged: (controller, progress) {
                  // Optional: You can use this to show progress
                  // print('Progress: $progress%');
                },
              ),
            if (_isLoading && !_noInternetError)
              const Center(
                child: CircularProgressIndicator(),
              ),
            if (_noInternetError)
              Center(
                child: Container(
                  decoration: BoxDecoration(),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/netbg.png',
                        fit: BoxFit.contain,
                        width: 1000.0,
                        height: 250.0,
                      ),
                      const Text(
                        'No internet connection',
                        style: TextStyle(
                            fontSize: 22.0,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFF5508)),
                      ),
                      const Text(
                        'Check Your Connection or',
                        style: TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.w500,
                            color: Color.fromARGB(255, 150, 145, 143)),
                      ),
                      const SizedBox(height: 16.0),
                      ElevatedButton(
                        onPressed: () {
                          _reloadWebView();
                        },
                        child: const Text('Try Again'),
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

  void _reloadWebView() {
    setState(() {
      _noInternetError = false;
    });

    _webViewController.reload();
  }

  Future<void> _requestPermissions() async {
    var locationStatus = await perm.Permission.location.request();
    var cameraStatus = await perm.Permission.camera.request();

    if (locationStatus == perm.PermissionStatus.granted) {
      print('Location permission granted');
    } else {
      print('Location permission denied');
    }

    if (cameraStatus == perm.PermissionStatus.granted) {
      print('Camera permission granted');
    } else {
      print('Camera permission denied');
    }
  }

  void _startLocationPermissionCheck() {
    _locationPermissionTimer =
        Timer.periodic(const Duration(seconds: 5), (timer) async {
      var serviceStatus = await perm.Permission.location.serviceStatus;
      if (serviceStatus == perm.ServiceStatus.disabled) {
        SystemNavigator.pop();
      }
    });
  }
}
