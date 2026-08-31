import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/api_client.dart';
import '../../utils/database_helper.dart';
import '../../utils/formatters.dart';

class DetailTagihanPetugasPage extends StatefulWidget {
  final Map<String, dynamic> tagihan;

  const DetailTagihanPetugasPage({super.key, required this.tagihan});

  @override
  State<DetailTagihanPetugasPage> createState() =>
      _DetailTagihanPetugasPageState();
}

class _DetailTagihanPetugasPageState extends State<DetailTagihanPetugasPage> {
  bool isProcessing = false;

  final List<String> _namaBulan = [
    '',
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
  ];

  String _getBulanText(dynamic bulan) {
    if (bulan == null) return '';
    int b = int.tryParse(bulan.toString()) ?? 0;
    if (b >= 1 && b <= 12) return _namaBulan[b];
    return bulan.toString();
  }

  Future<void> _openGoogleMaps(dynamic wr) async {
    final lat = wr['latitude'] ?? wr['lat'];
    final lng = wr['longitude'] ?? wr['lokasi_long'];
    final alamat = wr['alamat'] ?? '';
    final desa = wr['desa']?['desa'] ?? '';
    final kec = wr['kecamatan']?['kecamatan'] ?? '';

    Uri url;
    if (lat != null && lng != null && lat.toString().isNotEmpty && lng.toString().isNotEmpty) {
      url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    } else {
      // Fallback menggunakan nama alamat lengkap di Kudus
      final query = Uri.encodeComponent('$alamat, Desa $desa, Kec. $kec, Kudus, Jawa Tengah');
      url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
    }

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak dapat membuka aplikasi peta.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal membuka peta: $e')),
      );
    }
  }

  // Logika Pembayaran Tunggal: Coba Online -> Otomatis Simpan Offline jika tanpa sinyal
  Future<void> _prosesPembayaran() async {
    if (isProcessing) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Pembayaran'),
        content: Text(
          'Terima uang tunai sebesar ${AppFormatters.formatRupiah(widget.tagihan['nominal'] ?? 0)} dari ${widget.tagihan['wajib_retribusi']?['nama_lengkap'] ?? 'Warga'}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ya, Terima Uang'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => isProcessing = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final url = Uri.parse('${ApiClient.baseUrl}/petugas/pembayaran/tunai');

      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              if (token != null) 'Authorization': 'Bearer $token',
            },
            body: json.encode({'tagihan_id': widget.tagihan['id']}),
          )
          .timeout(const Duration(seconds: 7));

      final responseData = json.decode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Pembayaran Tunai Berhasil Dicatat (Online)!'),
            backgroundColor: Color(0xFF059669),
            duration: Duration(seconds: 3),
          ),
        );
        Navigator.pop(context, true);
        return;
      } else {
        // Respons error dari server
        throw Exception(responseData['message'] ?? 'Gagal memproses pembayaran di server.');
      }
    } catch (_) {
      // JIKA TERJADI KESALAHAN JARINGAN / OFFLINE / TIMEOUT:
      // Simpan langsung ke penyimpanan lokal SQLite offline
      try {
        final dbHelper = DatabaseHelper();
        final tagihanId = widget.tagihan['id'] is int
            ? widget.tagihan['id']
            : int.tryParse(widget.tagihan['id'].toString()) ?? 0;

        await dbHelper.insertPembayaranPending(
          tagihanId,
          DateTime.now().toIso8601String(),
        );

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚡ Pembayaran Disimpan Offline (Akan otomatis disinkronkan saat ada sinyal)'),
            backgroundColor: Color(0xFFD97706),
            duration: Duration(seconds: 4),
          ),
        );
        Navigator.pop(context, true);
      } catch (dbErr) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan transaksi offline: $dbErr'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final wr = widget.tagihan['wajib_retribusi'] ?? {};
    final nama = wr['nama_lengkap'] ?? '-';
    final nik = wr['nik'] ?? '-';
    final noHp = wr['no_hp'] ?? '-';
    final alamat = wr['alamat'] ?? '-';
    final rt = wr['rt'] ?? '';
    final rw = wr['rw'] ?? '';
    final desa = wr['desa']?['desa'] ?? '-';
    final kec = wr['kecamatan']?['kecamatan'] ?? '-';
    final noTagihan = widget.tagihan['nomor_tagihan'] ?? '-';
    final nominal = widget.tagihan['nominal'] ?? 0;
    final bulanName = _getBulanText(widget.tagihan['bulan']);
    final tahun = widget.tagihan['tahun'] ?? '';

    final hasCoordinates = (wr['latitude'] != null && wr['latitude'].toString().isNotEmpty) ||
        (wr['lat'] != null && wr['lat'].toString().isNotEmpty);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      appBar: AppBar(
        title: const Text(
          'Detail Tagihan Warga',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Color(0xFF0F172A)),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Modern Nominal Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF065F46), Color(0xFF059669)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF059669).withOpacity(0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Tagihan $bulanName $tahun',
                        style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.9)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF87171),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Belum Bayar',
                          style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    AppFormatters.formatRupiah(nominal),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'No: $noTagihan',
                    style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.75)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 2. Data Wajib Retribusi Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.person_pin, color: Color(0xFF059669), size: 22),
                      SizedBox(width: 8),
                      Text(
                        'Data Wajib Retribusi',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                      ),
                    ],
                  ),
                  const Divider(height: 20, color: Color(0xFFF1F5F9)),
                  _buildDetailRow('Nama Lengkap', nama, isBold: true),
                  _buildDetailRow('NIK', nik),
                  _buildDetailRow('No. WhatsApp / HP', noHp),
                  _buildDetailRow('Kecamatan', kec),
                  _buildDetailRow('Desa / Kelurahan', desa),
                  _buildDetailRow('Alamat Lengkap', '$alamat ${rt.isNotEmpty ? "RT $rt " : ""}${rw.isNotEmpty ? "RW $rw" : ""}'),
                  
                  const SizedBox(height: 14),

                  // Tombol Peta Google Maps
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _openGoogleMaps(wr),
                      icon: const Icon(Icons.location_on_outlined, color: Color(0xFF2563EB), size: 18),
                      label: Text(
                        hasCoordinates ? 'Buka Titik Lokasi di Maps 📍' : 'Cari Alamat di Google Maps 📍',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF93C5FD)),
                        backgroundColor: const Color(0xFFEFF6FF),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 3. Tombol Pembayaran Tunai
            ElevatedButton.icon(
              onPressed: isProcessing ? null : _prosesPembayaran,
              icon: isProcessing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.payments_outlined, size: 22),
              label: Text(
                isProcessing ? 'Memproses...' : 'Terima Pembayaran Tunai',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.offline_bolt_outlined, size: 14, color: Color(0xFF64748B)),
                  SizedBox(width: 4),
                  Text(
                    'Mendukung transaksi offline jika tanpa sinyal internet',
                    style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 125,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
          ),
          const Text(': ', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                color: const Color(0xFF1E293B),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
