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
        return const Color(0xFFF59E0B); // Amber
      case 'survey':
        return const Color(0xFF3B82F6); // Blue
      case 'perbaikan':
        return const Color(0xFFEC4899); // Pink
      case 'ditolak':
        return const Color(0xFFEF4444); // Red
      case 'disetujui':
        return const Color(0xFF10B981); // Emerald Green
      default:
        return const Color(0xFF6B7280);
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'menunggu':
        return Icons.hourglass_top_rounded;
      case 'survey':
        return Icons.search_rounded;
      case 'perbaikan':
        return Icons.build_circle_outlined;
      case 'ditolak':
        return Icons.cancel_outlined;
      case 'disetujui':
        return Icons.check_circle_outline_rounded;
      default:
        return Icons.info_outline;
    }
  }

  String _getStatusTitle(String status) {
    switch (status.toLowerCase()) {
      case 'menunggu':
        return 'Menunggu Verifikasi Admin';
      case 'survey':
        return 'Tahap Survey Lapangan';
      case 'perbaikan':
        return 'Perlu Perbaikan Berkas';
      case 'ditolak':
        return 'Pengajuan Ditolak';
      case 'disetujui':
        return 'Pengajuan Disetujui ✓';
      default:
        return status.toUpperCase();
    }
  }

  void _showDetailDialog(Map<String, dynamic> p) {
    final status = p['status_pengajuan']?.toString() ?? 'menunggu';
    final color = _getStatusColor(status);
    final tgl = AppFormatters.formatTanggal(p['created_at']);
    final catatan = p['catatan_admin']?.toString() ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: color.withValues(alpha: 0.15),
                  child: Icon(_getStatusIcon(status), color: color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p['nomor_pengajuan'] ?? 'Pengajuan',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                      ),
                      Text(
                        'Diajukan pada $tgl',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 32, color: Color(0xFFF1F5F9)),
            _buildDetailRow('Status:', _getStatusTitle(status), valueColor: color, isBold: true),
            if (catatan.isNotEmpty)
              _buildDetailRow('Catatan Admin:', catatan, isBold: true),
            _buildDetailRow('Nama Pemohon:', p['nama_lengkap'] ?? '-'),
            _buildDetailRow('NIK:', p['nik'] ?? '-'),
            _buildDetailRow('Kategori Objek:', p['jenis_retribusi']?['nama'] ?? '-'),
            if (p['nama_usaha'] != null && p['nama_usaha'].toString().isNotEmpty)
              _buildDetailRow('Nama Toko/Usaha:', p['nama_usaha']),
            _buildDetailRow('Wilayah:', 'Kec. ${p['kecamatan']?['kecamatan'] ?? "-"}, Desa ${p['desa']?['desa'] ?? "-"}'),
            _buildDetailRow('Alamat:', '${p['alamat'] ?? "-"} (RT ${p['rt'] ?? "-"} / RW ${p['rw'] ?? "-"})'),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Tutup Detail', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                color: valueColor ?? const Color(0xFF1E293B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Status Pengajuan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE2E8F0), height: 1),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Perbarui Data',
            onPressed: () {
              setState(() => _isLoading = true);
              _fetchStatus();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF059669)))
          : RefreshIndicator(
              onRefresh: _fetchStatus,
              color: const Color(0xFF059669),
              child: _pengajuans.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE2E8F0),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.assignment_outlined, size: 48, color: Color(0xFF64748B)),
                              ),
                              const SizedBox(height: 18),
                              const Text(
                                'Belum Ada Pengajuan',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Anda belum pernah mengirim pengajuan objek retribusi.',
                                style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
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
                        final statusStr = p['status_pengajuan']?.toString() ?? 'menunggu';
                        final color = _getStatusColor(statusStr);
                        final tglStr = AppFormatters.formatTanggal(p['created_at']);
                        final jenis = p['jenis_retribusi']?['nama'] ?? 'Objek Retribusi';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: InkWell(
                            onTap: () => _showDetailDialog(p),
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: color.withValues(alpha: 0.12),
                                        child: Icon(_getStatusIcon(statusStr), color: color, size: 20),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              p['nomor_pengajuan'] ?? 'Pengajuan #${p['id']}',
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: Color(0xFF1E293B)),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '$jenis • $tglStr',
                                              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: color.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(color: color.withValues(alpha: 0.3)),
                                        ),
                                        child: Text(
                                          statusStr.toUpperCase(),
                                          style: TextStyle(
                                            color: color,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 22, color: Color(0xFFF1F5F9)),
                                  Row(
                                    children: [
                                      const Icon(Icons.info_outline, size: 14, color: Color(0xFF94A3B8)),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          _getStatusTitle(statusStr),
                                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: color),
                                        ),
                                      ),
                                      const Text('Lihat Detail', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                                      const SizedBox(width: 2),
                                      const Icon(Icons.chevron_right, size: 16, color: Color(0xFF2563EB)),
                                    ],
                                  ),
                                ],
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
