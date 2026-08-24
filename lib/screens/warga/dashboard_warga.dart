import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'detail_tagihan_warga_page.dart';
import 'pengajuan_screen.dart';
import '../../core/api_client.dart';

class DashboardWarga extends StatefulWidget {
  @override
  _DashboardWargaState createState() => _DashboardWargaState();
}

class _DashboardWargaState extends State<DashboardWarga> {
  bool isLoading = true;
  Map<String, dynamic> dashboardData = {};

  @override
  void initState() {
    super.initState();
    fetchDashboard();
  }

  Future<void> fetchDashboard() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final url = Uri.parse('${ApiClient.baseUrl}/warga/dashboard');
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          dashboardData = data['data'];
          isLoading = false;
        });
      } else {
        setState(() { isLoading = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengambil data dashboard')),
        );
      }
    } catch (e) {
      setState(() { isLoading = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Dashboard Warga')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final sisaTagihan = dashboardData['sisa_tagihan'] ?? [];
    final riwayat = dashboardData['riwayat_pembayaran'] ?? [];
    final profil = dashboardData['profil'];

    if (profil == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Halo, Warga Baru!')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.info_outline, size: 80, color: Colors.blue),
                const SizedBox(height: 16),
                const Text(
                  'Sistem Informasi Retribusi Kudus',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Selamat datang! Anda belum terdaftar sebagai Wajib Retribusi.\n'
                  'Silakan ajukan pendaftaran retribusi untuk area rumah atau usaha Anda.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const PengajuanScreen()),
                    );
                    if (result == true) {
                      fetchDashboard(); // Refresh if submitted
                    }
                  },
                  child: const Text('Ajukan Retribusi Sekarang'),
                )
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Halo, ${profil['nama_lengkap']}'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Total Sisa Tagihan', style: TextStyle(fontSize: 16)),
                          SizedBox(height: 8),
                          Text(
                            'Rp ${dashboardData['total_sisa_tagihan'] ?? 0}',
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.red),
                          ),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: () {
                          // TODO: Fitur bayar transfer
                        },
                        child: Text('Bayar'),
                      )
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
              Text('Tagihan Belum Lunas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              sisaTagihan.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Text('Hore! Semua tagihan Anda sudah lunas.'),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: sisaTagihan.length,
                      itemBuilder: (context, index) {
                        final tag = sisaTagihan[index];
                        return ListTile(
                          title: Text('Tagihan Bulan ${tag['bulan']} ${tag['tahun']}'),
                          subtitle: Text('Rp ${tag['nominal']}'),
                          trailing: Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DetailTagihanWargaPage(tagihan: tag),
                              ),
                            );
                          },
                        );
                      },
                    ),
              SizedBox(height: 20),
              Text('Riwayat Pembayaran', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              riwayat.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Text('Belum ada riwayat pembayaran.'),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: riwayat.length,
                      itemBuilder: (context, index) {
                        final tag = riwayat[index];
                        return ListTile(
                          title: Text('Pembayaran Bulan ${tag['bulan']} ${tag['tahun']}'),
                          subtitle: Text('Lunas'),
                          trailing: Icon(Icons.check_circle, color: Colors.green),
                        );
                      },
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
