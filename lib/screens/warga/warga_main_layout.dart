import 'package:flutter/material.dart';
import 'dashboard_warga.dart';
import 'beranda_warga.dart';
import '../profile/profile_page.dart';

class WargaMainLayout extends StatefulWidget {
  const WargaMainLayout({super.key});

  @override
  State<WargaMainLayout> createState() => _WargaMainLayoutState();
}

class _WargaMainLayoutState extends State<WargaMainLayout> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      BerandaWarga(onNavigateTab: _onItemTapped),
      const DashboardWarga(),
      const ProfilePage(),
    ];

    return Scaffold(
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: const Color(0xFF059669),
        unselectedItemColor: const Color(0xFF94A3B8),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_rounded),
            label: 'Retribusi',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
