import 'package:flutter/material.dart';
import 'package:salesautomation_v1/Homepage.dart';

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    initialRoute: 'homepage',
    routes: {'homepage': (context) => Homepage()},
  ));
}
