import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dashboard_petugas.dart';
import 'rekap_setoran_page.dart';
import '../profile/profile_page.dart';
import '../../utils/database_helper.dart';

class PetugasMainLayout extends StatefulWidget {
  const PetugasMainLayout({super.key});

  @override
  State<PetugasMainLayout> createState() => _PetugasMainLayoutState();
}

class _PetugasMainLayoutState extends State<PetugasMainLayout> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const DashboardPetugas(),
    const RekapSetoranPage(),
    const ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    _triggerAutoSync();
  }

  Future<void> _triggerAutoSync() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token != null) {
      final synced = await DatabaseHelper().syncAllPending(token);
      if (synced > 0 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ Berhasil menyinkronkan $synced pembayaran offline ke server'),
            backgroundColor: const Color(0xFF059669),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _triggerAutoSync();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: const Color(0xFF059669),
        unselectedItemColor: const Color(0xFF94A3B8),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_rounded),
            label: 'Tagihan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_rounded),
            label: 'Setoran',
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
