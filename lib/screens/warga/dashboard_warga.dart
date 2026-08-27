import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'detail_tagihan_warga_page.dart';
import 'pengajuan_screen.dart';
import '../../core/api_client.dart';
import '../../utils/formatters.dart';

class DashboardWarga extends StatefulWidget {
  const DashboardWarga({super.key});

  @override
  State<DashboardWarga> createState() => _DashboardWargaState();
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
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (!mounted) return;
        setState(() {
          dashboardData = data['data'] ?? {};
          isLoading = false;
        });
      } else {
        if (!mounted) return;
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal mengambil data dashboard')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Terjadi kesalahan: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Dashboard Warga')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final sisaTagihan = dashboardData['sisa_tagihan'] ?? [];
    final riwayat = dashboardData['riwayat_pembayaran'] ?? [];
    final profil = dashboardData['profil'];

    if (profil == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Halo, Warga Baru!'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Perbarui',
              onPressed: () {
                setState(() => isLoading = true);
                fetchDashboard();
              },
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: fetchDashboard,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24.0),
            children: [
              const SizedBox(height: 40),
              const Center(
                child: Icon(Icons.info_outline, size: 80, color: Colors.green),
              ),
              const SizedBox(height: 16),
              const Text(
                'Sistem Informasi Retribusi Kudus',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Selamat datang! Anda belum terdaftar sebagai Wajib Retribusi aktif.\n'
                'Silakan ajukan pendaftaran retribusi untuk area rumah atau tempat usaha Anda.',
                textAlign: TextAlign.center,
                style: TextStyle(height: 1.5, color: Colors.black87),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PengajuanScreen(),
                    ),
                  );
                  if (result == true) {
                    setState(() => isLoading = true);
                    fetchDashboard(); // Refresh jika berhasil mengajukan
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(Icons.add_task),
                label: const Text(
                  'Ajukan Retribusi Sekarang',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Halo, ${profil['nama_lengkap']}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Perbarui',
            onPressed: () {
              setState(() => isLoading = true);
              fetchDashboard();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: fetchDashboard,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          children: [
            Card(
              elevation: 3,
              color: Colors.green.shade50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.green.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Total Sisa Tagihan',
                          style: TextStyle(fontSize: 15, color: Colors.black54),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          AppFormatters.formatRupiah(
                            dashboardData['total_sisa_tagihan'] ?? 0,
                          ),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                    if (sisaTagihan.isNotEmpty)
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          // Buka detail tagihan pertama yang belum bayar
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DetailTagihanWargaPage(
                                tagihan: sisaTagihan.first,
                              ),
                            ),
                          );
                        },
                        child: const Text('Bayar'),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Tagihan Belum Lunas',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            sisaTagihan.isEmpty
                ? const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green),
                          SizedBox(width: 12),
                          Text('Hore! Semua tagihan Anda sudah lunas.'),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: sisaTagihan.length,
                    itemBuilder: (context, index) {
                      final tag = sisaTagihan[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Color(0xFFFFEBEE),
                            child: Icon(Icons.receipt, color: Colors.red),
                          ),
                          title: Text(
                            'Tagihan Bulan ${tag['bulan']} ${tag['tahun']}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            AppFormatters.formatRupiah(tag['nominal']),
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    DetailTagihanWargaPage(tagihan: tag),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
            const SizedBox(height: 24),
            const Text(
              'Riwayat Pembayaran',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            riwayat.isEmpty
                ? const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'Belum ada riwayat pembayaran yang tercatat.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: riwayat.length,
                    itemBuilder: (context, index) {
                      final tag = riwayat[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Color(0xFFE8F5E9),
                            child: Icon(Icons.check, color: Colors.green),
                          ),
                          title: Text(
                            'Pembayaran Bulan ${tag['bulan']} ${tag['tahun']}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            AppFormatters.formatRupiah(tag['nominal'] ?? 0),
                            style: const TextStyle(color: Colors.green),
                          ),
                          trailing: const Chip(
                            label: Text(
                              'Lunas',
                              style: TextStyle(
                                color: Colors.green,
                                fontSize: 12,
                              ),
                            ),
                            backgroundColor: Color(0xFFE8F5E9),
                          ),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
}
