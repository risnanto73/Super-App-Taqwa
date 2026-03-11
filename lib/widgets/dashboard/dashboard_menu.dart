import 'package:flutter/material.dart';

class DashboardMenu extends StatelessWidget {
  const DashboardMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: GridView.count(
        crossAxisCount: 4,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        children: [
          _buildMenuItem(
            context,
            'assets/images/ic_menu_doa.png',
            'Doa',
            '/doa-harian',
          ),
          _buildMenuItem(
            context,
            'assets/images/ic_menu_zakat.png',
            'Zakat',
            '/zakat-page',
          ),
          _buildMenuItem(
            context,
            'assets/images/ic_menu_jadwal_sholat.png',
            'Sholat',
            '/jadwal-sholat',
          ),
          _buildMenuItem(
            context,
            'assets/images/ic_menu_video_kajian.png',
            'Kajian',
            '/video-kajian',
          ),
          _buildMenuItem(
            context,
            'assets/images/ic_menu_quran.png',
            'Quran',
            '/quran',
          ),
          _buildMenuItem(
            context,
            'assets/images/ic_menu_video_kajian.png', // Icon fallback
            'Waris',
            '/waris',
          ),
          _buildMenuItem(
            context,
            'assets/images/ic_menu_video_kajian.png',
            'Dzikir',
            '/video-kajian',
          ),
          _buildMenuItem(
            context,
            'assets/images/ic_menu_video_kajian.png',
            'Berita',
            '/video-kajian',
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context,
    String iconPath,
    String title,
    String routeName,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        splashColor: Colors.amber.withAlpha(51),
        onTap: () => Navigator.pushNamed(context, routeName),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(13),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(iconPath, width: 35),
              const SizedBox(height: 6),
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'PoppinsRegular',
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
