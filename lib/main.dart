import 'dart:io';

import 'package:bitaqwa/components/dashboard_page.dart';
import 'package:bitaqwa/components/video_page.dart';
import 'package:bitaqwa/components/zakat_page.dart';
import 'package:bitaqwa/pages/home_page.dart';
import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = MyHttpOverrides();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      debugShowCheckedModeBanner: false,
      routes: {
        // '/' nama route dari halaman HomePage(),
        // '/zakat' nama route dari halaman ZakatPage(),
        '/': (context) => HomePage(),
        '/video-kajian': (context) => VideoPage(),
        '/zakat-page': (context) => ZakatPage(),
      },
    );
  }
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (cert, host, port) => true;
  }
}
