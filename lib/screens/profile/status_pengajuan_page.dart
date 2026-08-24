import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/api_client.dart';

class StatusPengajuanPage extends StatefulWidget {
  const StatusPengajuanPage({super.key});

  @override
  State<StatusPengajuanPage> createState() => _StatusPengajuanPageState();
}

class _StatusPengajuanPageState extends State<StatusPengajuanPage> {
  bool _isLoading = true;
  List<dynamic> _pengajuans = [];

  @override
  void initState() {
    super.initState();
    _fetchStatus();
  }

  Future<void> _fetchStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final url = Uri.parse('${ApiClient.baseUrl}/warga/pengajuan/status');
      
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
          _pengajuans = data['data'];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'menunggu':
      case 'survey':
        return Colors.orange;
      case 'perbaikan':
      case 'ditolak':
        return Colors.red;
      case 'disetujui':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Status Pengajuan')),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _pengajuans.isEmpty
          ? const Center(child: Text('Belum ada riwayat pengajuan.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _pengajuans.length,
              itemBuilder: (context, index) {
                final p = _pengajuans[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text(p['nomor_pengajuan']),
                    subtitle: Text('Tgl: ${p['created_at'].toString().split('T')[0]}'),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getStatusColor(p['status_pengajuan']).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        p['status_pengajuan'].toString().toUpperCase(),
                        style: TextStyle(
                          color: _getStatusColor(p['status_pengajuan']),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
