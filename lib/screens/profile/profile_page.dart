import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/api_client.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';
import 'settings_page.dart';
import 'help_center_page.dart';
import 'status_pengajuan_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String _nama = '';
  String _role = '';
  String _email = '';
  bool _isWajibRetribusiActive = false;
  bool _hasWajibRetribusiProfile = false;
  bool _isLoadingStatus = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    setState(() {
      _nama = prefs.getString('nama') ?? 'Pengguna';
      _role = prefs.getString('role') ?? 'User';
    });

    // Ambil status dari API jika user adalah warga
    if (_role.toLowerCase() != 'petugas' && token != null) {
      try {
        final url = Uri.parse('${ApiClient.baseUrl}/warga/dashboard');
        final response = await http.get(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ).timeout(const Duration(seconds: 6));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final profil = data['data']?['profil'];
          if (mounted) {
            setState(() {
              if (profil != null) {
                _hasWajibRetribusiProfile = true;
                _isWajibRetribusiActive = (profil['status_aktif'] == true || profil['status_aktif'] == 1);
                _email = profil['user']?['email'] ?? '';
              } else {
                _hasWajibRetribusiProfile = false;
                _isWajibRetribusiActive = false;
              }
              _isLoadingStatus = false;
            });
          }
        } else {
          if (mounted) setState(() => _isLoadingStatus = false);
        }
      } catch (_) {
        if (mounted) setState(() => _isLoadingStatus = false);
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoadingStatus = false;
          _isWajibRetribusiActive = true; // Petugas default aktif jika bisa login
        });
      }
    }
  }

  void _handleLogout() async {
    await AuthService.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPetugas = _role.toLowerCase() == 'petugas';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      appBar: AppBar(
        title: const Text('Profil Saya', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Header Card Identitas & Status
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 20.0),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 42,
                    backgroundColor: isPetugas ? const Color(0xFFECFDF5) : const Color(0xFFEFF6FF),
                    child: Icon(
                      isPetugas ? Icons.badge : Icons.person,
                      size: 48,
                      color: isPetugas ? const Color(0xFF059669) : const Color(0xFF2563EB),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    _nama,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isPetugas ? 'Petugas Lapangan Kudus' : (_email.isNotEmpty ? _email : 'Wajib Retribusi Warga'),
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Role & Status Badges
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      // Role Pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: isPetugas ? const Color(0xFFECFDF5) : const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isPetugas ? const Color(0xFFA7F3D0) : const Color(0xFFBFDBFE),
                          ),
                        ),
                        child: Text(
                          isPetugas ? 'PETUGAS LAPANGAN' : 'WAJIB RETRIBUSI',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isPetugas ? const Color(0xFF047857) : const Color(0xFF1D4ED8),
                          ),
                        ),
                      ),

                      // Status Aktif / Inaktif Pill
                      if (_isLoadingStatus)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text('Memuat...', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                        )
                      else if (isPetugas || (_hasWajibRetribusiProfile && _isWajibRetribusiActive))
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFA7F3D0)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.check_circle, color: Color(0xFF059669), size: 13),
                              SizedBox(width: 4),
                              Text(
                                'STATUS: AKTIF',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF047857),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFFECDD3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.cancel, color: Color(0xFFDC2626), size: 13),
                              SizedBox(width: 4),
                              Text(
                                'STATUS: BELUM AKTIF',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFB91C1C),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Menu List Card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            color: Colors.white,
            child: Column(
              children: [
                if (!isPetugas) ...[
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFFECFDF5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.assignment_outlined, color: Color(0xFF059669), size: 20),
                    ),
                    title: const Text(
                      'Status Pengajuan Retribusi',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF1E293B)),
                    ),
                    subtitle: const Text(
                      'Cek persetujuan pendaftaran objek retribusi Anda',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFF94A3B8)),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const StatusPengajuanPage(),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                ],
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Color(0xFFEFF6FF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.settings_outlined, color: Color(0xFF2563EB), size: 20),
                  ),
                  title: const Text(
                    'Pengaturan Akun',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF1E293B)),
                  ),
                  subtitle: const Text('Ubah sandi, notifikasi & informasi', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFF94A3B8)),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SettingsPage(),
                      ),
                    );
                  },
                ),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFFBEB),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.help_outline, color: Color(0xFFD97706), size: 20),
                  ),
                  title: const Text(
                    'Pusat Bantuan & FAQ',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF1E293B)),
                  ),
                  subtitle: const Text('Kontak dinas PKPLH & tanya jawab', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFF94A3B8)),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HelpCenterPage(),
                      ),
                    );
                  },
                ),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFEF2F2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.logout_rounded, color: Color(0xFFDC2626), size: 20),
                  ),
                  title: const Text(
                    'Keluar dari Akun',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Color(0xFFDC2626),
                    ),
                  ),
                  subtitle: const Text('Logout sesi dari perangkat ini', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: Color(0xFFDC2626),
                  ),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Konfirmasi Logout'),
                        content: const Text(
                          'Apakah Anda yakin ingin keluar dari aplikasi?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Batal'),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFDC2626),
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                              _handleLogout();
                            },
                            child: const Text('Logout'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Center(
            child: Text(
              'Aplikasi Retribusi Kudus v1.0.0\nKabupaten Kudus © 2026',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
