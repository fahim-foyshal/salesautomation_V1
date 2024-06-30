import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';

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

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    _startLocationPermissionCheck();
  }

  @override
  void dispose() {
    _locationPermissionTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (await _webViewController.canGoBack()) {
          _webViewController.goBack();
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(''),
          backgroundColor: Color(0xFFf1faee),
          toolbarHeight: 10.0,
        ),
        key: _scaffoldKey,
        body: SingleChildScrollView(
          child: Container(
            height: MediaQuery.of(context).size.height - 40,
            child: Stack(
              children: [
                Material(
                  elevation: 4.0,
                  child: Container(
                    height: 50.0,
                    alignment: Alignment.centerRight,
                    padding: EdgeInsets.only(right: 16.0),
                    color: Color(0xFFF5F5F5),
                    child: Image.asset(
                      'assets/ERP-OLD-LOGO.png',
                      fit: BoxFit.contain,
                      width: 100.0,
                      height: 50.0,
                    ),
                  ),
                ),
                if (!_noInternetError)
                  InAppWebView(
                    initialUrlRequest: URLRequest(
                        url: WebUri(
                            'https://cloudmvc.clouderp.com.bd/app/views/sec_mobile_app')),
                    initialSettings: InAppWebViewSettings(
                      javaScriptEnabled: true,
                      mediaPlaybackRequiresUserGesture: false,
                    ),
                    onGeolocationPermissionsShowPrompt:
                        (InAppWebViewController controller,
                            String origin) async {
                      return GeolocationPermissionShowPromptResponse(
                        origin: origin,
                        allow: true,
                        retain: true,
                      );
                    },
                    androidOnPermissionRequest:
                        (InAppWebViewController controller, String origin,
                            List<String> resources) async {
                      return PermissionRequestResponse(
                          resources: resources,
                          action: PermissionRequestResponseAction.GRANT);
                    },
                    onWebViewCreated: (controller) {
                      _webViewController = controller;
                    },
                    onLoadStart: (controller, url) {
                      _startLocationPermissionCheck();
                      setState(() {
                        _isLoading = true;
                      });
                    },
                    onLoadStop: (controller, url) {
                      _startLocationPermissionCheck();
                      setState(() {
                        _isLoading = false;
                      });
                    },
                    onLoadError: (controller, url, code, message) {
                      if (code == -2) {
                        setState(() {
                          _noInternetError = true;
                        });
                      }
                    },
                  ),
                if (_isLoading && !_noInternetError)
                  const Center(
                    child: CircularProgressIndicator(),
                  ),
                if (_noInternetError)
                  Center(
                    child: Container(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Column(
                            children: [
                              Image.asset(
                                'assets/netbg.png',
                                fit: BoxFit.contain,
                                width: 1000.0,
                                height: 250.0,
                              ),
                              Text(
                                'No internet connection',
                                style: TextStyle(
                                    fontSize: 22.0,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFFFF5508)),
                              ),
                              Text(
                                'Check Your Connection or',
                                style: TextStyle(
                                    fontSize: 16.0,
                                    fontWeight: FontWeight.w500,
                                    color: Color.fromARGB(255, 150, 145, 143)),
                              ),
                            ],
                          ),
                          SizedBox(height: 16.0),
                          ElevatedButton(
                            onPressed: () {
                              _reloadWebView();
                            },
                            child: Text('Try Again'),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
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
    var locationStatus = await Permission.location.request();
    var cameraStatus = await Permission.camera.request();

    if (locationStatus == PermissionStatus.granted) {
      print('Location permission granted');
    } else {
      print('Location permission denied');
    }

    if (cameraStatus == PermissionStatus.granted) {
      print('Camera permission granted');
    } else {
      print('Camera permission denied');
    }
  }

  void _startLocationPermissionCheck() {
    _locationPermissionTimer =
        Timer.periodic(Duration(seconds: 5), (timer) async {
      var serviceStatus = await Permission.location.serviceStatus;
      if (serviceStatus == ServiceStatus.disabled) {
        SystemNavigator.pop();
        // SystemNavigator.pop();
      }
    });
  }
}
