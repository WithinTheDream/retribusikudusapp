import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'detail_tagihan_petugas_page.dart';
import 'scan_qr_page.dart';
import '../../core/api_client.dart';
import '../../utils/formatters.dart';

class DashboardPetugas extends StatefulWidget {
  const DashboardPetugas({super.key});

  @override
  State<DashboardPetugas> createState() => _DashboardPetugasState();
}

class _DashboardPetugasState extends State<DashboardPetugas> {
  List<dynamic> tagihans = [];
  bool hasAssignment = true;
  String assignmentMessage = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchTagihan();
  }

  Future<void> fetchTagihan() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final url = Uri.parse('${ApiClient.baseUrl}/petugas/tagihan');

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
          tagihans = data['data'] ?? [];
          hasAssignment = data['has_assignment'] ?? true;
          assignmentMessage = data['message'] ?? '';
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal mengambil data tagihan')),
          );
        }
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Terjadi kesalahan: $e')));
      }
    }
  }

  void _handleScanQr() async {
    final scannedResult = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const ScanQrPage()),
    );

    if (scannedResult == null || scannedResult.isEmpty) return;

    // Cari tagihan berdasarkan ID atau string QR
    dynamic foundTagihan;

    // Coba parsing jika QR format JSON
    try {
      final decoded = json.decode(scannedResult);
      if (decoded is Map) {
        final targetId = decoded['id'] ?? decoded['tagihan_id'];
        foundTagihan = tagihans.firstWhere(
          (t) => t['id']?.toString() == targetId?.toString(),
          orElse: () => null,
        );
      }
    } catch (_) {
      // Bukan JSON, cari langsung berdasarkan ID string atau kode
      foundTagihan = tagihans.firstWhere(
        (t) =>
            t['id']?.toString() == scannedResult ||
            t['kode_tagihan']?.toString() == scannedResult ||
            t['nomor_tagihan']?.toString() == scannedResult,
        orElse: () => null,
      );
    }

    if (!mounted) return;

    if (foundTagihan != null) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DetailTagihanPetugasPage(tagihan: foundTagihan),
        ),
      );
      if (result == true) {
        fetchTagihan();
      }
    } else {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Tagihan Tidak Ditemukan'),
          content: Text(
            'Data tagihan dengan kode/ID "$scannedResult" tidak ditemukan di daftar tagihan aktif wilayah Anda.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Petugas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: 'Scan QR Warga',
            onPressed: _handleScanQr,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              setState(() => isLoading = true);
              fetchTagihan();
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _handleScanQr,
        icon: const Icon(Icons.qr_code_scanner),
        label: const Text('Scan QR Warga'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: fetchTagihan,
              child: !hasAssignment
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        const SizedBox(height: 80),
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.location_off,
                                  size: 70,
                                  color: Colors.orange,
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Belum Ada Penugasan Wilayah',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  assignmentMessage.isNotEmpty
                                      ? assignmentMessage
                                      : 'Akun Anda belum memiliki penugasan wilayah penagihan.\nSilakan hubungi Admin Dinas untuk penugasan Kecamatan & Desa.',
                                  style: const TextStyle(color: Colors.grey, height: 1.4),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 24),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    setState(() => isLoading = true);
                                    fetchTagihan();
                                  },
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Muat Ulang'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : tagihans.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: const [
                            SizedBox(height: 120),
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.check_circle_outline,
                                    size: 64,
                                    color: Colors.green,
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'Semua Lunas!',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Tidak ada tagihan yang belum lunas di wilayah Anda.',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 80, top: 8),
                      itemCount: tagihans.length,
                      itemBuilder: (context, index) {
                        final tagihan = tagihans[index];
                        final wajibRetribusi = tagihan['wajib_retribusi'] ?? {};
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          elevation: 2,
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            leading: CircleAvatar(
                              backgroundColor: Colors.green.shade100,
                              child: Icon(
                                Icons.receipt_long,
                                color: Colors.green.shade800,
                              ),
                            ),
                            title: Text(
                              wajibRetribusi['nama_lengkap'] ?? 'Tanpa Nama',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  'Bulan ${tagihan['bulan']} ${tagihan['tahun']}',
                                ),
                                Text(
                                  AppFormatters.formatRupiah(
                                    tagihan['nominal'],
                                  ),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                            trailing: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        DetailTagihanPetugasPage(
                                          tagihan: tagihan,
                                        ),
                                  ),
                                );
                                if (result == true) {
                                  fetchTagihan();
                                }
                              },
                              child: const Text('Detail'),
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
