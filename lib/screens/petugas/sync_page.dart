import 'package:flutter/material.dart';
import '../../utils/database_helper.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/api_client.dart';

class SyncPage extends StatefulWidget {
  @override
  _SyncPageState createState() => _SyncPageState();
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
    setState(() {
      unsyncedData = data;
    });
  }

  Future<void> syncData() async {
    if (isSyncing || unsyncedData.isEmpty) return;

    setState(() { isSyncing = true; });

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
            'tanggal_bayar': row['tanggal_bayar'], // Backend perlu menyesuaikan jika menerima field ini
          }),
        );

        final responseData = json.decode(response.body);
        if (response.statusCode == 200 && responseData['success'] == true) {
          await dbHelper.markAsSynced(row['id']);
          successCount++;
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Berhasil sinkronisasi $successCount dari ${unsyncedData.length} data')),
      );

      loadUnsyncedData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal sinkronisasi: Pastikan koneksi internet stabil')),
      );
    } finally {
      setState(() { isSyncing = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Sinkronisasi Data Offline')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Ada ${unsyncedData.length} pembayaran yang belum dikirim ke server.',
              style: TextStyle(fontSize: 16),
            ),
          ),
          ElevatedButton.icon(
            onPressed: (unsyncedData.isEmpty || isSyncing) ? null : syncData,
            icon: isSyncing ? CircularProgressIndicator(color: Colors.white) : Icon(Icons.sync),
            label: Text(isSyncing ? 'Menyinkronkan...' : 'Mulai Sinkronisasi'),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: unsyncedData.length,
              itemBuilder: (context, index) {
                final item = unsyncedData[index];
                return ListTile(
                  title: Text('Tagihan ID: ${item['tagihan_id']}'),
                  subtitle: Text('Waktu Bayar: ${item['tanggal_bayar']}'),
                  trailing: Icon(Icons.cloud_off, color: Colors.grey),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
