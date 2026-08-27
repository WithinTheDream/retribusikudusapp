import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
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

  Future<void> _simpanOffline() async {
    setState(() => isProcessing = true);
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

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.offline_pin, color: Colors.orange),
              SizedBox(width: 8),
              Text('Tersimpan Offline'),
            ],
          ),
          content: const Text(
            'Pembayaran berhasil dicatat di penyimpanan lokal offline.\n\nSilakan lakukan sinkronisasi data melalui menu "Sync" ketika Anda kembali terhubung ke internet.',
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx); // Tutup dialog
                Navigator.pop(context, true); // Kembali ke dashboard
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan offline: $e'),
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

  Future<void> _prosesPembayaranTunai() async {
    if (isProcessing) return;
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
              'Authorization': 'Bearer $token',
            },
            body: json.encode({'tagihan_id': widget.tagihan['id']}),
          )
          .timeout(const Duration(seconds: 10));

      final responseData = json.decode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pembayaran Tunai Berhasil!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(
          context,
          true,
        ); // Kembali ke dashboard dengan membawa status 'true'
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              responseData['message'] ?? 'Gagal memproses pembayaran',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Terjadi kesalahan jaringan / offline / timeout
      if (!mounted) return;

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Koneksi Gagal'),
          content: const Text(
            'Tidak dapat terhubung ke server.\n\nApakah Anda ingin menyimpan transaksi pembayaran ini secara OFFLINE di perangkat?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(ctx);
                _simpanOffline();
              },
              child: const Text('Simpan Offline'),
            ),
          ],
        ),
      );
    } finally {
      if (mounted) {
        setState(() => isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final wajibRetribusi = widget.tagihan['wajib_retribusi'] ?? {};

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Tagihan Warga')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Data Wajib Retribusi',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(),
                    Text('Nama: ${wajibRetribusi['nama_lengkap'] ?? '-'}'),
                    Text('NIK: ${wajibRetribusi['nik'] ?? '-'}'),
                    Text('No HP: ${wajibRetribusi['no_hp'] ?? '-'}'),
                    const SizedBox(height: 8),
                    Text(
                      'Alamat: ${wajibRetribusi['alamat']} RT ${wajibRetribusi['rt']} / RW ${wajibRetribusi['rw']}',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text('Total Tagihan', style: TextStyle(fontSize: 16)),
                    const SizedBox(height: 8),
                    Text(
                      AppFormatters.formatRupiah(widget.tagihan['nominal']),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Bulan: ${widget.tagihan['bulan']} | Tahun: ${widget.tagihan['tahun']}',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: isProcessing ? null : _prosesPembayaranTunai,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: isProcessing
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Terima Pembayaran Tunai (Online)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: isProcessing ? null : _simpanOffline,
              icon: const Icon(Icons.offline_pin, color: Colors.orange),
              label: const Text(
                'Catat Offline (Jika Tanpa Sinyal)',
                style: TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.orange),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
