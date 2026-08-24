import 'package:flutter/material.dart';
import 'dashboard_petugas.dart';
import 'rekap_setoran_page.dart';
import 'sync_page.dart';
import '../profile/profile_page.dart';

class PetugasMainLayout extends StatefulWidget {
  const PetugasMainLayout({super.key});

  @override
  State<PetugasMainLayout> createState() => _PetugasMainLayoutState();
}

class _PetugasMainLayoutState extends State<PetugasMainLayout> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    DashboardPetugas(),
    RekapSetoranPage(),
    SyncPage(),
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
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Tagihan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: 'Setoran',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.sync),
            label: 'Sync',
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
