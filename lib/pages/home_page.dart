import 'dart:async'; // timer countdown
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart'; // carousel slider
import 'package:http/http.dart' as http; // ambil data API JSON
import 'dart:convert'; // decode JSON
import 'package:geolocator/geolocator.dart'; // GPS
import 'package:geocoding/geocoding.dart'; // Konversi GPS
import 'package:intl/intl.dart'; // Formatter Number
import 'package:permission_handler/permission_handler.dart'; // Izin handler
import 'package:shared_preferences/shared_preferences.dart'; // cache lokal
import 'package:string_similarity/string_similarity.dart'; // fuzzy match string

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final CarouselController _controller = CarouselController();
  int _currentIndex = 0;

  final posterList = const <String>[
    'assets/images/ramadhan-kareem.png',
    'assets/images/idl-fitr.png',
    'assets/images/idl-adh.png',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            // =============================
            // [MENU SECTION]
            // =============================
            _buildMenuGridSection(),
            // =============================
            // [CAROUSEL SECTION]
            // =============================
            _buildCarouselSection(),
          ],
        ),
      ),
    );
  }

  // =============================
  // [MENU ITEM WIDGET]
  // =============================
  Widget _buildMenuItem(
    String iconPath, 
    String title, 
    String routeName
  ) {
    return Column(
      children: [
        Image.asset(iconPath, width: 35,),
        Text(title)
      ],
    );
  }

  // =============================
  // [MENU GRID SECTION WIDGET]
  // =============================
  Widget _buildMenuGridSection() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: GridView.count(
        crossAxisCount: 4,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _buildMenuItem(
            'assets/images/ic_menu_doa.png', // iconPath 
            'Doa Harian', // title
            '/doa'), //routeName
          _buildMenuItem(
            'assets/images/ic_menu_doa.png',
            'Jadwal Sholat',
            '/doa',
          ),
          _buildMenuItem(
            'assets/images/ic_menu_doa.png',
            'Video Kajian',
            '/doa',
          ),
          _buildMenuItem('assets/images/ic_menu_doa.png', 'Zakat', '/doa'),
        ],
      ),
    );
  }

  // =============================
  // [CAROUSEL SECTION WIDGET]
  // =============================
  Widget _buildCarouselSection() {
    return Column(
      children: [
        const SizedBox(height: 20),
        // CAROUSEL CARD
        CarouselSlider.builder(
          itemCount: posterList.length,
          itemBuilder: (context, index, realIndex) {
            final poster = posterList[index];
            return Container(
              margin: EdgeInsets.all(15),
              child: ClipRRect(
                borderRadius: BorderRadiusGeometry.circular(20),
                child: Image.asset(
                  poster,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            );
          },
          options: CarouselOptions(
            autoPlay: true,
            height: 270,
            enlargeCenterPage: true,
            viewportFraction: 0.7,
            onPageChanged: (index, reason) {
              setState(() => _currentIndex = index);
            },
          ),
        ),

        // DOT INDIKATOR CAROUSEL
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: posterList.asMap().entries.map((entry) {
            return GestureDetector(
              onTap: () => _currentIndex.animateToPage(entry.key),
              child: Container(
                width: 10,
                height: 10,
                margin: EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentIndex == entry.key
                      ? Colors.amber
                      : Colors.grey[400],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

extension on int {
  void animateToPage(int key) {}
}
