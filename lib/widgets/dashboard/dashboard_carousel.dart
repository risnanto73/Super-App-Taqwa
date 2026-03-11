import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';

class DashboardCarousel extends StatefulWidget {
  final List<String> posterList;
  const DashboardCarousel({super.key, required this.posterList});

  @override
  State<DashboardCarousel> createState() => _DashboardCarouselState();
}

class _DashboardCarouselState extends State<DashboardCarousel> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 10),
        CarouselSlider.builder(
          itemCount: widget.posterList.length,
          itemBuilder: (context, index, _) => Container(
            margin: const EdgeInsets.symmetric(horizontal: 5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(66), // 0.26 * 255
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                widget.posterList[index],
                fit: BoxFit.fitWidth,
                width: double.infinity,
              ),
            ),
          ),
          options: CarouselOptions(
            height: 180,
            autoPlay: true,
            viewportFraction: 0.7,
            enlargeCenterPage: true,
            onPageChanged: (index, _) => setState(() => _currentIndex = index),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: widget.posterList
              .asMap()
              .entries
              .map(
                (entry) => Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 4,
                  ),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentIndex == entry.key
                        ? Colors.amber
                        : Colors.grey[400],
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}
