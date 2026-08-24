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

  final List<Widget> _pages = [
    const BerandaWarga(),
    DashboardWarga(), // Ini yang jadi menu "Retribusi"
    const ProfilePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Retribusi',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
