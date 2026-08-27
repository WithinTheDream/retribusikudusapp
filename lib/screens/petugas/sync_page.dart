import 'package:flutter/material.dart';
import '../../utils/database_helper.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/api_client.dart';

class SyncPage extends StatefulWidget {
  const SyncPage({super.key});

  @override
  State<SyncPage> createState() => _SyncPageState();
}

class _SyncPageState extends State<SyncPage> {
  List<Map<String, dynamic>> unsyncedData = [];
  bool isSyncing = false;
  final dbHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    loadUnsyncedData();
  }

  Future<void> loadUnsyncedData() async {
    final data = await dbHelper.getUnsyncedPembayaran();
    if (!mounted) return;
    setState(() {
      unsyncedData = data;
    });
  }

  Future<void> syncData() async {
    if (isSyncing || unsyncedData.isEmpty) return;

    setState(() {
      isSyncing = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final url = Uri.parse('${ApiClient.baseUrl}/petugas/pembayaran/tunai');

      int successCount = 0;

      for (var row in unsyncedData) {
        final response = await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: json.encode({
            'tagihan_id': row['tagihan_id'],
            'tanggal_bayar':
                row['tanggal_bayar'], // Backend perlu menyesuaikan jika menerima field ini
          }),
        );

        final responseData = json.decode(response.body);
        if (response.statusCode == 200 && responseData['success'] == true) {
          await dbHelper.markAsSynced(row['id']);
          successCount++;
        }
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Berhasil sinkronisasi $successCount dari ${unsyncedData.length} data',
          ),
        ),
      );

      loadUnsyncedData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal sinkronisasi: Pastikan koneksi internet stabil'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSyncing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sinkronisasi Data Offline'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Perbarui',
            onPressed: isSyncing ? null : loadUnsyncedData,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: loadUnsyncedData,
        child: unsyncedData.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 120),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.cloud_done, size: 70, color: Colors.green),
                        SizedBox(height: 16),
                        Text(
                          'Semua Data Tersinkronisasi',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Tidak ada pembayaran offline yang tertunda.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16.0),
                    margin: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.info_outline,
                              color: Colors.orange,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Ada ${unsyncedData.length} pembayaran offline yang belum tersinkron ke server.',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: isSyncing ? null : syncData,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            icon: isSyncing
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.sync),
                            label: Text(
                              isSyncing
                                  ? 'Menyinkronkan...'
                                  : 'Mulai Sinkronisasi ke Server',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: unsyncedData.length,
                      itemBuilder: (context, index) {
                        final item = unsyncedData[index];
                        final tgl = item['tanggal_bayar'] != null
                            ? item['tanggal_bayar']
                                  .toString()
                                  .replaceAll('T', ' ')
                                  .split('.')
                                  .first
                            : '-';
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                              child: Icon(Icons.offline_pin),
                            ),
                            title: Text(
                              'Tagihan ID: #${item['tagihan_id']}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text('Waktu Bayar: $tgl'),
                            trailing: const Chip(
                              label: Text(
                                'Pending',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.orange,
                                ),
                              ),
                              backgroundColor: Color(0xFFFFF3E0),
                              padding: EdgeInsets.zero,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
