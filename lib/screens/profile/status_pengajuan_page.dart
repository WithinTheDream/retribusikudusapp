import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/api_client.dart';
import '../../utils/formatters.dart';

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
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (!mounted) return;
        setState(() {
          _pengajuans = data['data'] ?? [];
          _isLoading = false;
        });
      } else {
        if (!mounted) return;
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'menunggu':
      case 'survey':
        return Colors.orange;
      case 'perbaikan':
      case 'ditolak':
        return Colors.red;
      case 'disetujui':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Status Pengajuan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Perbarui',
            onPressed: () {
              setState(() => _isLoading = true);
              _fetchStatus();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchStatus,
              child: _pengajuans.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 120),
                        Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.assignment_outlined,
                                size: 64,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Belum Ada Pengajuan',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Anda belum pernah mengirim pengajuan objek retribusi.',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      itemCount: _pengajuans.length,
                      itemBuilder: (context, index) {
                        final p = _pengajuans[index];
                        final statusStr =
                            p['status_pengajuan']?.toString() ?? 'menunggu';
                        final tglStr = AppFormatters.formatTanggal(
                          p['created_at'],
                        );

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 2,
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: _getStatusColor(
                                statusStr,
                              ).withValues(alpha: 0.15),
                              child: Icon(
                                Icons.assignment,
                                color: _getStatusColor(statusStr),
                              ),
                            ),
                            title: Text(
                              p['nomor_pengajuan'] ?? 'Pengajuan #${p['id']}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text('Tanggal: $tglStr'),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(
                                  statusStr,
                                ).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                statusStr.toUpperCase(),
                                style: TextStyle(
                                  color: _getStatusColor(statusStr),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
